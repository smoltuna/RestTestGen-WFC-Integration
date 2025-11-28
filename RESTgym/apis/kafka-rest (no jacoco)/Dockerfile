# Kafka REST Proxy - RESTgym Compatible Dockerfile
# Note: This API requires a full Kafka cluster (Zookeeper, Kafka, Schema Registry)
# Use docker-compose-restgym.yml to run the complete stack
FROM ubuntu:22.04

# API identification
ENV API=kafka-rest
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

# Copy infrastructure
COPY ./infrastructure/ /infrastructure/

# Note: Kafka REST Proxy JAR is provided by Confluent Platform
# This Dockerfile is a placeholder - use docker-compose-restgym.yml instead
# The docker-compose file includes:
# - Zookeeper (port 2181)
# - Kafka (port 9092)
# - Schema Registry (port 8081)
# - Kafka REST Proxy with mitmproxy (port 9090 -> 8082)

# Expose RESTgym standard ports
# 9090: mitmproxy (API access point - RESTgym standard)
# 12345: JaCoCo TCP server (not applicable for pre-built binary)
# 8082: Kafka REST Proxy internal port
EXPOSE 9090 12345 8082

# This Dockerfile serves as PLACEHOLDER for RESTgym template compliance
# Actual deployment uses docker-compose-restgym.yml
CMD echo "⚠️  PLACEHOLDER DOCKERFILE - Use docker-compose instead" && \
    echo "" && \
    echo "Kafka REST Proxy requires multi-service stack:" && \
    echo "  • Zookeeper (cluster coordination)" && \
    echo "  • Kafka Broker (message storage)" && \
    echo "  • Schema Registry (schema management)" && \
    echo "  • Kafka REST Proxy (REST API)" && \
    echo "  • Mitmproxy (RESTgym instrumentation)" && \
    echo "" && \
    echo "Usage:" && \
    echo "  docker-compose -f docker-compose-restgym.yml up -d" && \
    echo "" && \
    echo "Access API via mitmproxy: http://localhost:9090" && \
    echo "See README.md for complete testing guide" && \
    echo "" && \
    sleep infinity
