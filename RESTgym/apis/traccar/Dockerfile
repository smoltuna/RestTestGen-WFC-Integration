# Traccar GPS Tracking System - RESTgym Dockerfile
FROM ubuntu:22.04

# Environment variables
ENV API=traccar
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
        python3-pip \
        git && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy
RUN pip3 install mitmproxy

# Create API directories
RUN mkdir -p /api/conf /api/logs /api/data

# Copy RESTgym infrastructure first
COPY ./infrastructure/ /infrastructure/

# Copy API files from apis/traccar/
COPY ./apis/traccar/tracker-server.jar /api/traccar.jar
COPY ./apis/traccar/database/ /database/
COPY ./apis/traccar/schema/ /api/schema/
COPY ./apis/traccar/dictionaries/ /api/dictionaries/
COPY ./apis/traccar/specifications/ /api/specifications/
COPY ./apis/traccar/restgym-api-config.yml /api/
COPY ./apis/traccar/classes/ /api/classes/

# Copy traccar configuration
RUN mkdir -p /api/database && \
    cp /database/traccar.xml /api/conf/traccar.xml && \
    cp /database/schema.sql /api/database/schema.sql

# Set working directory
WORKDIR /api

# Expose RESTgym standard ports
EXPOSE 9090 12345 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/api/server || exit 1

# Container execution command (RESTgym template pattern)
CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.traccar.*,output=tcpserver,port=12345,address=* \
        -Xms512m -Xmx512m \
        -Dfile.encoding=UTF-8 \
        -Djava.net.preferIPv4Stack=true \
        -jar /api/traccar.jar /api/conf/traccar.xml 2>&1 | tee /results/$API/$TOOL/$RUN/traccar.log
