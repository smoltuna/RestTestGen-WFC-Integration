#!/bin/bash
# JaCoCo coverage collection script
# Dumps coverage data every 5 seconds

while true; do
    sleep 5
    if command -v nc &> /dev/null; then
        echo "dump" | nc localhost 12345 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Coverage dump requested"
    fi
done
