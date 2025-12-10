#!/bin/bash

mkdir -p /results/$API/$TOOL/$RUN

sh /infrastructure/jacoco/collect-coverage-interval.sh &

mitmdump -p 9090 --mode reverse:http://localhost:8080/ -s /infrastructure/mitmproxy/store-interactions.py &

java -javaagent:/infrastructure/jacoco/org.jacoco.agent-0.8.7-runtime.jar=includes=*,output=tcpserver,port=12345,address=* -Dfile.encoding=UTF-8 -Dserver.port=8080 -Dspring.datasource.url=jdbc:mysql://mysql:3306/notebook_manager?createDatabaseIfNotExist=true\&useSSL=false\&allowPublicKeyRetrieval=true -Dspring.datasource.username=root -Dspring.datasource.password=root123 -Dspring.jpa.hibernate.ddl-auto=update -jar /api/notebookmanager.jar
