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


printf "%-40s %-10s %-10s %-12s\n" "name" "vendor" "product" "handler"
awk -v RS="" '{
    name = $0; sub(/.*Name="/, "", name); sub(/".*/, "", name)
    vendor = $0; sub(/.*Vendor=/, "", vendor); vendor = substr(vendor, 1, 4)
    product = $0; sub(/.*Product=/, "", product); product = substr(product, 1, 4)
    handler = $0; sub(/.*Handlers=/, "", handler); handler = substr(handler, 1, 10)
    
    printf "%-40s %-10s %-10s %-12s\n", name, vendor, product, handler
}' /proc/bus/input/devices


if [ -n "$OLD" ]; then
    NEW=$(echo "$CURRENT" | grep -vxF "$OLD" || true)
else
    NEW="$CURRENT"
fi

if [ -n "$NEW" ]; then
    echo "[$TIME] Новые устройства:" >> "$LOG_FILE"
    echo "$NEW" >> "$LOG_FILE"
fi