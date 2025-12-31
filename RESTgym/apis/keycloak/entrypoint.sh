#!/bin/bash
set -e
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

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

# Get admin token
echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:8080/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=admin-cli&username=admin&password=admin" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

# Create user restapitestteam@gmail.com
echo "Creating user restapitestteam@gmail.com..."
curl -s -X POST "http://localhost:8080/admin/realms/master/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "restapitestteam@gmail.com",
    "email": "restapitestteam@gmail.com",
    "enabled": true,
    "credentials": [{"type": "password", "value": "universe", "temporary": false}]
  }' && echo "User created" || echo "User may already exist"

# Get user ID
USER_ID=$(curl -s "http://localhost:8080/admin/realms/master/users?username=restapitestteam@gmail.com" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -c "import sys, json; users=json.load(sys.stdin); print(users[0]['id'] if users else '')")

# Assign admin role to the user
if [ -n "$USER_ID" ]; then
  echo "Assigning admin role to user..."
  ADMIN_ROLE=$(curl -s "http://localhost:8080/admin/realms/master/roles/admin" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  curl -s -X POST "http://localhost:8080/admin/realms/master/users/$USER_ID/role-mappings/realm" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "[$ADMIN_ROLE]" && echo "Role assigned" || echo "Role assignment failed"
fi

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
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
