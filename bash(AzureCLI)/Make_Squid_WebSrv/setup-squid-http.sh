#!/bin/bash

# パッケージ更新とインストール
sudo apt-get update
sudo apt-get install -y squid python3

# Squid設定変更
sudo sed -i 's/^http_port .*/http_port 8080/' /etc/squid/squid.conf
sudo sed -i 's/^#http_access allow all/http_access allow all/' /etc/squid/squid.conf

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