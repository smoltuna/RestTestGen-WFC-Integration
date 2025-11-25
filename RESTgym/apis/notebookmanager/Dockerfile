FROM ubuntu:22.04

ENV API=notebookmanager

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results

RUN apt update && \
    apt -y upgrade && \
    apt -y install openjdk-8-jdk mitmproxy && \
    apt -y autoremove

COPY apis/notebookmanager/notebookmanager.jar /api/notebookmanager.jar
COPY apis/notebookmanager/classes/ /api/classes/
COPY apis/notebookmanager/entrypoint.sh /entrypoint.sh
COPY ./infrastructure/ /infrastructure/

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
