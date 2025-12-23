#!/bin/bash
set -e

mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

echo "Starting Cassandra Management API (mgmtapi mode)..."

# Source the original docker-entrypoint behavior but modify for our needs
export CASSANDRA_CONF=/etc/cassandra

# Start Cassandra in background
echo "Starting Cassandra..."
cassandra -R > /results/$API/$TOOL/$RUN/logs/cassandra.log 2>&1 &
CASSANDRA_PID=$!

echo "Waiting for Cassandra to start (up to 120 seconds)..."
for i in {1..120}; do
  if cqlsh -e "SELECT release_version FROM system.local" > /dev/null 2>&1; then
    echo "Cassandra is ready!"
    break
  fi
  if [ $i -eq 120 ]; then
    echo "Cassandra failed to start in time, checking logs..."
    tail -50 /results/$API/$TOOL/$RUN/logs/cassandra.log
    exit 1
  fi
  sleep 1
done

echo "Running CQL initialization script..."
cqlsh -f /api/database/init-test-data.cql || echo "CQL initialization completed with warnings"

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh &

echo "Starting Management API on port 8080..."
# Use the management API jar that comes with the image
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.datastax.mgmtapi.*:io.k8ssandra.*,output=tcpserver,port=12345,address=* \
    -Xms128m -Xmx256m \
    -jar /opt/management-api/datastax-mgmtapi-server.jar \
    --host tcp://0.0.0.0:8080 \
    --cassandra-socket /tmp/cassandra.sock \
    --db-socket /tmp/cassandra.sock \
    --cassandra-home /opt/cassandra > /results/$API/$TOOL/$RUN/logs/mgmtapi.log 2>&1 &
MGMT_PID=$!

echo "Waiting for Management API to start (up to 60 seconds)..."
for i in {1..60}; do
  if curl -s http://localhost:8080/api/v0/probes/liveness > /dev/null 2>&1; then
    echo "Management API is ready!"
    break
  fi
  if [ $i -eq 60 ]; then
    echo "Management API failed to start in time, checking logs..."
    tail -50 /results/$API/$TOOL/$RUN/logs/mgmtapi.log
    exit 1
  fi
  sleep 1
done

echo "Starting mitmproxy on port 9090..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to bind to port 9090..."
for i in {1..15}; do
  if nc -z localhost 9090 2>/dev/null; then
    echo "mitmproxy is ready on port 9090!"
    break
  fi
  if [ $i -eq 15 ]; then
    echo "mitmproxy failed to start"
    exit 1
  fi
  sleep 1
done

echo "All services started successfully! Keeping container alive..."
# Keep container running
wait $MGMT_PID
