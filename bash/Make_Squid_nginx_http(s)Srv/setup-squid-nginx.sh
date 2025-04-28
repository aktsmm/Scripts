#!/bin/bash
set -e

# 古い設定ファイルを削除
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/debug.conf

#!/bin/bash
set -e

# 1. リポジトリを明示的に追加（念のため）
add-apt-repository universe -y

# 2. パッケージキャッシュ更新 （強制）
apt-get clean
apt-get update -y
apt-get upgrade -y

apt install -y squid nginx openssl

# 2. Squid 設定: 全通過（ポート8080）
cat <<EOF > /etc/squid/squid.conf
http_port 8080
acl all src all
http_access allow all
EOF

# 3. nginx: 自己署名証明書作成
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/selfsigned.key \
    -out /etc/nginx/ssl/selfsigned.crt \
    -subj "/C=JP/ST=Tokyo/L=Chiyoda/O=ExampleCompany/CN=localhost"

# 4.時刻とシリアル番号生成
TIME=$(date '+%Y-%m-%d %H:%M:%S')
SN=$(echo -n "$TIME" | md5sum | cut -c1-8)

# 虹の色 (黄色を除く)
RAINBOW_COLORS=("red" "orange" "green" "blue" "indigo" "violet")
TARGET_STRING="NGINX Debug Portal"

