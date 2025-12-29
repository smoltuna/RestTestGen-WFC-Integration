# Multi-stage Dockerfile per Liferay Portal con JaCoCo coverage
# Stage 1: Estrazione delle classi Java dall'immagine ufficiale Liferay
FROM liferay/portal:7.4.3.120-ga120 AS extractor

USER root

# Crea directory per le classi estratte
RUN mkdir -p /extracted/classes

# Estrai le classi dai moduli headless REST API
RUN find /opt/liferay/tomcat/webapps/ROOT/WEB-INF -name "portal-impl.jar" -o -name "portal-kernel.jar" | while read jar; do \
    mkdir -p /tmp/extract && \
    cd /tmp/extract && \
    unzip -q "$jar" 'com/**/*.class' 2>/dev/null || true && \
    if [ -d "com" ]; then \
        cp -r com /extracted/classes/ 2>/dev/null || true; \
    fi && \
    cd / && rm -rf /tmp/extract; \
    done

# Estrai anche le classi dalla directory WEB-INF/classes
RUN if [ -d /opt/liferay/tomcat/webapps/ROOT/WEB-INF/classes ]; then \
    cp -r /opt/liferay/tomcat/webapps/ROOT/WEB-INF/classes/* /extracted/classes/ 2>/dev/null || true; \
    fi

# Estrai classi da JAR di liferay nella lib
RUN find /opt/liferay/tomcat/webapps/ROOT/WEB-INF/lib -name "com.liferay*.jar" | head -50 | while read jar; do \
    mkdir -p /tmp/extract && \
    cd /tmp/extract && \
    unzip -q "$jar" 'com/**/*.class' 2>/dev/null || true && \
    if [ -d "com" ]; then \
        cp -r com /extracted/classes/ 2>/dev/null || true; \
    fi && \
    cd / && rm -rf /tmp/extract; \
    done


# Stage 2: Immagine finale con JaCoCo e MITMProxy
FROM liferay/portal:7.4.3.120-ga120

ENV API=liferay
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV LIFERAY_JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Duser.timezone=GMT -Xms2g -Xmx2g"

USER root

# Dipendenze
RUN apt-get update && \
    apt-get install -y python3 python3-pip unzip wget && \
    pip3 install mitmproxy pyyaml requests && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Directory principali
RUN mkdir -p /infrastructure /results /api/classes /api/specifications

# Copia infrastructure come negli altri Dockerfile RESTgym
COPY apis/infrastructure/ /infrastructure/

# Copy API files
COPY apis/liferay/specifications/ /api/specifications/
COPY apis/liferay/auth.yaml /api/auth.yaml
COPY apis/liferay/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy the classes extracted from the extractor stage
COPY --from=extractor --chown=liferay:liferay /extracted/classes /api/classes/

EXPOSE 9090 12345 8080

# Override both ENTRYPOINT and CMD to use our entrypoint.sh directly
ENTRYPOINT []
CMD ["/bin/bash", "/entrypoint.sh"]
