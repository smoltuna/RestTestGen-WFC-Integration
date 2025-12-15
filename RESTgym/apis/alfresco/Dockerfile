# Alfresco Content Services - RESTgym Container
# Using official Alfresco image with embedded H2 database
FROM alfresco/alfresco-content-repository-community:7.4.1

# Environment configuration
ENV API=alfresco
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

# Switch to root to install packages
USER root

# Install required packages for RESTgym using dnf (Rocky Linux)
RUN dnf install -y \
        curl \
        wget \
        nmap-ncat \
        sqlite \
        python39 \
        python39-pip \
        postgresql-server \
        postgresql-contrib && \
    dnf clean all

# Install mitmproxy
RUN pip3 install mitmproxy

# Initialize PostgreSQL data directory
RUN mkdir -p /var/lib/pgsql/data && \
    chown -R postgres:postgres /var/lib/pgsql && \
    su - postgres -c "/usr/bin/initdb -D /var/lib/pgsql/data"

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Copy OpenAPI specifications for test generation
COPY apis/alfresco/specifications/ /api/specifications/

# Copy infrastructure tools from common RESTgym infrastructure
COPY apis/infrastructure/ /infrastructure/

# Copy authentication script
COPY apis/alfresco/auth.py /infrastructure/mitmproxy/auth.py

# Copy pre-extracted Alfresco class files for JaCoCo coverage analysis
COPY apis/alfresco/classes/ /api/classes/

# Copy entrypoint script
COPY apis/alfresco/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose RESTgym standard ports
# 9090: mitmproxy reverse proxy (API access)
# 12345: JaCoCo coverage collection
# 8080: Internal API port (Tomcat)
EXPOSE 9090 12345 8080

# Set working directory
WORKDIR /usr/local/tomcat

ENTRYPOINT ["/entrypoint.sh"]
