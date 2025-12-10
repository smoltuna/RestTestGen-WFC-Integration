FROM ubuntu:22.04

ENV API=erc20
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk python3 python3-pip curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt -y install nodejs && \
    apt -y autoremove && \
    pip3 install mitmproxy && \
    npm install -g ganache@7.9.1

COPY apis/erc20/erc20-rest-service-0.1.0.jar /api/app.jar
COPY apis/erc20/classes/ /api/classes/

# Copy OpenAPI specifications for test generation
COPY apis/erc20/specifications/ /api/specifications/

COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080 8545

CMD mkdir -p /results/$API/$TOOL/$RUN/code-coverage && \
    cp -r /api/specifications /results/$API/$TOOL/$RUN/ && \
    ganache --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545 > /results/$API/$TOOL/$RUN/ganache.log 2>&1 & \
    sleep 20 && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --set confdir=/results/$API/$TOOL/$RUN --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    sleep 2 && \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -DnodeEndpoint=http://localhost:8545 -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 -jar /api/app.jar
