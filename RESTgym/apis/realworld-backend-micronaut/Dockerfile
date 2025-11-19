FROM ubuntu:22.04

ENV API=realworld-backend-micronaut

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy && \
    apt -y autoremove

COPY ./apis/realworld-backend-micronaut/ /api/
COPY ./infrastructure/ /infrastructure/

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.github.al.realworld.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -jar /api/service/build/libs/realworld-backend-micronaut-0.2.5-SNAPSHOT.jar
