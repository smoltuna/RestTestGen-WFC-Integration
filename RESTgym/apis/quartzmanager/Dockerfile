FROM maven:3.8-openjdk-11-slim AS builder
WORKDIR /app

COPY quartz-manager/quartz-manager-parent quartz-manager-parent/

WORKDIR /app/quartz-manager-parent
RUN mvn clean install -DskipTests -Dmaven.javadoc.skip=true

FROM ubuntu:22.04

ENV API=quartzmanager
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /api /infrastructure /results

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install openjdk-11-jre python3 python3-pip curl netcat sqlite3 && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install mitmproxy

COPY --from=builder /app/quartz-manager-parent/quartz-manager-web-showcase/target/*.war /api/app.war

COPY ./infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -jar /api/app.war
