# Spring PetClinic REST API - RESTgym Container
FROM ubuntu:22.04

# Environment configuration
ENV API=petclinic
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Install required packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-17-jdk \
        curl \
        wget \
        netcat \
        sqlite3 \
        python3 \
        python3-pip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy
RUN pip3 install mitmproxy

# Copy API application
COPY apis/petclinic/spring-petclinic-rest.jar /api/spring-petclinic-rest.jar

# Copy classes for JaCoCo coverage analysis
COPY apis/petclinic/classes/ /api/classes/

# Copy database initialization files (H2 schema and data)
COPY apis/petclinic/database/ /api/database/

# Copy OpenAPI specifications for test generation
COPY apis/petclinic/specifications/ /api/specifications/

# Copy infrastructure tools from common RESTgym infrastructure
COPY apis/infrastructure/ /infrastructure/

# Expose RESTgym standard ports
# 9090: mitmproxy reverse proxy (API access)
# 12345: JaCoCo coverage collection
# 8080: Internal API port
EXPOSE 9090 12345 8080

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'mkdir -p /results/$API/$TOOL/$RUN/code-coverage' >> /start.sh && \
    echo 'cp -r /api/specifications /results/$API/$TOOL/$RUN/' >> /start.sh && \
    echo 'mkdir -p /results/$API/$TOOL/$RUN/logs' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Starting JaCoCo coverage collector..."' >> /start.sh && \
    echo 'sh /infrastructure/jacoco/collect-coverage-interval.sh &' >> /start.sh && \
    echo 'JACOCO_PID=$!' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Starting PetClinic API in background..."' >> /start.sh && \
    echo 'java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.springframework.samples.petclinic.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -Dspring.profiles.active=h2,spring-data-jpa -jar /api/spring-petclinic-rest.jar > /results/$API/$TOOL/$RUN/logs/petclinic-stdout.log 2> /results/$API/$TOOL/$RUN/logs/petclinic-stderr.log &' >> /start.sh && \
    echo 'PETCLINIC_PID=$!' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Waiting for PetClinic to start..."' >> /start.sh && \
    echo 'for i in {1..60}; do' >> /start.sh && \
    echo '  if curl -s http://localhost:8080/vets > /dev/null 2>&1; then' >> /start.sh && \
    echo '    echo "PetClinic is ready!"' >> /start.sh && \
    echo '    break' >> /start.sh && \
    echo '  fi' >> /start.sh && \
    echo '  if [ $i -eq 60 ]; then' >> /start.sh && \
    echo '    echo "PetClinic failed to start in time"' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo '  fi' >> /start.sh && \
    echo '  sleep 1' >> /start.sh && \
    echo 'done' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Starting mitmproxy..."' >> /start.sh && \
    echo 'mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &' >> /start.sh && \
    echo 'MITM_PID=$!' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "Waiting for mitmproxy to start..."' >> /start.sh && \
    echo 'sleep 10' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "All services started. Waiting for PetClinic process..."' >> /start.sh && \
    echo 'wait $PETCLINIC_PID' >> /start.sh && \
    chmod +x /start.sh
COPY apis/petclinic/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash", "/start.sh"]
