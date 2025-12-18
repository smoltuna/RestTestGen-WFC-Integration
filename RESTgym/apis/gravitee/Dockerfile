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

COPY apis/gravitee/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
