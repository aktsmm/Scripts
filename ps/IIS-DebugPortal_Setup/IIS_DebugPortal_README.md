
# 🌐 Setup_IIS_Debug_Env.ps1 - README

## 📝 概要

この PowerShell スクリプト `Setup_IIS_Debug_Env.ps1` は、Windows Server 2019 以降で実行可能な **IIS + Classic ASP ベースのデバッグ環境** を自動構築します。  
Ubuntu + nginx + Squid 相当のヘッダ確認環境を Windows 上に再現するための完全自動セットアップスクリプトです。

---

## 🚀 主な機能一覧

| 機能                           | 説明 |
|--------------------------------|------|
| IIS + Classic ASP 構成        | PowerShell から自動で IIS と ASP 機能を追加 |
| HTTPS 対応（自己署名証明書） | `CN=localhost` の証明書を生成してバインド |
| W3Cログ形式 + カスタム出力   | `X-Forwarded-For`, `User-Agent` なども IIS ログへ出力 |
| JSON / HTML 切り替え          | `/index.asp` にアクセスすると Accept ヘッダーに応じて JSON または HTML |
| クライアント IP 情報表示     | Proxy 通過時の IP 確認用として `X-Real-IP`, `X-Forwarded-For` も解析 |
| パブリックIP表示             | `api.ipify.org` でグローバルIPを確認・表示 |
| IE ESC 無効化                 | 管理者・ユーザー両方に対して強制無効化 |
| ファイアウォール自動開放     | HTTP, HTTPS, RDP のインバウンドを許可 |
| index.asp に固定SN表示       | デプロイ毎に8桁のハッシュ(SN)を表示・識別用に活用可 |
| tail -f 風のログ監視          | PowerShell または WSL でリアルタイムログ確認可能 |

---

## ブラウザでの確認例
![Image](https://github.com/user-attachments/assets/86d5524b-dfcf-4805-9cb6-3239820e1402)

![Image](https://github.com/user-attachments/assets/703d9d87-866c-4137-bef2-bea5b26c0c28)

## 🧪 確認コマンド例

### ✅ HTML 出力を確認

```powershell
Invoke-WebRequest "http://localhost" `
  -Headers @{
    "X-Real-IP"      = "9.9.9.9"
    "X-Forwarded-For"= "1.2.3.4"
    "Referer"        = "https://example.com/"
  } |
  Select-Object -ExpandProperty Content
```

### ✅ JSON 出力を取得（スプラッティング）

```powershell
$headers = @{
  Accept           = 'application/json'
  'X-Real-IP'      = '9.9.9.9'
  'X-Forwarded-For'= '1.2.3.4'
  Referer          = 'https://example.com/'
}
Invoke-RestMethod -Uri 'http://localhost' -Headers $headers | Format-List *
```
![Image](https://github.com/user-attachments/assets/2fd40ed1-ef50-4222-9a6f-5753eb9b73f0)
---

## 📂 ログファイル確認（tail -f 相当）

PowerShell or WSL で以下のように実行してリアルタイムでログ確認が可能です。

```powershell
# PowerShell で
Get-Content -Path "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 10 -Wait

# WSL (Linux風コマンド)
tail -f /mnt/c/inetpub/logs/LogFiles/W3SVC1/u_ex*.log
```

---

## 📎 補足

- 実行後はブラウザで `https://<サーバーIP>/` にアクセスして動作確認が可能。
- `?format=json` または `Accept: application/json` を付けると JSON 出力に切り替わります。
- `SN`（シリアルナンバー）は毎回のセットアップでランダムに生成され、識別用に表示されます。

---

## 📘 対応環境

- Windows Server 2019 またはそれ以降
- PowerShell 5.1 以上
- 管理者権限での実行が必須

---

## 🛡️ 注意事項

- 本スクリプトは開発・デバッグ用途向けです。本番環境では適切なセキュリティ設定をご検討ください。
- 自己署名証明書は信頼されていないため、ブラウザで警告が表示されることがあります。

---

✅ 完了後、ブラウザで以下を確認してみてください：

```
https://<your-server-ip>/
https://<your-server-ip>/?format=json
```

---

作成者: Yamapan / ChatGPT  
ライセンス: MIT または自由利用
