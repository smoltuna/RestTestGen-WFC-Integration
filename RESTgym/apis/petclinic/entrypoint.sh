#!/bin/bash
set -e
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting PetClinic API in background..."
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.springframework.samples.petclinic.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -Dspring.profiles.active=h2,spring-data-jpa -jar /api/spring-petclinic-rest.jar > /results/$API/$TOOL/$RUN/logs/petclinic-stdout.log 2> /results/$API/$TOOL/$RUN/logs/petclinic-stderr.log &
PETCLINIC_PID=$!

echo "Waiting for API to start..."
for i in {1..60}; do
  if curl -s http://localhost:8080/vets > /dev/null 2>&1; then
    echo "API is ready!"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "API failed to start in time"
    exit 1
  fi
  sleep 1
done

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 10

echo "All services started. Waiting for PetClinic process..."
wait $PETCLINIC_PID
