FROM ubuntu:22.04

ENV API=erc20

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk nodejs npm python3 python3-pip && \
    apt -y autoremove && \
    pip3 install mitmproxy && \
    npm install -g ganache@7.9.1

COPY erc20-rest-service-0.1.0.jar /api/app.jar
COPY ./infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080 8545

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    ganache --wallet.deterministic --wallet.accounts 10 --wallet.defaultBalance 100 --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545 > /results/$API/$TOOL/$RUN/ganache.log 2>&1 & \
    sleep 5 && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    sleep 2 && \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -DnodeEndpoint=http://localhost:8545 -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 -jar /api/app.jar
