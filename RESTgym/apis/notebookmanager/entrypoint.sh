#!/bin/bash

mkdir -p /results/$API/$TOOL/$RUN

# Start MySQL
service mysql start

# Wait for MySQL to be ready
until mysqladmin ping -h localhost --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done

# Create database and user
mysql -e "CREATE DATABASE IF NOT EXISTS notebook_manager;"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123';"
mysql -e "FLUSH PRIVILEGES;"

# Import schema and data if they exist
if [ -f /api/database/schema.sql ]; then
    mysql notebook_manager < /api/database/schema.sql
fi
if [ -f /api/database/data.sql ]; then
    mysql notebook_manager < /api/database/data.sql
fi

sh /infrastructure/jacoco/collect-coverage-interval.sh &

mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py &

java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -Dspring.datasource.url=jdbc:mysql://localhost:3306/notebook_manager?createDatabaseIfNotExist=true\&useSSL=false\&allowPublicKeyRetrieval=true -Dspring.datasource.username=root -Dspring.datasource.password=root123 -Dspring.jpa.hibernate.ddl-auto=update -jar /api/notebookmanager.jar
