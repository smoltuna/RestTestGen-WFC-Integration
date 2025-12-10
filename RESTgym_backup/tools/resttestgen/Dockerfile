FROM ubuntu:22.04

RUN mkdir /tool && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-11-jdk

COPY ./tools/#tool-template/resttestgen.jar /tool/
COPY ./tools/#tool-template/rtg-config.yml /tool/
COPY ./tools/#tool-template/config.sh /tool/

CMD sh /tool/config.sh && \
    cd /tool && \
    while true; do java -jar resttestgen.jar; done
