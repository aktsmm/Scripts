# README.md

## 概要

このスクリプトは、Azure CLI (`az`) を用いて、指定したローカルフォルダ以下のファイルを再帰的に Azure Blob Storage にアップロードするためのバッチ実行スクリプトです。

RBAC（Azure AD）認証を使用することで、ストレージアカウントキーをハードコーディングせずに安全にアップロードできます。

## 前提条件

1. **Azure CLI** がインストールされていること
2. 実行ユーザーが対象ストレージアカウントに対して **Storage Blob Data Contributor** ロールを持っていること
3. インターネット接続が可能であること（認証・アップロード時）
4. **Azure CLI** は PowerShell をはじめ、Bash（Ubuntu Shell）や Azure Cloud Shell など、さまざまなシェル上で動作すること
5. **本スクリプトの変数定義** は PowerShell の構文を前提としているため、PowerShell 環境（Azure CLI + PowerShell）での実行を推奨します

## プレースホルダ定義

スクリプト冒頭の以下の変数部分を、ご自身の環境に合わせて置き換えてください。

```powershell
# Azure AD テナント ID
$TenantId       = "<YOUR_TENANT_ID>"
# Azure サブスクリプション ID
$SubscriptionId = "<YOUR_SUBSCRIPTION_ID>"
# ストレージアカウント名
$AccountName    = "<YOUR_STORAGE_ACCOUNT_NAME>"
# アップロード先の Blob コンテナ名
$ContainerName  = "<YOUR_BLOB_CONTAINER_NAME>"
# ローカルのアップロード元フォルダパス
$SourcePath     = "<LOCAL_SOURCE_FOLDER_PATH>"
```

> **例**
>
> ```powershell
> $TenantId       = "00000000-0000-0000-0000-000000000000"
> $SubscriptionId = "00000000-0000-0000-0000-000000000000"
> $AccountName    = "mystorageaccount"
> $ContainerName  = "mycontainer"
> $SourcePath     = "C:\path\to\data"
```


## 実行手順

1. スクリプトをダウンロードまたは保存する（例：`AzBlobUpload.ps1`）
2. 必要に応じて PowerShell 実行ポリシーを設定（ローカル実行時）

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. スクリプトを実行

   ```powershell
   .\AzBlobUpload.ps1
   ```

   * ログイン時にブラウザが立ち上がり、Azure AD 認証を行います
   * 認証完了後、自動的に指定フォルダ内を再帰的にアップロードします

## スクリプト内容例

以下は PowerShell 向けのスクリプト内容例です。ファイル名は `AzBlobUpload.ps1` としてください。

```powershell
#――――――――――――――――――――
# プレースホルダ定義
#――――――――――――――――――――
$TenantId       = "<YOUR_TENANT_ID>"
$SubscriptionId = "<YOUR_SUBSCRIPTION_ID>"
$AccountName    = "<YOUR_STORAGE_ACCOUNT_NAME>"
$ContainerName  = "<YOUR_BLOB_CONTAINER_NAME>"
$SourcePath     = "<LOCAL_SOURCE_FOLDER_PATH>"

#――――――――――――――――――――
# ① ログイン ＆ サブスクリプション切替
#――――――――――――――――――――
az login --tenant $TenantId
az account set --subscription $SubscriptionId

#――――――――――――――――――――
# ② バッチアップロード
#――――――――――――――――――――
az storage blob upload-batch `
  --account-name $AccountName `
  --destination   $ContainerName `
  --source        $SourcePath `
  --auth-mode     login
```
