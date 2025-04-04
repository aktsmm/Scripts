# Azure メンテナンス構成 エクスポートスクリプト

このスクリプトは、**同一の Azure Active Directory（AAD）テナント内に存在するすべてのサブスクリプション**に対して、Azure Maintenance Configuration（メンテナンス構成）を取得し、CSVファイルに出力します。

## 🔧 前提条件

- Azure CLI がインストールされていること
- `az login` により Azure にログイン済みであること
- PowerShell 5.x または PowerShell Core が使用可能であること

## 📜 スクリプト概要

スクリプトは以下の処理を行います：

1. `az account show` を使って現在のテナントIDを取得
2. 同じテナント内のすべてのサブスクリプションを列挙
3. 各サブスクリプションについて `az maintenance configuration list` を実行
4. 結果が0件のサブスクリプションはスキップ
5. メンテナンス構成が存在する場合のみ画面に出力
6. 最終的な結果をCSVファイルに出力（カレントフォルダ）

## 📁 出力内容

スクリプト実行後、以下のCSVファイルがカレントディレクトリに作成されます：
```maintenance-configurations.csv```


CSVには以下の列が含まれます：

- `SubscriptionId`
- `Name`
- `Location`
- `MaintenanceScope`
- `ResourceGroup`
- `StartDateTime`
- `RecurEvery`
- `TimeZone`
- `Visibility`

## ▶️ 使用方法

PowerShell でスクリプトを実行します：

```powershell
.\Export-AzMaintenanceConfigurations.ps1
```

## 備考
同じテナントに属する有効なサブスクリプションのみが対象です。

無効化された（Disabled）サブスクリプションは自動的にスキップされます。

必要に応じて、対象スコープやリージョンでのフィルタ処理を追加可能です。