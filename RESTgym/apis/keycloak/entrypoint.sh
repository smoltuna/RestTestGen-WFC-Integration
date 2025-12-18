#!/bin/bash
set -e
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs
cp -r /api/specifications /results/$API/$TOOL/$RUN/

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting Keycloak in background..."
cd /api
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=admin
export JAVA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.keycloak.*,output=tcpserver,port=12345,address=* -Xms256m -Xmx2048m"
./bin/kc.sh start-dev --http-port=8080 > /results/$API/$TOOL/$RUN/logs/keycloak-stdout.log 2>&1 &
KEYCLOAK_PID=$!

echo "Waiting for Keycloak to start (this may take 60-90 seconds)..."
for i in {1..90}; do
  if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
    echo "Keycloak is ready!"
    break
  fi
  if [ $i -eq 90 ]; then
    echo "Keycloak failed to start in time"
    cat /results/$API/$TOOL/$RUN/logs/keycloak-stdout.log
    exit 1
  fi
  sleep 1
done

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 10

echo "Services started and ready for testing."
echo "Mitmproxy PID: $MITM_PID"
echo "Keycloak PID: $KEYCLOAK_PID"
echo "JaCoCo PID: $JACOCO_PID"

# Keep container running - wait for all processes
while kill -0 $KEYCLOAK_PID 2>/dev/null && kill -0 $MITM_PID 2>/dev/null; do
  sleep 5
done

echo "One or more services stopped. Shutting down..."
kill $KEYCLOAK_PID $MITM_PID $JACOCO_PID 2>/dev/null || true
wait
