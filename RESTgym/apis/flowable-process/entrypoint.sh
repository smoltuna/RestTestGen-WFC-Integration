#!/bin/bash
set -e

mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting Flowable REST API..."
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.flowable.*,output=tcpserver,port=12345,address=* \
    -Dfile.encoding=UTF-8 \
    -Dserver.port=8080 \
    -Dspring.config.location=file:/api/application.properties \
    -jar /api/flowable-rest.war > /results/$API/$TOOL/$RUN/logs/flowable-stdout.log 2>&1 &
FLOWABLE_PID=$!

echo "Waiting for Flowable to start (this may take 30-60 seconds)..."
for i in {1..90}; do
  if curl -s -u rest-admin:test http://localhost:8080/flowable-rest/service/repository/deployments > /dev/null 2>&1; then
    echo "Flowable is ready!"
    break
  fi
  if [ $i -eq 90 ]; then
    echo "Flowable failed to start in time"
    cat /results/$API/$TOOL/$RUN/logs/flowable-stdout.log | tail -100
    exit 1
  fi
  sleep 1
done

# Create user restapitestteam@gmail.com with password universe using Flowable Identity API
echo "Creating user restapitestteam@gmail.com..."
curl -s -u rest-admin:test -X POST "http://localhost:8080/flowable-rest/service/identity/users" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "restapitestteam@gmail.com",
    "firstName": "REST API",
    "lastName": "Test Team",
    "email": "restapitestteam@gmail.com",
    "password": "universe"
  }' && echo "User created successfully" || echo "User may already exist"

# Wait a moment for user to be fully created
sleep 2

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
  -s /infrastructure/mitmproxy/store-interactions.py \
  > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 5

echo "All services started and ready for testing."
echo "Mitmproxy PID: $MITM_PID"
echo "Flowable PID: $FLOWABLE_PID"
echo "JaCoCo PID: $JACOCO_PID"

# Keep container running - wait for all processes
while kill -0 $FLOWABLE_PID 2>/dev/null && kill -0 $MITM_PID 2>/dev/null; do
  sleep 5
done

echo "One or more services stopped. Shutting down..."
kill $FLOWABLE_PID $MITM_PID $JACOCO_PID 2>/dev/null || true
wait
