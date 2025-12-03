#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="$script_dir/OUTPUT.txt"
> "$OUTPUT_FILE"

for dir in /proc/[0-9]*
do
    if [ -d "$dir" ] 
        then
            pid=$(basename "$dir")
            process_name=""
            if [ -r "$dir/exe" ]; then
                exe_link=$(readlink -f "$dir/exe" 2>/dev/null)
                if [ -n $exe_link ]; then
                    process_name=$(basename "$exe_link")
                    echo $process_name >> "$OUTPUT_FILE"
                fi 
            fi
    fi
done