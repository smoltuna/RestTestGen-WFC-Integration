#!/bin/bash

mkdir -p /results/$API/$TOOL/$RUN

# Start MySQL
service mysql start

# Wait for MySQL to be ready
until mysqladmin ping -h localhost --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done

# Set root password first (MySQL 8.0 requires authentication)
mysql --user=root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123';
    FLUSH PRIVILEGES;
EOSQL

# Drop and recreate the database to ensure clean state
mysql --user=root --password=root123 <<-EOSQL
    DROP DATABASE IF EXISTS notebook_manager;
    CREATE DATABASE notebook_manager;
EOSQL

# Import schema and data if they exist
if [ -f /api/database/schema.sql ]; then
    mysql --user=root --password=root123 notebook_manager < /api/database/schema.sql
fi
if [ -f /api/database/data.sql ]; then
    mysql --user=root --password=root123 notebook_manager < /api/database/data.sql
fi

sh /infrastructure/jacoco/collect-coverage-interval.sh &

mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py &

java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -Dspring.datasource.url=jdbc:mysql://localhost:3306/notebook_manager?createDatabaseIfNotExist=true\&useSSL=false\&allowPublicKeyRetrieval=true -Dspring.datasource.username=root -Dspring.datasource.password=root123 -Dspring.jpa.hibernate.ddl-auto=none -jar /api/notebookmanager.jar
