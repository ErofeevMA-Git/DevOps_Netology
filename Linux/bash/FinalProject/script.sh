#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="$script_dir/OUTPUT.txt"
LOG_FILE="$script_dir/LOG.txt"

# Очищаем файл при запуске
> "$OUTPUT_FILE"

trap 'echo "Exit (Ctrl+C)"; exit 1;' 2

if [[ $EUID -ne 0 ]]; then
	echo "Должен запускаться c правами ROOT"
	exit 1
fi

parameters=("cmdline" "environ" "limits" "mounts" "status" "cwd" "fd" "fdinfo" "root")
choice_param=()
select param in "${parameters[@]}"
do
    case $param in
        "cmdline"|"environ"|"limits"|"mounts"|"status"|"cwd"|"fd"|"fdinfo"|"root")
            choice_param+=( "$param" )
            ;;
        *)
            break
            ;;
    esac
    echo "Выбраны: ${choice_param[*]}"
done

# Заголовок таблицы
if [[ ${#choice_param[@]} -gt 0 ]]; then
    header="PID|name|$(IFS='|'; echo "${choice_param[*]}")"
    echo "$header" | column -t -s '|' >> "$OUTPUT_FILE"
else
    echo "PID name" >> "$OUTPUT_FILE"
fi

# Читаем старые PID из предыдущего файла
OLD_PIDS_FILE="$script_dir/old_pids.tmp"
OLD_PIDS=()
if [[ -f "$OLD_PIDS_FILE" ]]; then
    mapfile -t OLD_PIDS < "$OLD_PIDS_FILE" 2>/dev/null
fi

# Сохраняем текущие PID для следующего запуска
CURRENT_PIDS=()
time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
NEW_PIDS=()

for dir in /proc/[0-9]*
do
    if [ -d "$dir" ]; then
        pid=$(basename "$dir")
        CURRENT_PIDS+=("$pid")
        
        # Получаем имя процесса
        name_pid=""
        if [[ -e "$dir/exe" ]]; then
            exe_link=$(readlink -f "$dir/exe" 2>/dev/null)
            name_pid=$(basename "$exe_link" 2>/dev/null)
        fi
        [[ -z "$name_pid" ]] && name_pid="[unknown]"
        
        values=()
        for parametr in "${choice_param[@]}"; do
            case $parametr in
                "cmdline")
                    volume=$(cat "/proc/$pid/$parametr" 2>/dev/null | tr '\0' ' ' | head -c 50)
                    [[ -z "$volume" ]] && volume="[empty]"
                    ;;
                "environ")
                    volume=$(cat "/proc/$pid/$parametr" 2>/dev/null | tr '\0' ' ' | head -c 50)
                    [[ -z "$volume" ]] && volume="[empty]"
                    ;;
                "limits"|"mounts"|"status")
                    volume=$(head -3 "/proc/$pid/$parametr" 2>/dev/null | tr '\n' ' ')
                    [[ -z "$volume" ]] && volume="[no access]"
                    ;;
                "cwd"|"root")
                    volume=$(readlink "/proc/$pid/$parametr" 2>/dev/null)
                    [[ -z "$volume" ]] && volume="[no link]"
                    ;;
                "fd"|"fdinfo")
                    if [[ -d "/proc/$pid/$parametr" ]]; then
                        count=$(ls -1 "/proc/$pid/$parametr" 2>/dev/null | wc -l)
                        volume="count: $count"
                    else
                        volume="[no dir]"
                    fi
                    ;;
            esac
            values+=("$volume")
        done
        
        # Записываем в файл
        if [[ ${#choice_param[@]} -gt 0 ]]; then
            row="$pid|$name_pid|$(IFS='|'; echo "${values[*]}")"
            echo "$row" >> "$OUTPUT_FILE"
        else
            echo "$pid $name_pid" >> "$OUTPUT_FILE"
        fi
        
        # Проверяем, новый ли это процесс
        is_new=true
        for old_pid in "${OLD_PIDS[@]}"; do
            if [[ "$old_pid" == "$pid" ]]; then
                is_new=false
                break
            fi
        done
        
        if [[ "$is_new" == true ]]; then
            NEW_PIDS+=("$pid:$name_pid")
        fi
    fi
done

# Сохраняем текущие PID для следующего запуска
printf "%s\n" "${CURRENT_PIDS[@]}" > "$OLD_PIDS_FILE" 2>/dev/null

# Логируем новые процессы
if [[ ${#NEW_PIDS[@]} -gt 0 ]]; then
    echo "$time_stamp Новые процессы: ${NEW_PIDS[*]}" >> "$LOG_FILE"
fi

# Форматируем и выводим результат
if [[ -f "$OUTPUT_FILE" ]]; then
    column -t -s '|' "$OUTPUT_FILE"
else
    echo "Файл $OUTPUT_FILE не создан"
fi