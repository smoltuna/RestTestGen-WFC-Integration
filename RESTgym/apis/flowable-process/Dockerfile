FROM ubuntu:22.04

ENV API=flowable-process
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    mkdir /api/classes && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy wget unzip && \
    apt -y autoremove

RUN cd /api && \
    wget -q "https://github.com/flowable/flowable-engine/releases/download/flowable-7.0.1/flowable-7.0.1.zip" -O flowable.zip && \
    unzip -q flowable.zip && \
    mv flowable-7.0.1/wars/flowable-rest.war /api/flowable-rest.war && \
    rm -rf flowable.zip flowable-7.0.1

RUN cd /api && \
    mkdir -p /tmp/war-extract && \
    cd /tmp/war-extract && \
    jar xf /api/flowable-rest.war && \
    find WEB-INF/classes/org/flowable -name "*.class" -exec cp --parents {} /api/classes/ \; 2>/dev/null || true && \
    cd /api && \
    rm -rf /tmp/war-extract

COPY ./apis/flowable-process/application.properties /api/application.properties
COPY ./apis/flowable-process/specifications /api/specifications
COPY ./apis/flowable-process/database /api/database
COPY ./infrastructure/ /infrastructure/

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080 -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.flowable.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dspring.config.location=file:/api/application.properties -jar /api/flowable-rest.war
