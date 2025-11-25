FROM ubuntu:22.04

ENV API=gestaohospitalar

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results

RUN apt update && \
    apt -y upgrade && \
    apt -y install openjdk-8-jdk mitmproxy && \
    apt -y autoremove

COPY apis/gestaohospitalar/gestaohospitalar-0.0.1.jar /api/gestaohospitalar.jar
COPY apis/gestaohospitalar/classes/ /api/classes/
COPY ./infrastructure/ /infrastructure/

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -Dspring.data.mongodb.host=mongodb \
        -Dspring.data.mongodb.port=27017 \
        -Dspring.data.mongodb.database=HospitalDB \
        -jar /api/gestaohospitalar.jar
