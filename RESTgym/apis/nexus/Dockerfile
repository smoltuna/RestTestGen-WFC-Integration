FROM sonatype/nexus3:3.85.0

# Switch to root for installations
USER root

# Environment configuration
ENV API=nexus
ENV NEXUS_CONTEXT=/
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /infrastructure /results /database

# Install dependencies for RESTgym tools
# Nexus3 image is based on Red Hat UBI, use yum
RUN yum install -y \
    python3 \
    python3-pip \
    nc \
    procps \
    findutils && \
    yum clean all

# Install mitmproxy for HTTP interception
RUN pip3 install --no-cache-dir mitmproxy

# Copy infrastructure tools (JaCoCo, mitmproxy)
COPY ./infrastructure/ /infrastructure/

# Copy database initialization (if any)
COPY ./database/ /database/

# Expose RESTgym standard ports
# 9090: mitmproxy reverse proxy (API access)
# 12345: JaCoCo coverage collection
# 8081: Nexus API and frontend (internal)
EXPOSE 9090 12345 8081

# Switch back to nexus user for security
USER nexus

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8081/service/rest/v1/status || exit 1

# Container execution (RESTgym pattern)
CMD mkdir -p /results/$API/$TOOL/$RUN && \
    /opt/sonatype/nexus/bin/nexus run > /results/$API/$TOOL/$RUN/nexus.log 2>&1 & \
    sleep 90 && \
    until curl -sf http://localhost:8081/service/rest/v1/status > /dev/null 2>&1; do \
        echo "Waiting for Nexus to start..." && sleep 10; \
    done && \
    echo "Nexus started successfully" && \
    mitmdump -p 9090 --mode reverse:http://localhost:8081/ -s /infrastructure/mitmproxy/store-interactions.py & \
    tail -f /results/$API/$TOOL/$RUN/nexus.log
