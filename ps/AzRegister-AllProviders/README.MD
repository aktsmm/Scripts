# 🌀 Az-Register-AllProviders.ps1

## 概要

`Az-Register-AllProviders.ps1` は、現在の Azure サブスクリプションで  
**未登録のリソースプロバイダー (Resource Providers)** を一括登録する PowerShell スクリプトです。

Azure Policy や Microsoft Defender for Cloud、Bicep デプロイ時に  
「リソースプロバイダーが登録されていないために失敗する」問題を解消する目的で利用します。

---

## 🧩 主な機能

| 機能 | 説明 |
|------|------|
| 🔍 未登録 RP 検出 | `Get-AzResourceProvider` を使用して、登録状態を取得 |
| ⚙️ 一括登録 | `Register-AzResourceProvider` で未登録のすべてを自動登録 |
| 🚦 ログ出力 | 登録中・完了・失敗を色付きで表示 |
| 🛡️ 冪等性 | 既に登録済みの RP はスキップされるため、再実行しても安全 |
| ⏱️ 実行時間 | 約5〜30分（環境・登録数により変動） |

---

## 🪛 事前準備

1. **Azure PowerShell モジュールをインストール**
   ```powershell
   Install-Module Az -Scope CurrentUser -Force
