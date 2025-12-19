FROM sonatype/nexus3:latest AS nexus-base
FROM ubuntu:22.04

ENV API=nexus
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

ENV NEXUS_HOME=/opt/sonatype/nexus
ENV NEXUS_DATA=/nexus-data
ENV SONATYPE_WORK=/sonatype-work
ENV NEXUS_CONTEXT=/
ENV JAVA_MAX_MEM=2048m
ENV JAVA_MIN_MEM=512m

# Disable random password generation - use default admin/admin123 credentials
ENV NEXUS_SECURITY_RANDOMPASSWORD=false

RUN mkdir -p /api /infrastructure /results

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

RUN pip3 install mitmproxy


COPY ./apis/nexus/ /api/

COPY apis/nexus/collect-coverage.sh /api/collect-coverage.sh
COPY apis/nexus/collect-coverage-interval.sh /api/collect-coverage-interval.sh
RUN chmod +x /api/collect-coverage.sh /api/collect-coverage-interval.sh

COPY apis/infrastructure/ /infrastructure/


COPY --from=nexus-base /opt/sonatype/nexus /opt/sonatype/nexus
COPY --from=nexus-base /opt/sonatype/sonatype-work /opt/sonatype/sonatype-work


RUN mkdir -p /nexus-data /sonatype-work


WORKDIR /opt/sonatype/nexus


EXPOSE 8081 9090 12345


HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8081/ || exit 1

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /api/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8081/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py & \
    export INSTALL4J_ADD_VM_PARAMS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=org.sonatype.*:com.sonatype.*,output=tcpserver,port=12345,address=* -Xms${JAVA_MIN_MEM} -Xmx${JAVA_MAX_MEM}" && \
    /opt/sonatype/nexus/bin/nexus run 2>&1 | tee /results/$API/$TOOL/$RUN/nexus.log