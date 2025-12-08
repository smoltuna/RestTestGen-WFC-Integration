FROM ubuntu:22.04

ENV API=spring-kafka-publisher
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-21-jdk mitmproxy && \
    apt -y autoremove

COPY ./apis/spring-kafka-publisher/ /api/
COPY ./infrastructure/ /infrastructure/

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:9083/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.ivanfranchin.*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=9083 -Dspring.data.elasticsearch.client.reactive.endpoints=${ELASTICSEARCH_HOST:-elasticsearch}:${ELASTICSEARCH_REST_PORT:-9200} -jar /api/publisher-api.jar
