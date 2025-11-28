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

# Copy pre-built JAR and dependencies
COPY tracker-server.jar /api/traccar.jar
COPY target/lib /api/lib

# Copy RESTgym infrastructure first (needed for config)
COPY ./infrastructure/ /infrastructure/
COPY ./database/ /database/

# Copy traccar configuration from database directory
RUN cp /database/traccar.xml /api/conf/traccar.xml

# Copy schema directory for Liquibase
COPY ./schema/ /api/schema/
# Copy database schema.sql where Liquibase can find it
COPY ./database/schema.sql /api/database/schema.sql

# Copy remaining RESTgym files
COPY ./dictionaries/ /api/dictionaries/
COPY ./specifications/ /api/specifications/
COPY ./restgym-api-config.yml /api/
COPY ./README.md /api/
COPY ./classes/ /api/classes/

# Set working directory
WORKDIR /api

# Expose RESTgym standard ports
EXPOSE 9090 12345 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8080/api/server || exit 1

# Copy and setup startup script
COPY start-restgym.sh /start-restgym.sh
RUN chmod +x /start-restgym.sh

# Container execution command (RESTgym template pattern)
CMD ["/start-restgym.sh"]
