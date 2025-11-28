#!/bin/sh
# RESTgym startup script for Traccar

# Create results directory
mkdir -p /results/${API}/${TOOL}/${RUN}

# Start JaCoCo coverage collector in background
sh /infrastructure/jacoco/collect-coverage-interval.sh &

# Start mitmproxy in background
mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py &

# Start Traccar with JaCoCo agent
java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=org.traccar.*,output=tcpserver,port=12345,address=* \
    -Xms512m -Xmx512m \
    -Dfile.encoding=UTF-8 \
    -Djava.net.preferIPv4Stack=true \
    -jar /api/traccar.jar /api/conf/traccar.xml 2>&1 | tee /results/${API}/${TOOL}/${RUN}/traccar.log
