#!/bin/bash
set -e

# 1. パッケージ更新とインストール
apt update -y
apt install -y squid nginx openssl

# 2. Squid 設定: 全通過（ポート8080）
cat <<EOF > /etc/squid/squid.conf
http_port 8080
acl all src all
http_access allow all
EOF

# 3. Squid 自動起動＆起動
systemctl enable squid
systemctl restart squid

# 4. nginx: 自己署名証明書作成
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=JP/ST=Tokyo/L=Chiyoda/O=ExampleCompany/CN=localhost"

# 5. nginx: HTTP/HTTPS 構成（リダイレクトなし）
cat <<'EOF' > /etc/nginx/sites-enabled/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html-http;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    root /var/www/html-https;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 6. nginx ログフォーマットにポート番号追加
sed -i '/http {/a \
    log_format with_port '\''$remote_addr - $remote_user [$time_local] '\''\
                     '\''"$request" $status $body_bytes_sent '\''\
                     '\''port=$server_port '\''\
                     '\''"$http_referer" "$http_user_agent"'\'';\
    access_log /var/log/nginx/access.log with_port;' /etc/nginx/nginx.conf

# 7. 表示用HTML作成
mkdir -p /var/www/html-http
mkdir -p /var/www/html-https
echo '<h1>Welcome to NGINX over HTTP!</h1>' > /var/www/html-http/index.html
echo '<h1>Welcome to NGINX over HTTPS!</h1>' > /var/www/html-https/index.html

# 8. nginx 自動起動＆反映
systemctl enable nginx
nginx -t && systemctl restart nginx

echo "✅ All services installed and configured successfully."
echo "👉 Squid:        http://<vmip>:8080"
echo "👉 NGINX HTTP:   http://<vmip>"
echo "👉 NGINX HTTPS:  https://<vm> (self-signed)"
