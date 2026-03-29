#!/bin/bash
set -e

echo "=== Starting Liferay RESTgym Container ==="

# Setup result directories
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs

# Configure Liferay portal-ext.properties for test user
echo "Configuring Liferay..."
cat > /opt/liferay/portal-ext.properties << EOF
setup.wizard.enabled=false
default.admin.password=universe
default.admin.screen.name=restapitestteam
default.admin.email.address=restapitestteam@gmail.com
default.admin.first.name=RESTapi
default.admin.last.name=Tester
company.default.locale=en_US
locales.enabled=en_US
locales=en_US
EOF

# Start JaCoCo coverage collector
echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh > /results/$API/$TOOL/$RUN/logs/jacoco.log 2>&1 &
JACOCO_PID=$!

# Start mitmproxy in background
echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
    -s /infrastructure/mitmproxy/store-interactions.py \
    > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

# Find tomcat directory
TOMCAT_DIR=$(ls -d /opt/liferay/tomcat* | head -1)
echo "Using Tomcat at: $TOMCAT_DIR"

# Start Liferay with JaCoCo agent
echo "Starting Liferay Portal (this takes 2-3 minutes)..."
export CATALINA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.liferay.*,output=tcpserver,port=12345,address=*"

cd /opt/liferay
$TOMCAT_DIR/bin/catalina.sh run > /results/$API/$TOOL/$RUN/logs/liferay-stdout.log 2> /results/$API/$TOOL/$RUN/logs/liferay-stderr.log
