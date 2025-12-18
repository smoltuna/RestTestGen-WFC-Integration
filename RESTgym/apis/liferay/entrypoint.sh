#!/bin/bash
set -e

echo "=== Starting Liferay RESTgym Container ==="

# Setup result directories
mkdir -p /results/$API/$TOOL/$RUN/code-coverage
mkdir -p /results/$API/$TOOL/$RUN/logs
cp -r /api/specifications /results/$API/$TOOL/$RUN/

# Configure Liferay portal-ext.properties for test user
echo "Configuring Liferay..."
cat > /opt/liferay/portal-ext.properties << EOF
setup.wizard.enabled=false
default.admin.password=universe
default.admin.screen.name=restapitestteam
default.admin.email.address=restapitestteam@gmail.com
default.admin.first.name=RESTapi
default.admin.last.name=Tester
EOF

# Start JaCoCo coverage collector
echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh > /results/$API/$TOOL/$RUN/logs/jacoco.log 2>&1 &

# Start mitmproxy in background
echo "Starting mitmproxy..."
mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
    -s /infrastructure/mitmproxy/store-interactions.py \
    -s /api/auth.py \
    > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &

# Start Liferay with JaCoCo agent
echo "Starting Liferay Portal (this takes 2-3 minutes)..."
export CATALINA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.liferay.*,output=tcpserver,port=12345,address=*"

cd /opt/liferay
/opt/liferay/tomcat*/bin/catalina.sh run > /results/$API/$TOOL/$RUN/logs/liferay-stdout.log 2> /results/$API/$TOOL/$RUN/logs/liferay-stderr.log
