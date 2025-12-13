FROM ubuntu:22.04

ENV API=keycloak
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy python3-requests curl && \
    apt -y autoremove

COPY ./apis/keycloak/ /api/

# Copy OpenAPI specifications for test generation
COPY apis/keycloak/specifications/ /api/specifications/

COPY apis/infrastructure/ /infrastructure/

ENV JAVA_OPTS="-Xms256m -Xmx2048m"
ENV KC_HOME_DIR=/api
ENV KC_CONF_DIR=/api/conf

# Expose ports
EXPOSE 9090 12345 8080

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
mkdir -p /results/$API/$TOOL/$RUN/code-coverage\n\
mkdir -p /results/$API/$TOOL/$RUN/logs\n\
cp -r /api/specifications /results/$API/$TOOL/$RUN/\n\
\n\
echo "Starting JaCoCo coverage collector..."\n\
sh /infrastructure/jacoco/collect-coverage-interval.sh &\n\
JACOCO_PID=$!\n\
\n\
echo "Building Keycloak (required on first run)..."\n\
cd /api\n\
export KEYCLOAK_ADMIN=admin\n\
export KEYCLOAK_ADMIN_PASSWORD=admin\n\
export JAVA_OPTS="-Xms256m -Xmx2048m"\n\
./bin/kc.sh build --health-enabled=true > /results/$API/$TOOL/$RUN/logs/keycloak-build.log 2>&1\n\
\n\
echo "Starting Keycloak in background..."\n\
export JAVA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.keycloak.*,output=tcpserver,port=12345,address=* -Xms256m -Xmx2048m"\n\
./bin/kc.sh start-dev --http-port=8080 > /results/$API/$TOOL/$RUN/logs/keycloak-stdout.log 2>&1 &\n\
KEYCLOAK_PID=$!\n\
\n\
echo "Waiting for Keycloak to start (this may take 60-90 seconds)..."\n\
for i in {1..90}; do\n\
  if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then\n\
    echo "Keycloak is ready!"\n\
    break\n\
  fi\n\
  if [ $i -eq 90 ]; then\n\
    echo "Keycloak failed to start in time"\n\
    cat /results/$API/$TOOL/$RUN/logs/keycloak-stdout.log\n\
    exit 1\n\
  fi\n\
  sleep 1\n\
done\n\
\n\
echo "Starting mitmproxy..."\n\
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &\n\
MITM_PID=$!\n\
\n\
echo "Waiting for mitmproxy to start..."\n\
sleep 10\n\
\n\
echo "Services started and ready for testing."\n\
echo "Mitmproxy PID: $MITM_PID"\n\
echo "Keycloak PID: $KEYCLOAK_PID"\n\
echo "JaCoCo PID: $JACOCO_PID"\n\
\n\
# Keep container running - wait for all processes\n\
while kill -0 $KEYCLOAK_PID 2>/dev/null && kill -0 $MITM_PID 2>/dev/null; do\n\
  sleep 5\n\
done\n\
\n\
echo "One or more services stopped. Shutting down..."\n\
kill $KEYCLOAK_PID $MITM_PID $JACOCO_PID 2>/dev/null || true\n\
wait\n\
' > /start.sh && chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
