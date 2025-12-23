FROM k8ssandra/cass-management-api:4.0.18

# Switch to root for installation
USER root

# Environment configuration
ENV API=cassandra-management-api
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV USE_MGMT_API=true
ENV MGMT_API_LISTEN_TCP_PORT=8080
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Install mitmproxy for HTTP interception
RUN apt-get update && \
    apt-get -y install python3 python3-pip && \
    pip3 install mitmproxy && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy all API files including specifications, classes, database scripts
COPY ./apis/cassandra-management-api/ /api/
COPY apis/infrastructure/ /infrastructure/

# Install netcat for port checking
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

RUN chmod +x /api/entrypoint.sh

EXPOSE 9090 12345 8080 9042

ENTRYPOINT ["/api/entrypoint.sh"]
