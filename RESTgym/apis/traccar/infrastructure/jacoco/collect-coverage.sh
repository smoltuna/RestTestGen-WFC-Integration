#!/bin/bash
# JaCoCo coverage collection script - RESTgym
# Dumps coverage data from JaCoCo agent and generates reports

sample_time=$(date +"%Y-%m-%dT%H.%M.%S")
exec_file=/results/$API/$TOOL/$RUN/code-coverage/jacoco_$sample_time.exec
csv_file=/results/$API/$TOOL/$RUN/code-coverage/jacoco_$sample_time.csv

# Create code-coverage directory if it doesn't exist
mkdir -p /results/$API/$TOOL/$RUN/code-coverage

# Dump coverage data from JaCoCo agent
java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7.jar dump --address localhost --port 12345 --destfile $exec_file

# Generate CSV report (optional - skip if class files not found)
if [ -d "/api/classes/" ]; then
    class_files=$(find /api/classes/ -type f -name "*.class" 2>/dev/null | tr '\n' ' ' | sed 's/.\{1\}$//' | sed 's/\ /\ --classfiles\ /g')
    if [ ! -z "$class_files" ]; then
        java -jar /infrastructure/jacoco/org.jacoco.cli-0.8.7.jar report $exec_file --classfiles $class_files --csv $csv_file 2>/dev/null || true
    fi
fi

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Coverage dumped: $exec_file"