# 文字列を一文字ずつランダムな虹の色で装飾する関数
colorize_string() {
    local str="$1"
    local colored_str=""
    local len=${#str}
    for ((i=0; i<len; i++)); do
        local char="${str:$i:1}"
        local color="${RAINBOW_COLORS[$((RANDOM % ${#RAINBOW_COLORS[@]}))]}"
        colored_str+="<span style=\"color: ${color};\">${char}</span>"
    done
    echo "$colored_str"
}

# 色付けされた NGINX 文字列を生成
COLORED_NGINX=$(colorize_string "$TARGET_STRING")

# 5. nginx: HTTP/HTTPS 構成（リダイレクトなし）+ access_log + charset + add_header
cat <<EOF > /etc/nginx/sites-enabled/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    charset utf-8;
    default_type text/html;
    access_log /var/log/nginx/access.log with_headers;

     location = / {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 '<!DOCTYPE html>\n<html lang="ja">\n<head>\n  <meta charset="UTF-8">\n  <title>NGINX Debug Top</title>\n</head>\n<body>\n<h1>Welcome to ${COLORED_NGINX} on \$server_addr (via HTTPS, SN:$SN)</h1>\n<h2>Hostname: \$hostname</h2>\n<hr>\n<h3>📘 エンドポイント一覧:</h3>\n<ul>\n  <li><a href="/">/</a> - Acceptヘッダに応じてHTMLまたはJSON応答(   #   - application/json を含む 場合 JSON 応答)</li>\n  <li><a href="/h">/h</a> - HTTPヘッダ情報一覧</li>\n  <li><a href="/s">/s</a> - ServerAddrとHostname</li>\n  <li><a href="/ua">/ua</a> - User-Agentのみ表示</li>\n  <li><a href="/r">/r</a> - Refererヘッダー表示</li>\n  <li><a href="/ip">/ip</a> - RemoteAddrとClientIP表示</li>\n  <li><a href="/all">/all</a> - 全情報をまとめて表示</li>\n</ul>\n<hr>\n<h3>📑 ヘッダー情報の説明:</h3>\n<ul>\n  <li><b>X-Forwarded-For</b>: プロキシを通過してきた元のIPアドレス</li>\n  <li><b>X-Real-IP</b>: 実際のクライアントIPアドレス</li>\n  <li><b>Host</b>: リクエスト先のホスト名</li>\n  <li><b>RemoteAddr</b>: TCP接続元のIPアドレス</li>\n  <li><b>User-Agent</b>: クライアントのソフトウェア情報</li>\n  <li><b>Referer</b>: リンク元のURL</li>\n</ul>\n</body>\n</html>';
    }

    location = /h {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 "<pre>X-Forwarded-For: \$http_x_forwarded_for\nX-Real-IP: \$http_x_real_ip\nHost: \$host\nRemoteAddr: \$remote_addr\nUser-Agent: \$http_user_agent\nReferer: \$http_referer</pre>";
    }

    location = /s {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "ServerAddr: \$server_addr\nHostname: \$hostname";
    }

    location = /ua {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "User-Agent: \$http_user_agent";
    }

    location = /r {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "Referer: \$http_referer";
    }

    location = /ip {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "RemoteAddr: \$remote_addr\nClientIP: \$http_x_real_ip";
    }

    location = /all {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 "<pre>ServerAddr: \$server_addr\nHostname: \$hostname\nRemoteAddr: \$remote_addr\nClientIP: \$http_x_real_ip\nX-Forwarded-For: \$http_x_forwarded_for\nX-Real-IP: \$http_x_real_ip\nHost: \$host\nUser-Agent: \$http_user_agent\nReferer: \$http_referer</pre>";
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    charset utf-8;
    default_type text/html;

    location = / {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 '<!DOCTYPE html>\n<html lang="ja">\n<head>\n  <meta charset="UTF-8">\n  <title>NGINX Debug Top</title>\n</head>\n<body>\n<h1>Welcome to ${COLORED_NGINX} on \$server_addr (via HTTPS, SN:$SN)</h1>\n<h2>Hostname: \$hostname</h2>\n<hr>\n<h3>📘 エンドポイント一覧:</h3>\n<ul>\n  <li><a href="/">/</a> - Acceptヘッダに応じてHTMLまたはJSON応答(   #   - application/json を含む 場合 JSON 応答)</li>\n  <li><a href="/h">/h</a> - HTTPヘッダ情報一覧</li>\n  <li><a href="/s">/s</a> - ServerAddrとHostname</li>\n  <li><a href="/ua">/ua</a> - User-Agentのみ表示</li>\n  <li><a href="/r">/r</a> - Refererヘッダー表示</li>\n  <li><a href="/ip">/ip</a> - RemoteAddrとClientIP表示</li>\n  <li><a href="/all">/all</a> - 全情報をまとめて表示</li>\n</ul>\n<hr>\n<h3>📑 ヘッダー情報の説明:</h3>\n<ul>\n  <li><b>X-Forwarded-For</b>: プロキシを通過してきた元のIPアドレス</li>\n  <li><b>X-Real-IP</b>: 実際のクライアントIPアドレス</li>\n  <li><b>Host</b>: リクエスト先のホスト名</li>\n  <li><b>RemoteAddr</b>: TCP接続元のIPアドレス</li>\n  <li><b>User-Agent</b>: クライアントのソフトウェア情報</li>\n  <li><b>Referer</b>: リンク元のURL</li>\n</ul>\n</body>\n</html>';
    }

    location = /h {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 "<pre>X-Forwarded-For: \$http_x_forwarded_for\nX-Real-IP: \$http_x_real_ip\nHost: \$host\nRemoteAddr: \$remote_addr\nUser-Agent: \$http_user_agent\nReferer: \$http_referer</pre>";
    }

    location = /s {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "ServerAddr: \$server_addr\nHostname: \$hostname";
    }

    location = /ua {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "User-Agent: \$http_user_agent";
    }

    location = /r {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "Referer: \$http_referer";
    }

    location = /ip {
        add_header Content-Type "text/plain; charset=UTF-8";
        return 200 "RemoteAddr: \$remote_addr\nClientIP: \$http_x_real_ip";
    }

    location = /all {
        add_header Content-Type "text/html; charset=UTF-8";
        return 200 "<pre>ServerAddr: \$server_addr\nHostname: \$hostname\nRemoteAddr: \$remote_addr\nClientIP: \$http_x_real_ip\nX-Forwarded-For: \$http_x_forwarded_for\nX-Real-IP: \$http_x_real_ip\nHost: \$host\nUser-Agent: \$http_user_agent\nReferer: \$http_referer</pre>";
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# 6. nginx ログフォーマットを正しく追加（重複防止）
if ! grep -q "log_format with_headers" /etc/nginx/nginx.conf; then
    sed -i '/http {/a\
    log_format with_headers '\''\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent "\$http_referer" "\$http_user_agent" XFF="\$http_x_forwarded_for" XRI="\$http_x_real_ip" HOST="\$http_host" port=\$server_port'\'';\
    access_log /var/log/nginx/access.log with_headers;' /etc/nginx/nginx.conf
else
    echo "⚠ log_format with_headers は既に定義されています。スキップします。"
fi

# 7. ログローテーションの設定
cat <<EOF > /etc/logrotate.d/nginx-debug
/var/log/nginx/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \$(cat /var/run/nginx.pid)
    endscript
}
EOF

cat <<EOF > /etc/logrotate.d/squid-debug
/var/log/squid/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 proxy proxy
    sharedscripts
    postrotate
        [ -f /var/run/squid.pid ] && kill -USR1 \$(cat /var/run/squid.pid)
    endscript
}
EOF

# 8. 表示用HTMLディレクトリの作成
mkdir -p /var/www/html-http /var/www/html-https

# 9. nginx 自動起動＆反映
systemctl enable nginx
nginx -t && systemctl restart nginx

# 10. Squid 自動起動＆反映
systemctl enable squid
systemctl restart squid

# 11. IP表示
IP=$(hostname -I | awk '{print $1}')
echo "✅ All services installed and configured successfully."
echo "👉 Squid:       http://$IP:8080"
echo "👉 NGINX HTTP:    http://$IP"
echo "👉 NGINX HTTPS:   https://$IP (self-signed)"
echo "👉 NGINX access log: /var/log/nginx/access.log"
echo "👉 Squid access log: /var/log/squid/access.log"