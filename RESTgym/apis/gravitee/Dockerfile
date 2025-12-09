FROM ubuntu:22.04

ENV API=gravitee
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /api /infrastructure /results

# Install required packages including mitmproxy
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-21-jdk \
        curl \
        wget \
        netcat \
        sqlite3 \
        python3 \
        python3-pip && \
    pip3 install mitmproxy && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Gravitee Management API
RUN wget -q https://download.gravitee.io/graviteeio-apim/distributions/graviteeio-full-4.9.7.zip -O /tmp/gravitee.zip && \
    apt-get update && \
    apt-get -y install unzip && \
    unzip -q /tmp/gravitee.zip -d /opt && \
    mv /opt/graviteeio-full-* /opt/graviteeio && \
    rm /tmp/gravitee.zip && \
    apt-get -y remove unzip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


COPY apis/gravitee/classes/ /api/classes/


COPY apis/gravitee/database/ /api/database/

COPY infrastructure/ /infrastructure/

# Upgrade JaCoCo to 0.8.12 for Java 21 support (Gravitee requires Java 21)
RUN wget -q https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.12/org.jacoco.agent-0.8.12-runtime.jar -O /infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar && \
    wget -q https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.12/org.jacoco.cli-0.8.12-nodeps.jar -O /infrastructure/jacoco/org.jacoco.cli-0.8.12-nodeps.jar

# Expose RESTgym standard ports
# 9090: mitmproxy (reverse proxy to Gravitee)
# 12345: JaCoCo TCP server
# 8083: Gravitee Management API internal port
EXPOSE 9090 12345 8083

# Set MongoDB connection for Gravitee
ENV gravitee_management_type=mongodb
ENV gravitee_management_mongodb_uri=mongodb://mongodb:27017/gravitee?serverSelectionTimeoutMS=5000&connectTimeoutMS=5000&socketTimeoutMS=5000
ENV gravitee_ratelimit_type=mongodb
ENV gravitee_ratelimit_mongodb_uri=mongodb://mongodb:27017/gravitee?serverSelectionTimeoutMS=5000&connectTimeoutMS=5000&socketTimeoutMS=5000

# Configure Gravitee to listen on port 8083
ENV gravitee_http_port=8083

# Start Gravitee with JaCoCo, mitmproxy, and coverage collection
CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8083/ -s /infrastructure/mitmproxy/store-interactions.py & \
    cd /opt/graviteeio/graviteeio-apim-rest-api-4.9.7 && \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.12-runtime.jar=includes=io.gravitee.*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Djava.io.tmpdir=/tmp \
        -Dgravitee.home=/opt/graviteeio/graviteeio-apim-rest-api-4.9.7 \
        -Dgravitee.management.type=mongodb \
        -Dgravitee.management.mongodb.uri=$gravitee_management_mongodb_uri \
        -Dgravitee.ratelimit.type=mongodb \
        -Dgravitee.ratelimit.mongodb.uri=$gravitee_ratelimit_mongodb_uri \
        -jar lib/gravitee-apim-rest-api-standalone-bootstrap-4.9.7.jar
