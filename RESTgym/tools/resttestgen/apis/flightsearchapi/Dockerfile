# FlightSearchAPI Docker image for standalone testing
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Java 21 and MongoDB
RUN apt-get update && \
    apt-get -y install \
        openjdk-21-jdk \
        curl \
        gnupg \
        ca-certificates && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && \
    apt-get -y install mongodb-org && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy JAR from RESTgym folder
COPY flightsearchapi.jar /app/flightsearchapi.jar

EXPOSE 8080 27017

# Entrypoint: start MongoDB and API
RUN echo '#!/bin/bash\n\
set -e\n\
mkdir -p /data/db\n\
\n\
echo "Starting MongoDB..."\n\
mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db\n\
sleep 5\n\
\n\
echo "Starting FlightSearchAPI..."\n\
exec java -Xmx4g \\\n\
    -Dserver.port=8080 \\\n\
    -Dspring.data.mongodb.host=localhost \\\n\
    -Dspring.data.mongodb.port=27017 \\\n\
    -Dspring.data.mongodb.database=flightdatabase \\\n\
    -jar /app/flightsearchapi.jar\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
