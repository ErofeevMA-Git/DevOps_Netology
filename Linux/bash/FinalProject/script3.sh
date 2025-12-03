#!/bin/bash



script_dir=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="$script_dir/OUTPUT.txt"
> "$OUTPUT_FILE"

params=("fdinfo" "mounts" "root")

for pid in /proc/[0-9]*; do 
    name_proc=$(basename "$pid") #>>"$OUTPUT_FILE"
    if [ -r "$pid/exe" ]; then
        echo "\n"
        #echo $(basename "$(readlink -f "$pid/exe")")
    fi
    for param in ${params[@]}; do
        if [ -r "$pid/$param" ]; then
            echo " ------ $param $name_proc"
            cat "$pid/$param" 
        fi
    done >> "$OUTPUT_FILE"

done