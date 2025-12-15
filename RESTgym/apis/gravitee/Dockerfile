FROM ubuntu:22.04

ENV API=gravitee
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /api /infrastructure /results

# Install required packages including mitmproxy and MongoDB
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-21-jdk \
        curl \
        wget \
        netcat \
        sqlite3 \
        python3 \
        python3-pip \
        gnupg && \
    pip3 install mitmproxy requests pymongo 'bcrypt<4.0.0' && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get -y install mongodb-org && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Gravitee Management API
RUN wget -q https://download.gravitee.io/graviteeio-apim/distributions/graviteeio-full-4.9.7.zip -O /tmp/gravitee.zip && \
    apt-get update && \
    apt-get -y install unzip && \
    unzip -q /tmp/gravitee.zip -d /opt && \
    mv /opt/graviteeio-full-* /opt/graviteeio && \
    rm /tmp/gravitee.zip && \
    apt-get -y remove unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY apis/gravitee/classes/ /api/classes/


COPY apis/gravitee/database/ /api/database/

# Copy OpenAPI specifications for test generation
COPY apis/gravitee/specifications/ /api/specifications/

# Copy auth.py for mitmproxy
COPY apis/gravitee/auth.py /api/auth.py

# Copy database user creation script
COPY apis/gravitee/create-db-user.py /api/create-db-user.py

# Copy gravitee-specific JaCoCo collection scripts
COPY apis/gravitee/collect-coverage.sh /api/collect-coverage.sh
COPY apis/gravitee/collect-coverage-interval.sh /api/collect-coverage-interval.sh
RUN chmod +x /api/collect-coverage.sh /api/collect-coverage-interval.sh

COPY apis/infrastructure/ /infrastructure/

# Upgrade JaCoCo to 0.8.12 for Java 21 support (Gravitee requires Java 21)
#RUN wget -q https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.12/org.jacoco.agent-0.8.12-runtime.jar -O /infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar && \
#    wget -q https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.12/org.jacoco.cli-0.8.12-nodeps.jar -O /infrastructure/jacoco/org.jacoco.cli-0.8.12-nodeps.jar

COPY apis/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar /infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar
COPY apis/infrastructure/jacoco/org.jacoco.cli-0.8.12-nodeps.jar /infrastructure/jacoco/org.jacoco.cli-0.8.12-nodeps.jar

# Expose RESTgym standard ports
# 9090: mitmproxy (reverse proxy to Gravitee)
# 12345: JaCoCo TCP server
# 8083: Gravitee Management API internal port
EXPOSE 9090 12345 8083

# Set MongoDB connection for Gravitee
ENV gravitee_management_type=mongodb
ENV gravitee_management_mongodb_uri=mongodb://localhost:27017/gravitee?serverSelectionTimeoutMS=5000&connectTimeoutMS=5000&socketTimeoutMS=5000
ENV gravitee_ratelimit_type=mongodb
ENV gravitee_ratelimit_mongodb_uri=mongodb://localhost:27017/gravitee?serverSelectionTimeoutMS=5000&connectTimeoutMS=5000&socketTimeoutMS=5000

# Disable Elasticsearch analytics completely
ENV gravitee_analytics_type=none
ENV gravitee_analytics_elasticsearch_enabled=false

# Configure Gravitee to listen on port 8083
ENV gravitee_http_port=8083

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
mkdir -p /results/$API/$TOOL/$RUN/code-coverage\n\
cp -r /api/specifications /results/$API/$TOOL/$RUN/\n\
mkdir -p /data/db\n\
mkdir -p /results/$API/$TOOL/$RUN/logs\n\
mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db\n\
echo "Waiting for MongoDB to start..."\n\
sleep 10\n\
\n\
echo "Creating user in MongoDB..."\n\
python3 /api/create-db-user.py || echo "User creation completed with warnings"\n\
\n\
echo "Starting JaCoCo coverage collector..."\n\
sh /api/collect-coverage-interval.sh &\n\
JACOCO_PID=$!\n\
\n\
echo "Starting Gravitee API in background..."\n\
cd /opt/graviteeio/graviteeio-apim-rest-api-4.9.7\n\
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=io.gravitee.*,output=tcpserver,port=12345,address=* \\\n\
    -Dfile.encoding=UTF-8 \\\n\
    -Djava.io.tmpdir=/tmp \\\n\
    -Dgravitee.home=/opt/graviteeio/graviteeio-apim-rest-api-4.9.7 \\\n\
    -Dgravitee.management.type=mongodb \\\n\
    -Dgravitee.management.mongodb.uri=$gravitee_management_mongodb_uri \\\n\
    -Dgravitee.ratelimit.type=mongodb \\\n\
    -Dgravitee.ratelimit.mongodb.uri=$gravitee_ratelimit_mongodb_uri \\\n\
    -jar lib/gravitee-apim-rest-api-standalone-bootstrap-4.9.7.jar > /results/$API/$TOOL/$RUN/logs/gravitee-stdout.log 2>&1 &\n\
GRAVITEE_PID=$!\n\
\n\
echo "Waiting for Gravitee to start (this may take 30-60 seconds)..."\n\
for i in {1..60}; do\n\
  if curl -s http://localhost:8083/management/organizations > /dev/null 2>&1; then\n\
    echo "Gravitee is ready!"\n\
    break\n\
  fi\n\
  if [ $i -eq 60 ]; then\n\
    echo "Gravitee failed to start in time"\n\
    exit 1\n\
  fi\n\
  sleep 1\n\
done\n\
\n\

echo "Starting mitmproxy..."\n\
mitmdump -p 9090 --mode reverse:http://localhost:8083/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &\n\
MITM_PID=$!\n\
\n\
echo "Waiting for mitmproxy to start..."\n\
sleep 10\n\
\n\
echo "All services started. Waiting for Gravitee process..."\n\
wait $GRAVITEE_PID\n\
' > /start.sh && chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
