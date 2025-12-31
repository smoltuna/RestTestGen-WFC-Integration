#!/bin/bash
set -e

mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

echo "Starting JaCoCo coverage collector..."
sh /api/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting Nexus..."
export INSTALL4J_ADD_VM_PARAMS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=org.sonatype.*:com.sonatype.*,output=tcpserver,port=12345,address=* -Xms${JAVA_MIN_MEM} -Xmx${JAVA_MAX_MEM}"
/opt/sonatype/nexus/bin/nexus run > /results/$API/$TOOL/$RUN/logs/nexus-stdout.log 2>&1 &
NEXUS_PID=$!

echo "Waiting for Nexus to start (this may take 2-3 minutes)..."
for i in {1..180}; do
  if curl -s -u admin:admin123 http://localhost:8081/service/rest/v1/status > /dev/null 2>&1; then
    echo "Nexus is ready!"
    break
  fi
  if [ $i -eq 180 ]; then
    echo "Nexus failed to start in time"
    cat /results/$API/$TOOL/$RUN/logs/nexus-stdout.log | tail -100
    exit 1
  fi
  sleep 1
done

# Create user restapitestteam@gmail.com with password universe
echo "Creating user restapitestteam@gmail.com..."
curl -s -u admin:admin123 -X POST "http://localhost:8081/service/rest/v1/security/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "restapitestteam",
    "firstName": "REST API",
    "lastName": "Test Team",
    "emailAddress": "restapitestteam@gmail.com",
    "password": "universe",
    "status": "active",
    "roles": ["nx-admin"]
  }' && echo "User created successfully" || echo "User may already exist"

# Wait a moment for user to be fully created
sleep 2

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8081/ \
  -s /infrastructure/mitmproxy/store-interactions.py \
  > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 5

echo "All services started and ready for testing."
echo "Mitmproxy PID: $MITM_PID"
echo "Nexus PID: $NEXUS_PID"
echo "JaCoCo PID: $JACOCO_PID"

# Keep container running - wait for all processes
while kill -0 $NEXUS_PID 2>/dev/null && kill -0 $MITM_PID 2>/dev/null; do
  sleep 5
done

echo "One or more services stopped. Shutting down..."
kill $NEXUS_PID $MITM_PID $JACOCO_PID 2>/dev/null || true
wait
