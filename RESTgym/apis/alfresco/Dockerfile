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

# Install mitmproxy, requests, and pyyaml for WFC auth
RUN pip3 install mitmproxy requests pyyaml

# Initialize PostgreSQL data directory
RUN mkdir -p /var/lib/pgsql/data && \
    chown -R postgres:postgres /var/lib/pgsql && \
    su - postgres -c "/usr/bin/initdb -D /var/lib/pgsql/data"

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Copy all API files (specifications, classes, auth, entrypoint)
COPY ./apis/alfresco/ /api/
COPY apis/infrastructure/ /infrastructure/

# Move auth.py to mitmproxy directory for compatibility
RUN cp /api/auth.py /infrastructure/mitmproxy/auth.py

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
