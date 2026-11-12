FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y openvpn iptables curl ca-certificates unzip && rm -rf /var/lib/apt/lists/*

RUN curl -sSL -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/xray-linux-64.zip && unzip -o /tmp/xray.zip -d /usr/local/bin/ && rm /tmp/xray.zip && chmod +x /usr/local/bin/xray

RUN mkdir -p /etc/vpngate /etc/xray /app

COPY vpn-setup.sh /app/vpn-setup.sh
COPY xray-config.json /etc/xray/config.json

EXPOSE 10086

CMD ["sh", "-c", "/app/vpn-setup.sh && xray run -c /etc/xray/config.json"]
