FROM ubuntu:22.04

ENV API=realworld-backend-micronaut
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy python3-requests python3-yaml curl && \
    apt -y autoremove

COPY ./apis/realworld-backend-micronaut/ /api/
COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /infrastructure/mitmproxy/wfc-auth.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.github.al.realworld.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -jar /api/realworld-backend-micronaut.jar
