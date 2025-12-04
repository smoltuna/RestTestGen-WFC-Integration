# Nexus Repository Manager - RESTgym Dockerfile  
# Using official Nexus image as base but adding RESTgym infrastructure
FROM sonatype/nexus3:latest AS nexus-base

FROM ubuntu:22.04

# Environment variables
ENV API=nexus
ENV DEBIAN_FRONTEND=noninteractive
ENV NEXUS_HOME=/opt/sonatype/nexus
ENV NEXUS_DATA=/nexus-data
ENV SONATYPE_WORK=/sonatype-work
ENV NEXUS_CONTEXT=/
ENV JAVA_MAX_MEM=2048m
ENV JAVA_MIN_MEM=512m

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Install required packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-21-jdk \
        curl \
        python3 \
        python3-pip \
        unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy
RUN pip3 install mitmproxy

# Copy RESTgym infrastructure
COPY ./infrastructure/ /infrastructure/

# Copy Nexus from official image
COPY --from=nexus-base /opt/sonatype/nexus /opt/sonatype/nexus
COPY --from=nexus-base /opt/sonatype/sonatype-work /opt/sonatype/sonatype-work

# Create directories
RUN mkdir -p /nexus-data /sonatype-work /api/classes

# Extract classes for JaCoCo from the main Nexus JAR
RUN cd /api/classes && \
    unzip -q /opt/sonatype/nexus/bin/sonatype-nexus-repository-*.jar 'BOOT-INF/classes/org/sonatype/**/*.class' 'BOOT-INF/classes/com/sonatype/**/*.class' 2>/dev/null || true && \
    if [ -d BOOT-INF/classes ]; then mv BOOT-INF/classes/* . && rm -rf BOOT-INF; fi

# Set working directory
WORKDIR /opt/sonatype/nexus

# Expose ports
EXPOSE 8081 9090 12345

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8081/ || exit 1

# Container execution command (RESTgym template pattern)
CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8081/ -s /infrastructure/mitmproxy/store-interactions.py & \
    export INSTALL4J_ADD_VM_PARAMS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=org.sonatype.*:com.sonatype.*,output=tcpserver,port=12345,address=* -Xms${JAVA_MIN_MEM} -Xmx${JAVA_MAX_MEM}" && \
    /opt/sonatype/nexus/bin/nexus run 2>&1 | tee /results/$API/$TOOL/$RUN/nexus.log
