#!/bin/bash

DIR=$(dirname "$(readlink -f "$0")")
BUS_LIST_FILE="$DIR/bus_list.txt"
LIST_FILE="$DIR/input_devices.txt"
LOG_FILE="$DIR/input_devices.log"
TIME=$(date '+%Y-%m-%d %H:%M:%S')

CURRENT=$(grep "N: Name=" /proc/bus/input/devices | cut -d'"' -f2 | sort) 

if [ -f "$LIST_FILE" ]; then
    OLD=$(cat "$LIST_FILE")
else
    OLD=""
fi

echo $CURRENT > $LIST_FILE

if [ -f "$BUS_LIST_FILE" ]; then
    list_bus_old=$(tail -n +2 "$BUS_LIST_FILE")
else
    list_bus_old=""
fi

echo "bus!name!phys!sysfs!uniq!handlers!PROP!KEY!REL" > "$BUS_LIST_FILE"

bus_info=""
list_new=()
while IFS= read -r line; do
    if [[ "$line" == "" ]]; then
        if [[ -n "$bus_info" ]]; then
            echo "$bus_info" >> "$BUS_LIST_FILE"
            if ! echo "$list_bus_old" | grep -q -F "$bus_info"; then
                list_new+=( "$bus_info" )
            fi
            bus_info=""
        fi
    else
        bus_info+="${line:3}!"
    fi
done < /proc/bus/input/devices

if [[ -n "$bus_info" ]]; then
    echo "$bus_info" >> "$BUS_LIST_FILE"
    if ! echo "$list_bus_old" | grep -q -F "$bus_info"; then
        list_new+=( "$bus_info" )
    fi
fi

if [ ${#list_new[@]} -gt 0 ]; then
    echo "[$TIME] New devices detected:" >> "$LOG_FILE"
    for device in "${list_new[@]}"; do
        echo "[$TIME] $device" >> "$LOG_FILE"
    done
fi