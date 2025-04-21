
# 🛠 NGINX + Squid ローカル検証環境セットアップスクリプト

このスクリプトは、以下の環境を自動で構成するデバッグ用ツールです：

- NGINX（HTTP/HTTPS）＋Squid（プロキシ）
- 自己署名証明書によるSSLオフロード環境
- 各種ヘッダー情報を確認するためのL7エンドポイントを提供
- アクセスログの詳細出力（XFFやUser-Agentなど）
- ログローテーション設定付き

---

## 🧩 利用シナリオ

このスクリプトで構成される環境は、次のような用途に適しています：

- **SSLオフロードの検証**（自己署名証明書付き）
- **X-Forwarded-For, X-Real-IP などのヘッダー動作検証**
- **Squidプロキシ経由でのL7確認**
- **PowerShellやcurlを使ったテスト通信のレスポンス比較**
- **NATやReverse Proxy動作検証前の簡易環境構築**

---

## 📡 提供されるエンドポイント一覧

| パス      | 概要                                           | 応答形式        |
|-----------|------------------------------------------------|-----------------|
| `/`       | Acceptヘッダに応じてHTMLまたはJSONで応答       | HTML or JSON    |
| `/h`      | ヘッダー情報一覧（XFF, UA, Refererなど）       | HTML (preタグ)  |
| `/s`      | ServerAddrとホスト名                           | text/plain      |
| `/ua`     | User-Agent のみ表示                            | text/plain      |
| `/r`      | Referer のみ表示                               | text/plain      |
| `/ip`     | RemoteAddrとX-Real-IPを表示                     | text/plain      |
| `/all`    | 上記すべての情報をまとめて表示                 | HTML (preタグ)  |

---

## 🔍 各種ヘッダーの意味

| ヘッダー名         | 意味                                                                 |
|--------------------|----------------------------------------------------------------------|
| `X-Forwarded-For`  | プロキシを通過してきた元のクライアントIP（複数の場合カンマ区切り） |
| `X-Real-IP`        | 実際のクライアントのIPアドレス                                      |
| `Host`             | リクエスト先のホスト名                                               |
| `RemoteAddr`       | TCP接続元のIPアドレス（サーバ視点）                                  |
| `User-Agent`       | ブラウザやツールのクライアント情報                                  |
| `Referer`          | 遷移元のURL                                                          |

---

## 🧪 PowerShell / curl によるテスト例

### PowerShell（Windows）

```powershell
# IPを変えてください
$ip = "https://YOUR_NGINX_IP"

# JSONで受け取りたい場合
Invoke-WebRequest -Uri "$ip/" -Headers @{Accept="application/json"} | Select-Object -ExpandProperty Content

# ヘッダー一覧確認（/h）
Invoke-WebRequest -Uri "$ip/h" | Select-Object -ExpandProperty Content

# XFFを送って検証する例
Invoke-WebRequest -Uri "$ip/ip" -Headers @{"X-Forwarded-For"="1.2.3.4"} | Select-Object -ExpandProperty Content
```

### curl（Linux/WSLなど）

```bash
curl -H "Accept: application/json" https://YOUR_NGINX_IP/
curl https://YOUR_NGINX_IP/h
curl -H "X-Forwarded-For: 8.8.8.8" https://YOUR_NGINX_IP/ip
```

---

## 🔧 その他構成

- アクセスログ: `/var/log/nginx/access.log`（`log_format with_headers` で詳細記録）
- Squid ログ: `/var/log/squid/access.log`
- 自動起動設定済み: `nginx`, `squid`
- 自己署名証明書: `/etc/nginx/ssl/selfsigned.crt`, `.key`

---

## ✅ 構成後の確認メッセージ例

```
✅ All services installed and configured successfully.
👉 Squid:       http://<IP>:8080
👉 NGINX HTTP:    http://<IP>
👉 NGINX HTTPS:   https://<IP> (self-signed)
👉 NGINX access log: /var/log/nginx/access.log
👉 Squid access log: /var/log/squid/access.log
```


## 🔍 nginx アクセスログの確認（ポート番号付き）

```bash
sudo tail -f /var/log/nginx/access.log
```

出力例：

```log
172.21.0.1 - - [21/Apr/2025:12:34:56 +0900] "GET / HTTP/1.1" 200 77 port=80 "-" "Mozilla/5.0 ..."
172.21.0.1 - - [21/Apr/2025:12:35:10 +0900] "GET / HTTP/1.1" 200 77 port=443 "-" "Mozilla/5.0 ..."
```

---

## ⚠ 注意点

- **ポート8080・80・443が開いている必要があります**（クラウド環境ではNSGやFWに注意）
- `curl -k` でHTTPSを確認するのは自己署名証明書ゆえ（信頼されていない）
- スクリプト実行には **sudo権限が必要**
- `hostname` が空の場合は `hostnamectl --static` を利用（それでも取得できなければ `(unknown-host)` と表示）

---

## 📂 ファイル構成

| パス                                | 説明                    |
|-------------------------------------|-------------------------|
| `/etc/squid/squid.conf`             | Squid 設定ファイル      |
| `/etc/nginx/sites-enabled/default`  | nginx サイト設定        |
| `/etc/nginx/ssl/`                   | 自己署名SSL証明書       |
| `/var/www/html-http/index.html`     | HTTP用コンテンツ        |
| `/var/www/html-https/index.html`    | HTTPS用コンテンツ       |