# Kafka REST Proxy - RESTgym Dockerfile with JaCoCo
# Based on official Confluent Kafka REST image with RESTgym instrumentation

FROM confluentinc/cp-kafka-rest:7.5.0 AS kafka-rest-base

FROM ubuntu:22.04

# Environment variables
ENV API=kafka-rest
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive
ENV KAFKA_REST_HOST_NAME=localhost
ENV KAFKA_REST_LISTENERS=http://0.0.0.0:8082
ENV KAFKA_REST_BOOTSTRAP_SERVERS=kafka:29092
ENV KAFKA_REST_SCHEMA_REGISTRY_URL=http://schema-registry:8081

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results /api/classes

# Install required packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-17-jdk \
        curl \
        wget \
        netcat \
        python3 \
        python3-pip \
        unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy
RUN pip3 install mitmproxy

# Copy RESTgym infrastructure
COPY apis/infrastructure/ /infrastructure/

COPY apis/kafka-rest/specifications/ /api/specifications/



# Copy Kafka REST binaries and scripts from official image
COPY --from=kafka-rest-base /usr/share/java/kafka-rest-lib /usr/share/java/kafka-rest-lib
COPY --from=kafka-rest-base /usr/share/java/kafka-rest-bin /usr/share/java/kafka-rest-bin
COPY --from=kafka-rest-base /usr/share/java/rest-utils /usr/share/java/rest-utils
COPY --from=kafka-rest-base /usr/share/java/confluent-common /usr/share/java/confluent-common
COPY --from=kafka-rest-base /usr/share/java/confluent-telemetry /usr/share/java/confluent-telemetry
COPY --from=kafka-rest-base /usr/share/java/monitoring-interceptors /usr/share/java/monitoring-interceptors
COPY --from=kafka-rest-base /etc/kafka-rest /etc/kafka-rest
COPY --from=kafka-rest-base /usr/bin/kafka-rest-start /usr/bin/kafka-rest-start
COPY --from=kafka-rest-base /usr/bin/kafka-rest-run-class /usr/bin/kafka-rest-run-class
COPY --from=kafka-rest-base /usr/bin/kafka-rest-stop /usr/bin/kafka-rest-stop

# Extract classes for JaCoCo coverage from Kafka REST JAR
RUN cd /api/classes && \
    unzip -q /usr/share/java/kafka-rest-lib/kafka-rest-7.5.0.jar 'io/confluent/**/*.class' 2>/dev/null || true && \
    chmod +x /usr/bin/kafka-rest-*

# Set working directory
WORKDIR /etc/kafka-rest

EXPOSE 8082 9090 12345




CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8082/ -s /infrastructure/mitmproxy/store-interactions.py & \
    export KAFKAREST_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=io.confluent.*,output=tcpserver,port=12345,address=*" && \
    /usr/bin/kafka-rest-start /etc/kafka-rest/kafka-rest.properties
