# Squid プロキシ + Python HTTP サーバー自動構築スクリプト

このスクリプトは、検証向けに Ubuntu 環境上で Squid プロキシサーバーと Python ベースの簡易 HTTP サーバーを構築・起動するためのものです。
[setup-squid-http.sh](./setup-squid-http.sh)


## ✅ 機能概要

- Squid をポート `8080` で起動
- Squid プロキシの全アクセス許可設定（テスト用途）
- Python の HTTP サーバーをポート `80` で systemd サービスとして構成
- サーバー起動時に両サービスが自動起動
- ホスト名を表示する `index.html` を自動生成

## 🖥️ 前提条件

- Ubuntu（20.04 以降推奨）
- sudo 権限を持つユーザー

## 🚀 使い方

```bash
chmod +x setup.sh
./setup.sh
```

## 📁 出力

- Squid: ポート `8080` で待機
- Python HTTPサーバ: `http://<サーバーIP>/index.html` にて表示
- ログファイル: `/var/log/python_http.log`

## ⚠️ 注意事項
> **このスクリプトは、検証・学習目的のローカル環境を想定しています。**
- `squid.conf` にて `http_access allow all` を有効にしています。本番環境ではアクセス制限の調整が必要です。
- `http_access allow all` により、すべてのリクエストを無条件で許可します。
  - 本番環境では、適切な `acl`（例: `localnet`, `mypc`）を使って制限してください。
- HTTP サーバーは `root` ユーザーとして動作します。セキュリティ上の観点から、必要に応じて実行ユーザーを変更してください。
- ポート `80` を使用するため root 権限が必要です。必要に応じて他のポートに変更可能です。
- systemd 経由で起動する Python HTTP サーバーは、root ユーザーで動作し、誰でもアクセス可能です。

## 参考
* コマンド `sudo tail -f /var/log/squid/access.log` にてリアルタイムでSquidのアクセスログを確認する事が可能。
* コマンド `ip -4 addr show eth0 | grep inet | awk '{print $2}' | cut -d/ -f1` や `hostname -I` にて eth0 の IP アドレスを確認可能。
* コマンド `curl -x http://<プロキシのIP>:8080 http://example.com` や `Invoke-WebRequest http://example.com -Proxy "http://<プロキシのIP>:8080"` にてテスト可能

## 📜 ライセンス

MIT ライセンス
### MITライセンスの下で公開されたソフトウェアは：
✅ 自由に使える（商用利用・改変・再配布OK
✅ 改変して再配布してもOK（ライセンス表示だけ守れば）
✅ ライセンスと著作権表示を残すことが条件
✅ただし、このソフトを使ったことで問題が起きても、作者は責任を負いません。

## 参考
* コマンド `sudo tail -f /var/log/squid/access.log` にてリアルタイムでSquidのアクセスログを確認する事が可能。
* コマンド `ip -4 addr show eth0 | grep inet | awk '{print $2}' | cut -d/ -f1` にて eth0 の IP アドレスを確認可能。
