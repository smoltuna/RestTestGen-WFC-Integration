# Flowable Process Engine REST API - RESTgym Container
FROM ubuntu:22.04

# Environment configuration
ENV API=flowable-process
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk curl python3 python3-pip && \
    pip3 install mitmproxy pyyaml requests && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/*

# Copy all API files (war, classes, specifications, config, auth)
COPY ./apis/flowable-process/ /api/
COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

RUN chmod +x /api/entrypoint.sh

CMD ["/api/entrypoint.sh"]
