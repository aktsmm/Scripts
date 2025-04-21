#!/bin/bash

# パッケージ更新とインストール
sudo apt-get update
sudo apt-get install -y squid python3

# 既存のsquid.confをすべてコメントアウトし、末尾に必要な設定だけ追加
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.bak.$(date +%s)
sudo sed -i 's/^/# Commented by setup script: /' /etc/squid/squid.conf

# Squidの新しい設定を追記（完全許可）
sudo tee -a /etc/squid/squid.conf > /dev/null <<EOF

# === Added by setup script ===
http_port 8080

acl all src all
acl Safe_ports port 80 443 21 70 210 280 488 591 777 1025-65535
acl CONNECT method CONNECT

http_access allow all
# =============================
EOF

# Squid再起動と自動起動化
sudo systemctl restart squid
sudo systemctl enable squid

# index.html を作成
USER_HOME="/home/$(logname)"
HOSTNAME=$(hostname)
echo "This is $HOSTNAME Web Server" | sudo tee "$USER_HOME/index.html"

# HTTPサーバ用 systemd サービス作成
sudo tee /etc/systemd/system/simple-http.service > /dev/null <<EOF
[Unit]
Description=Simple Python HTTP Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 80
WorkingDirectory=$USER_HOME
StandardOutput=append:/var/log/python_http.log
StandardError=append:/var/log/python_http.log
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# systemd 反映とサービス起動
sudo systemctl daemon-reload
sudo systemctl enable simple-http
sudo systemctl start simple-http
