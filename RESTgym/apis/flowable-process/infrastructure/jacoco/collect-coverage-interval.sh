#!/bin/bash
# JaCoCo periodic coverage collection - RESTgym
# Calls collect-coverage.sh every 5 seconds after initial 10s delay

sleep 10
while true ; do
    sh /infrastructure/jacoco/collect-coverage.sh &
    sleep 5
done
