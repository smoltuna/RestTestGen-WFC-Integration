FROM k8ssandra/cass-management-api:4.0.18

# Switch to root for installation
USER root

# Environment configuration
ENV API=cassandra-management-api
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV USE_MGMT_API=true
ENV MGMT_API_LISTEN_TCP_PORT=8080
ENV DEBIAN_FRONTEND=noninteractive

# Create RESTgym directories
RUN mkdir -p /infrastructure /results /database

# Install mitmproxy for HTTP interception
RUN apt-get update && \
    apt-get -y install python3 python3-pip && \
    pip3 install mitmproxy && \
    apt-get -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy infrastructure tools (JaCoCo, mitmproxy)
COPY ./infrastructure/ /infrastructure/

# Copy database initialization script
COPY ./apis/cassandra-management-api/database/ /database/

EXPOSE 9090 12345 8080 9042

CMD mkdir -p /results/$API/$TOOL/$RUN && \
    cassandra -R > /results/$API/$TOOL/$RUN/cassandra.log 2>&1 & \
    sleep 30 && \
    until cqlsh -e "SELECT release_version FROM system.local" > /dev/null 2>&1; do sleep 5; done && \
    sh /infrastructure/jacoco/collect-coverage-interval.sh & \
    mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py & \
    java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=com.datastax.mgmtapi.*:io.k8ssandra.*,output=tcpserver,port=12345,address=* -Xms128m -Xmx128m -jar /opt/management-api/datastax-mgmtapi-server-0.1.110.jar --host tcp://0.0.0.0:8080 --host file:///tmp/oss-mgmt.sock --cassandra-socket /tmp/cassandra.sock --cassandra-home /opt/cassandra
