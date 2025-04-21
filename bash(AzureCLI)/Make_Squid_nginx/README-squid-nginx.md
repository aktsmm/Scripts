# Squid + NGINX 自動構成スクリプト (Ubuntu用)

このスクリプトは、Ubuntuベースのサーバーにおいて、以下の構成を自動化するためのものです。

- Squid（HTTPプロキシ）をポート `8080` で構成し、すべてのアクセスを許可
- nginx を HTTP (`80`) / HTTPS (`443`) で構成
- HTTPS は自己署名証明書で実装
- ログにポート番号を記録
- HTTP/HTTPS それぞれに異なる HTML を表示
- 両サービスを OS 起動時に自動起動するよう設定

---

## 🔧 セットアップ手順

### 1. スクリプトファイルを作成

```bash
nano setup-squid-nginx.sh
```

内容を貼り付けて、保存 (`Ctrl+O` → `Enter` → `Ctrl+X`)

---

### 2. 実行権限を付与し、実行

```bash
chmod +x setup-squid-nginx.sh
sudo ./setup-squid-nginx.sh
```

---

## ✅ 構成内容の詳細

### Squid（HTTPプロキシ）

| 項目         | 内容                     |
|--------------|--------------------------|
| ポート       | 8080                     |
| アクセス制御 | 全部許可（`allow all`）   |
| 自動起動     | 有効                     |

プロキシ動作確認：

```bash
curl -x http://localhost:8080 http://example.com
```

---

### nginx（HTTP/HTTPS）

| 項目         | 内容                                           |
|--------------|------------------------------------------------|
| ポート       | HTTP: `80` / HTTPS: `443`                     |
| SSL証明書    | 自己署名（1年間有効）                         |
| リダイレクト | HTTP→HTTPS の強制なし                         |
| ログ         | `$server_port` を含んだ独自ログフォーマットを追加 |
| 自動起動     | 有効                                           |

アクセス確認：

```bash
curl http://localhost
curl -k https://localhost
```

---

## 📝 表示されるHTML内容

| アクセス方法 | 表示内容                           |
|--------------|------------------------------------|
| HTTP (`80`)  | `Welcome to NGINX over HTTP!`      |
| HTTPS (`443`)| `Welcome to NGINX over HTTPS!`     |

HTMLは以下に保存されています：

- `/var/www/html-http/index.html`
- `/var/www/html-https/index.html`

---

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

- **ポート8080・80・443が開いている必要があります**（Cloud環境ではNSGやFWに注意）
- `curl -k` でHTTPSを確認するのは自己署名証明書ゆえ（信頼されていない）
- スクリプト実行には **sudo権限が必要**
- `squid -z` は初回にキャッシュ構成が必要な場合にだけ必要（このスクリプトでは不要）

---

## 📂 ファイル構成

| パス                             | 説明                           |
|----------------------------------|--------------------------------|
| `/etc/squid/squid.conf`          | Squid 設定ファイル             |
| `/etc/nginx/sites-enabled/default`| nginx サイト設定               |
| `/etc/nginx/ssl/`                | 自己署名SSL証明書              |
| `/var/www/html-http/index.html` | HTTP用コンテンツ               |
| `/var/www/html-https/index.html`| HTTPS用コンテンツ              |