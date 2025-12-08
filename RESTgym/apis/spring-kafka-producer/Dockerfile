FROM ubuntu:22.04

ENV API=spring-kafka-producer
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-21-jdk mitmproxy && \
    apt -y autoremove

COPY ./apis/spring-kafka-producer/ /api/
COPY ./infrastructure/ /infrastructure/

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:9080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.ivanfranchin.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=9080 -Dspring.kafka.bootstrap-servers=${KAFKA_HOST:-kafka}:${KAFKA_PORT:-9092} -Dspring.cloud.schema-registry.client.endpoint=http://${SCHEMA_REGISTRY_HOST:-schema-registry}:${SCHEMA_REGISTRY_PORT:-8081} -jar /api/producer-api.jar
