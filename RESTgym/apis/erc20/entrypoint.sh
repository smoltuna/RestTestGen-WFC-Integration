#!/bin/bash
set -e
mkdir -p /results/$API/$TOOL/$RUN/code-coverage

echo "Starting Ganache..."
ganache --wallet.deterministic --wallet.totalAccounts 10 --wallet.defaultBalance 100 --chain.networkId 1337 --server.host 0.0.0.0 --server.port 8545 > /results/$API/$TOOL/$RUN/ganache.log 2>&1 &
GANACHE_PID=$!

echo "Waiting for Ganache to start..."
sleep 20

echo "Starting JaCoCo coverage collector..."
sh /infrastructure/jacoco/collect-coverage-interval.sh &
JACOCO_PID=$!

echo "Starting ERC20 REST API..."
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -DnodeEndpoint=http://localhost:8545 -DfromAddress=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1 -jar /api/app.jar > /results/$API/$TOOL/$RUN/logs/erc20-stdout.log 2>&1 &
API_PID=$!

echo "Waiting for ERC20 API to start and deploying test contract..."
sleep 15
python3 /api/init-contract.py
CONTRACT_RESULT=$?

if [ $CONTRACT_RESULT -eq 0 ]; then
  echo "Test contract deployed successfully"
else
  echo "Warning: Test contract deployment failed, tests may have limited coverage"
fi

echo "Starting mitmproxy..."
mkdir -p /results/$API/$TOOL/$RUN/logs
mitmdump -p 9090 --set confdir=/results/$API/$TOOL/$RUN --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py -s /api/auth.py > /results/$API/$TOOL/$RUN/logs/mitmproxy.log 2>&1 &
MITM_PID=$!

echo "All services started. Waiting for API process..."
wait $API_PID
