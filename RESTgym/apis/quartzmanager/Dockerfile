FROM ubuntu:22.04

ENV API=quartzmanager
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install openjdk-11-jdk curl netcat python3 python3-pip && \
    apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install mitmproxy pyyaml requests

COPY apis/quartzmanager/ /api/
COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080

COPY apis/quartzmanager/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
