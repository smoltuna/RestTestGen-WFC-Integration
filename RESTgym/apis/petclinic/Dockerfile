# Spring PetClinic REST API - RESTgym Container
FROM ubuntu:22.04

# Environment configuration
ENV API=petclinic
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
        python3-pip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy
RUN pip3 install mitmproxy

# Copy API application
COPY apis/petclinic/spring-petclinic-rest.jar /api/spring-petclinic-rest.jar

# Copy classes for JaCoCo coverage analysis
COPY apis/petclinic/classes/ /api/classes/

# Copy database initialization files (H2 schema and data)
COPY apis/petclinic/database/ /api/database/

# Copy OpenAPI specifications for test generation
COPY apis/petclinic/specifications/ /api/specifications/

# Copy infrastructure tools from common RESTgym infrastructure
COPY apis/infrastructure/ /infrastructure/

# Expose RESTgym standard ports
# 9090: mitmproxy reverse proxy (API access)
# 12345: JaCoCo coverage collection
# 8080: Internal API port
EXPOSE 9090 12345 8080


COPY apis/petclinic/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
