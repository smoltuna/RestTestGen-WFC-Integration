FROM quay.io/keycloak/keycloak:23.0.7

# Switch to root for installation
USER root

# Environment configuration
ENV API=keycloak
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /infrastructure /results /database

# Install dependencies for RESTgym tools
RUN microdnf install -y \
    python3 \
    python3-pip \
    nc \
    procps \
    findutils && \
    microdnf clean all

# Install mitmproxy for HTTP interception
RUN pip3 install --no-cache-dir mitmproxy

# Copy infrastructure tools (JaCoCo, mitmproxy)
COPY ./infrastructure/ /infrastructure/

# Copy database initialization (if any)
COPY ./database/ /database/

# Expose RESTgym standard ports
# 9090: mitmproxy reverse proxy (API access)
# 12345: JaCoCo coverage collection (not applicable for Quarkus native)
# 8080: Keycloak Admin API and frontend
EXPOSE 9090 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health/ready || exit 1

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    /opt/keycloak/bin/kc.sh start-dev > /results/$API/$TOOL/$RUN/keycloak.log 2>&1 & \
    sleep 45 && \
    until curl -sf http://localhost:8080/health/ready > /dev/null 2>&1; do sleep 5; done && \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    tail -f /results/$API/$TOOL/$RUN/keycloak.log
