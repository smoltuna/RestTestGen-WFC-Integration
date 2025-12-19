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
        gnupg \
        unzip && \
    pip3 install mitmproxy requests pymongo 'bcrypt<4.0.0' && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get -y install mongodb-org && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy all API files (classes, database, specifications, auth, config, jar, lib)
COPY ./apis/gravitee/ /api/
COPY apis/infrastructure/ /infrastructure/

RUN chmod +x /api/collect-coverage.sh /api/collect-coverage-interval.sh

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
