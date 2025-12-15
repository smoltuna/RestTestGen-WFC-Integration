#!/bin/bash
set -e

echo "==================================="
echo "Starting Alfresco Content Services"
echo "API: $API, TOOL: $TOOL, RUN: $RUN"
echo "==================================="

# Create results directories
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs
cp -r /api/specifications /results/$API/$TOOL/$RUN/
touch /results/$API/$TOOL/$RUN/logs/postgres.log
chown postgres:postgres /results/$API/$TOOL/$RUN/logs/postgres.log

# Start PostgreSQL
echo "Starting PostgreSQL..."
su - postgres -c "/usr/bin/pg_ctl -D /var/lib/pgsql/data -l /results/$API/$TOOL/$RUN/logs/postgres.log start"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
for i in {1..30}; do
  if su - postgres -c "psql -c 'SELECT 1'" > /dev/null 2>&1; then
    echo "PostgreSQL is ready!"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "PostgreSQL failed to start"
    cat /results/$API/$TOOL/$RUN/logs/postgres.log
    exit 1
  fi
  sleep 1
done

# Create Alfresco database and user
echo "Creating Alfresco database..."
su - postgres -c "psql -c \"CREATE DATABASE alfresco;\""
su - postgres -c "psql -c \"CREATE USER alfresco WITH PASSWORD 'alfresco';\""
su - postgres -c "psql -c \"ALTER DATABASE alfresco OWNER TO alfresco;\""
su - postgres -c "psql -d alfresco -c \"GRANT ALL PRIVILEGES ON SCHEMA public TO alfresco;\""

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh > /results/$API/$TOOL/$RUN/logs/jacoco.log 2>&1 &
JACOCO_PID=$!

# Configure Alfresco environment variables  
# Use PostgreSQL database
export JAVA_TOOL_OPTIONS="-Dencryption.keystore.type=JCEKS \
    -Dencryption.cipherAlgorithm=DESede/CBC/PKCS5Padding \
    -Dencryption.keyAlgorithm=DESede \
    -Dencryption.keystore.location=/usr/local/tomcat/shared/classes/alfresco/extension/keystore/keystore \
    -Dmetadata-keystore.password=mp6yc0UD9e \
    -Dmetadata-keystore.aliases=metadata \
    -Dmetadata-keystore.metadata.password=oKIWzVdEdA \
    -Dmetadata-keystore.metadata.algorithm=DESede"

# Configure JAVA_OPTS with JaCoCo agent and Alfresco settings
export JAVA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.alfresco.*,output=tcpserver,port=12345,address=* \
    -Ddb.driver=org.postgresql.Driver \
    -Ddb.username=alfresco \
    -Ddb.password=alfresco \
    -Ddb.url=jdbc:postgresql://localhost:5432/alfresco \
    -Dindex.subsystem.name=noindex \
    -Dalfresco.host=localhost \
    -Dalfresco.port=8080 \
    -Dcsrf.filter.enabled=false \
    -Dlocal.transform.service.enabled=false \
    -Dtransform.service.enabled=false \
    -Dauthentication.chain=alfrescoNtlm1:alfrescoNtlm \
    -Dsample.site.disabled=false \
    -Xms512m -Xmx1g"

echo "Starting Alfresco in background..."
/usr/local/tomcat/bin/catalina.sh run > /results/$API/$TOOL/$RUN/logs/alfresco-stdout.log 2> /results/$API/$TOOL/$RUN/logs/alfresco-stderr.log &
ALFRESCO_PID=$!

echo "Waiting for Alfresco to start..."
for i in {1..180}; do
  if curl -s -u admin:admin http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready- > /dev/null 2>&1; then
    echo "Alfresco is ready!"
    break
  fi
  if [ $i -eq 180 ]; then
    echo "Alfresco failed to start in time"
    echo "=== Last 50 lines of stdout ==="
    tail -50 /results/$API/$TOOL/$RUN/logs/alfresco-stdout.log
    echo "=== Last 50 lines of stderr ==="
    tail -50 /results/$API/$TOOL/$RUN/logs/alfresco-stderr.log
    exit 1
  fi
  echo "Waiting... ($i/180)"
  sleep 2
done

echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
  -s /infrastructure/mitmproxy/store-interactions.py \
  -s /infrastructure/mitmproxy/auth.py \
  > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "Waiting for mitmproxy to start..."
sleep 5

echo "All services started. Waiting for Alfresco process..."
wait $ALFRESCO_PID
