# RESTgym Dockerfile for BezKoder Swagger 3 Example API
FROM ubuntu:22.04

# Environment variable with API slug
ENV API=bezkoder
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /api /infrastructure /results

# Install required packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-17-jdk \
        curl \
        wget \
        netcat \
        python3 \
        python3-pip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mitmproxy via pip
RUN pip3 install mitmproxy

# Copy the Spring Boot JAR file
COPY apis/bezkoder/spring-boot-swagger-3-example-0.0.1-SNAPSHOT.jar /api/bezkoder.jar

# Copy extracted class files for JaCoCo coverage analysis
COPY apis/bezkoder/classes/ /api/classes/

# Copy infrastructure from common RESTgym infrastructure
COPY infrastructure/ /infrastructure/

# Expose RESTgym standard ports
# 9090: mitmproxy (external access)
# 12345: JaCoCo coverage collection
# 8080: API internal port
EXPOSE 9090 12345 8080

# Container execution command
# 1. Create results directory structure
# 2. Start JaCoCo coverage collection in background
# 3. Start mitmproxy as reverse proxy in background
# 4. Start the Spring Boot API with JaCoCo agent
CMD mkdir -p /results/$API/$TOOL/$RUN && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -jar /api/bezkoder.jar
