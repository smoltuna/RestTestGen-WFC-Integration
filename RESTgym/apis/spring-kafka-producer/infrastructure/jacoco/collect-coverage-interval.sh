#!/bin/bash
# JaCoCo coverage collection script for spring-kafka-producer
# Periodically triggers JaCoCo to dump coverage data

echo "$(date) - JaCoCo coverage collection started"

while true; do
    sleep 60
    
    # Try to trigger JaCoCo dump via TCP
    if command -v nc &> /dev/null; then
        echo "dump" | nc localhost 12345 2>/dev/null && \
            echo "$(date) - JaCoCo coverage dumped successfully" || \
            echo "$(date) - JaCoCo not yet ready or not responding"
    fi
done
