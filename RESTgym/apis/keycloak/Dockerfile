FROM ubuntu:22.04

ENV API=keycloak
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy python3-requests curl && \
    apt -y autoremove

COPY ./apis/keycloak/ /api/

# Copy OpenAPI specifications for test generation
COPY apis/keycloak/specifications/ /api/specifications/

COPY apis/infrastructure/ /infrastructure/
COPY apis/keycloak/auth.py /api/

ENV KC_HOME_DIR=/api
ENV KC_CONF_DIR=/api/conf

# Expose ports - must be before CMD/ENTRYPOINT
EXPOSE 8080 9090 12345

# Pre-build Keycloak to avoid runtime build issues
RUN cd /api && \
    export KEYCLOAK_ADMIN=admin && \
    export KEYCLOAK_ADMIN_PASSWORD=admin && \
    ./bin/kc.sh build --health-enabled=true 2>&1 | tee /tmp/keycloak-prebuild.log || echo "Pre-build completed with warnings"

COPY apis/keycloak/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
