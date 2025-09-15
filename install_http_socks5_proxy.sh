#!/bin/bash
set -e

# ==========================
# Config chung
# ==========================
USERNAME="giaiphapmmo79"
PASSWORD="giaiphapmmo79"

# Random port từ 2000–65000
HTTP_PORT=$((RANDOM % 63000 + 2000))
SOCKS_PORT=$((RANDOM % 63000 + 2000))

# ==========================
# Cài HTTP Proxy (Squid)
# ==========================
apt update -y
apt install -y squid apache2-utils dante-server

# User/pass cho Squid
htpasswd -cb /etc/squid/passwd "$USERNAME" "$PASSWORD"

# Sao lưu config gốc
[ -f /etc/squid/squid.conf.bak ] || cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Config Squid
cat > /etc/squid/squid.conf <<EOF
http_port $HTTP_PORT
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
EOF

chmod 600 /etc/squid/passwd
chown proxy:proxy /etc/squid/passwd

systemctl restart squid
systemctl enable squid

# ==========================
# Cài SOCKS5 Proxy (Dante)
# ==========================
# Tạo user hệ thống cho Dante
id -u $USERNAME &>/dev/null || useradd -m -s /bin/false $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Config Dante
cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: 0.0.0.0 port = $SOCKS_PORT
external: eth0
method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    method: username
    log: connect disconnect
}
EOF

systemctl restart danted
systemctl enable danted

# ==========================
# Kết quả
# ==========================
IP=$(curl -s ipv4.icanhazip.com)

echo "✅ Proxy đã sẵn sàng!"
echo "➡️  HTTP Proxy:  http://$USERNAME:$PASSWORD@$IP:$HTTP_PORT"
echo "➡️  SOCKS5 Proxy: socks5://$USERNAME:$PASSWORD@$IP:$SOCKS_PORT"
