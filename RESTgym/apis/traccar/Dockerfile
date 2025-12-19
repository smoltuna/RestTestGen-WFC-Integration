# Traccar GPS Tracking System - RESTgym Dockerfile
FROM ubuntu:22.04

# Environment variables
ENV API=traccar
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
COPY apis/infrastructure/ /infrastructure/

# Copy all API files from apis/traccar/
COPY ./apis/traccar/ /api/

# Copy traccar configuration
RUN mkdir -p /api/database /api/conf && \
    cp /api/database/traccar.xml /api/conf/traccar.xml

# Set working directory
WORKDIR /api

# Expose RESTgym standard ports
EXPOSE 9090 12345 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/api/server || exit 1

# Container execution command (RESTgym template pattern)
CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --set confdir=/results/$API/$TOOL/$RUN --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.traccar.*,output=tcpserver,port=12345,address=* \
        -cp "/api/tracker-server.jar:/api/lib/*" \
        -Xms512m -Xmx512m \
        -Dfile.encoding=UTF-8 \
        -Djava.net.preferIPv4Stack=true \
        org.traccar.Main /api/conf/traccar.xml 2>&1 | tee /results/$API/$TOOL/$RUN/traccar.log
