FROM ubuntu:22.04

ENV API=notebookmanager

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results

RUN apt update && \
    apt -y upgrade && \
    apt -y install openjdk-11-jdk python3 python3-pip && \
    pip3 install mitmproxy && \
    apt -y autoremove && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY apis/notebookmanager/notebookmanager.jar /api/notebookmanager.jar
COPY apis/notebookmanager/classes/ /api/classes/
COPY apis/notebookmanager/entrypoint.sh /entrypoint.sh
COPY ./infrastructure/ /infrastructure/

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
