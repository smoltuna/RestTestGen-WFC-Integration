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
    pip3 install mitmproxy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Directory principali
RUN mkdir -p /infrastructure /results /api/classes /api/specifications

# Copia infrastructure come negli altri Dockerfile RESTgym
COPY apis/infrastructure/ /infrastructure/

# Copia le specifiche OpenAPI
COPY apis/liferay/specifications/ /api/specifications/

# Copia le classi estratte
COPY --from=extractor --chown=liferay:liferay /extracted/classes /api/classes/

# Script JaCoCo
RUN mkdir -p /opt/liferay/tomcat/bin && \
    echo '#!/bin/bash' > /opt/liferay/tomcat/bin/setenv-jacoco.sh && \
    echo 'export CATALINA_OPTS="$CATALINA_OPTS -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.liferay.*,output=tcpserver,port=12345,address=*"' >> /opt/liferay/tomcat/bin/setenv-jacoco.sh && \
    chmod +x /opt/liferay/tomcat/bin/setenv-jacoco.sh && \
    chown liferay:liferay /opt/liferay/tomcat/bin/setenv-jacoco.sh

# Script di avvio personalizzato
RUN echo '#!/bin/bash' > /startup.sh && \
    echo 'source /opt/liferay/tomcat/bin/setenv-jacoco.sh 2>/dev/null || true' >> /startup.sh && \
    echo 'mkdir -p /results/$API/$TOOL/$RUN/code-coverage' >> /startup.sh && \
    echo 'cp -r /api/specifications /results/$API/$TOOL/$RUN/' >> /startup.sh && \
    echo 'sh /infrastructure/jacoco/collect-coverage-interval.sh &' >> /startup.sh && \
    echo 'mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py &' >> /startup.sh && \
    echo 'exec /opt/liferay/tomcat/bin/catalina.sh run' >> /startup.sh && \
    chmod +x /startup.sh && \
    chown liferay:liferay /startup.sh

EXPOSE 9090 12345

USER liferay
CMD ["/bin/bash", "/startup.sh"]
