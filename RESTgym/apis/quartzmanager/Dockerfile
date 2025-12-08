FROM ubuntu:22.04

ENV API=quartzmanager
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /api /infrastructure /results

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        openjdk-11-jdk \
        curl \
        wget \
        netcat \
        python3 \
        python3-pip && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN pip3 install mitmproxy

COPY apis/quartzmanager/quartz-manager.war /api/quartz-manager.war

COPY apis/quartzmanager/classes/ /api/classes/

COPY apis/quartzmanager/database/ /api/database/

COPY infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=it.fabioformosa.*,output=tcpserver,port=12345,address=* \
        -Dfile.encoding=UTF-8 \
        -Dserver.port=8080 \
        -Dserver.servlet.context-path=/quartz-manager \
        -Dquartz-manager.jobClassPackages=it.fabioformosa.quartzdemo.jobs \
        -Dquartz-manager.oas.enabled=true \
        -Dquartz-manager.security.jwt.secret=mySecretKey123456789012345678901234567890 \
        -Dquartz-manager.security.accounts.in-memory.enabled=true \
        -Dquartz-manager.security.accounts.in-memory.users[0].username=admin \
        -Dquartz-manager.security.accounts.in-memory.users[0].password=admin \
        -Dquartz-manager.security.accounts.in-memory.users[0].roles[0]=ADMIN \
        -Dspring.h2.console.enabled=false \
        -jar /api/quartz-manager.war
