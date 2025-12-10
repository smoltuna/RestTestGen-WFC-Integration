FROM ubuntu:22.04

ENV API=keycloak
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk mitmproxy && \
    apt -y autoremove

COPY ./apis/keycloak/ /api/

# Copy OpenAPI specifications for test generation
COPY apis/keycloak/specifications/ /api/specifications/

COPY ./infrastructure/ /infrastructure/
COPY ./apis/keycloak/auth.py /api/

ENV JAVA_OPTS="-Xms256m -Xmx2048m"
ENV KC_HOME_DIR=/api
ENV KC_CONF_DIR=/api/conf

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py & \
    export JAVA_OPTS="-javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.keycloak.*,output=tcpserver,port=12345,address=* $JAVA_OPTS" && \
    /api/bin/kc.sh start-dev --http-port=8080
