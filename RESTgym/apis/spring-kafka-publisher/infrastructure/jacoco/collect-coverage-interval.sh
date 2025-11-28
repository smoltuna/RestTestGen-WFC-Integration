#!/bin/sh
# JaCoCo Coverage Collection Script for RESTgym
# Collects code coverage dumps at regular intervals during fuzzing

while true; do
  sleep 60
  
  # Dump coverage data via TCP
  java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7.jar dump \
    --address localhost \
    --port 12345 \
    --destfile /results/$API/$TOOL/$RUN/jacoco-$(date +%s).exec \
    --reset 2>/dev/null || true
    
  echo "JaCoCo coverage dumped at $(date)"
done
