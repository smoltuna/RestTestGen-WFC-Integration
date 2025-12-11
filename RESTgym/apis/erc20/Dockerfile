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
    pip3 install mitmproxy requests && \
    npm install -g ganache@7.9.1

COPY apis/erc20/erc20-rest-service-0.1.0.jar /api/app.jar
COPY apis/erc20/classes/ /api/classes/
COPY apis/erc20/init-contract.py /api/init-contract.py
COPY apis/erc20/auth.py /api/auth.py

# Copy OpenAPI specifications for test generation
COPY apis/erc20/specifications/ /api/specifications/

COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080 8545

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
mkdir -p /results/$API/$TOOL/$RUN/code-coverage\n\
cp -r /api/specifications /results/$API/$TOOL/$RUN/\n\
\n\
echo "Starting Ganache..."\n\
ganache --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545 > /results/$API/$TOOL/$RUN/ganache.log 2>&1 &\n\
GANACHE_PID=$!\n\
\n\
echo "Waiting for Ganache to start..."\n\
sleep 20\n\
\n\
echo "Starting JaCoCo coverage collector..."\n\
sh /infrastructure/jacoco/collect-coverage-interval.sh &\n\
JACOCO_PID=$!\n\
\n\
echo "Starting ERC20 REST API..."\n\
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -DnodeEndpoint=http://localhost:8545 -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 -jar /api/app.jar > /results/$API/$TOOL/$RUN/logs/erc20-stdout.log 2>&1 &\n\
API_PID=$!\n\
\n\
echo "Waiting for ERC20 API to start and deploying test contract..."\n\
sleep 15\n\
python3 /api/init-contract.py\n\
CONTRACT_RESULT=$?\n\
\n\
if [ $CONTRACT_RESULT -eq 0 ]; then\n\
  echo "Test contract deployed successfully"\n\
else\n\
  echo "Warning: Test contract deployment failed, tests may have limited coverage"\n\
fi\n\
\n\
echo "Starting mitmproxy..."\n\
mkdir -p /results/$API/$TOOL/$RUN/logs\n\
mitmdump -p 9090 --set confdir=/results/$API/$TOOL/$RUN --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &\n\
MITM_PID=$!\n\
\n\
echo "All services started. Waiting for API process..."\n\
wait $API_PID\n\
' > /start.sh && chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
