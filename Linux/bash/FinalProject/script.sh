#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="$script_dir/OUTPUT.txt"
> $OUTPUT_FILE

for dir in /proc/[0-9]*
do
    if [ -d $dir ] 
        then
            echo $(basename "$dir") >> $OUTPUT_FILE 
    fi
done