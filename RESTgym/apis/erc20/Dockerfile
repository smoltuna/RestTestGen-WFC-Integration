FROM ubuntu:22.04

ENV API=erc20
ENV TOOL=${TOOL:-manual}
ENV RUN=${RUN:-1}

RUN mkdir /api && \
    mkdir /infrastructure && \
    mkdir /results && \
    apt update && \
    apt -y upgrade && \
    apt -y install openjdk-17-jdk python3 python3-pip curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt -y install nodejs && \
    apt -y autoremove && \
    pip3 install mitmproxy requests && \
    npm install -g ganache@7.9.1

# Copy all API files
COPY ./apis/erc20/ /api/
COPY apis/infrastructure/ /infrastructure/

EXPOSE 9090 12345 8080 8545

COPY apis/erc20/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
