#!/bin/sh
set -e

echo "=== Setting up VPN Gate Japan connection ==="

# Download VPN Gate CA cert
CA_URL="https://raw.githubusercontent.com/SoftEtherVPN/SoftEtherVPN/master/SRC/SoftEther_VPN_Client/SSLVPN/CACertificates/CA_Certificate.pem"
curl -sSL -o /etc/vpngate/vpngate-ca.crt "$CA_URL" 2>/dev/null || echo "" > /etc/vpngate/vpngate-ca.crt

# VPN Gate Japan residential nodes (priority: softbank > dion)
NODES="60.121.142.196:1264 126.214.255.206:1394 36.13.199.72:1498"

connected=0
for node in $NODES; do
    ip="${node%:*}"
    port="${node#*:}"
    echo "Trying OpenVPN node $ip:$port ..."

    cat > /etc/vpngate/openvpn.conf <<EOF
client
dev tun
proto tcp
remote $ip $port
ca /etc/vpngate/vpngate-ca.crt
cipher AES-128-CBC
nsCertType
remote-cert-tls server
persist-tun
persist-key
ping 20
ping-restart 60
nobind
auth-user-pass
<auth>
vpn
vpn
</auth>
verb 3
EOF

    if timeout 5 sh -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
        echo "TCP $ip:$port reachable, starting OpenVPN..."
        openvpn --config /etc/vpngate/openvpn.conf --daemon \
            --up "ip route add default dev tun0 table 100; ip rule add from 0.0.0.0/0 table 100 priority 100" \
            2>/dev/null && { echo "OpenVPN connected to $ip"; connected=1; break; }
    else
        echo "TCP $ip:$port unreachable, skipping"
    fi
done

if [ "$connected" -eq 0 ]; then
    echo "WARN: No VPN Gate node reachable, Xray will use direct exit"
fi

echo "=== VPN setup complete ==="
