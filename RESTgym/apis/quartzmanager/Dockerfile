FROM ubuntu:22.04

ENV API=quartzmanager
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install openjdk-11-jdk curl netcat python3 python3-pip && \
    apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install mitmproxy requests

COPY apis/quartzmanager/ /api/
COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

CMD cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    echo "Starting Quartz Manager..." && \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=it.fabioformosa.*,output=tcpserver,port=12345,address=* \
        -Dspring.config.location=file:/api/application.properties \
        -jar /api/quartz-manager.jar > /results/$API/$TOOL/$RUN/logs/quartz-manager.log 2>&1 & \
    APP_PID=$! && \
    echo "Waiting for Quartz Maager to start..." && \
    for i in $(seq 1 60); do \
        if curl -s http://localhost:8080/quartz-manager/api/schedulers > /dev/null 2>&1; then \
            echo "Quartz-Manager is ready!"; \
            break; \
        fi; \
        if [ $i -eq 60 ]; then \
            echo "Timeout waiting for Quartz Manager"; \
            exit 1; \
        fi; \
        sleep 1; \
    done && \
    echo "Starting JaCoCo coverage collection..." && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    echo "Starting mitmproxy..." && \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ \
        -s /infrastructure/mitmproxy/store-interactions.py \
        -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 & \
    echo "Waiting for mitmproxy..." && sleep 10 && \
    echo "All services started. Waiting for Quartz Manager process..." && \
    wait $APP_PID
