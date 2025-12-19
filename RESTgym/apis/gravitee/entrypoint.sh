#!/bin/bash
set -e
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /data/db
mkdir -p /results/$API/$TOOL/$RUN/logs
mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db
echo "Waiting for MongoDB to start..."
sleep 10

echo "Creating user in MongoDB..."
python3 /api/create-db-user.py || echo "User creation completed with warnings"

echo "Starting JaCoCo coverage collector..."
sh /api/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting Gravitee API in background..."
cd /api
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=io.gravitee.*,output=tcpserver,port=12345,address=* \
    -Dfile.encoding=UTF-8 \
    -Djava.io.tmpdir=/tmp \
    -Dgravitee.home=/api \
    -Dgravitee.management.type=mongodb \
    -Dgravitee.management.mongodb.uri=$gravitee_management_mongodb_uri \
    -Dgravitee.ratelimit.type=mongodb \
    -Dgravitee.ratelimit.mongodb.uri=$gravitee_ratelimit_mongodb_uri \
    -jar /api/lib/gravitee-apim-rest-api-standalone-bootstrap-4.9.7.jar > /results/$API/$TOOL/$RUN/logs/gravitee-stdout.log 2>&1 &
GRAVITEE_PID=$!

echo "Waiting for Gravitee to start (this may take 30-60 seconds)..."
for i in {1..60}; do
  if curl -s http://localhost:8083/management/organizations > /dev/null 2>&1; then
    echo "Gravitee is ready!"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "Gravitee failed to start in time"
    exit 1
  fi
  sleep 1
done

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8083/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 10

echo "All services started. Waiting for Gravitee process..."
wait $GRAVITEE_PID
