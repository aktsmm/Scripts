# Azure Blob フォルダ一括削除スクリプト

この PowerShell スクリプトは、Azure Storage アカウント内の指定されたコンテナとフォルダプレフィックス（仮想フォルダ）に一致する BLOB を一括で削除し、その後の削除結果を確認します。

---

## 📌 概要

Azure Storage 上の特定の仮想フォルダ（Prefix）配下の BLOB を **一括削除**するためのスクリプトです。  
BLOB が多数存在する場合や、定期的にクリーンアップを行う運用に便利です。

---

## ⚙️ 必要条件

- PowerShell 5.1 または PowerShell Core
- `Az.Storage` モジュールがインストール済みであること
- Azure アカウントにログイン済み、またはスクリプト内で `Connect-AzAccount` を使用すること

---

## 🧾 スクリプト構成

### 1. 認証処理（任意）

```powershell
# Azure にログインし、対象のテナントとサブスクリプションを指定します。
Connect-AzAccount -TenantId <your-tenant-id>
Select-AzSubscription -SubscriptionId <your-subscription-id>
```

※ すでにログイン済みの場合はスキップ可能です。

---

### 2. 変数定義

以下の変数を自身の環境に合わせて変更してください。

```powershell
$storageAccount   = "<your-storage-account-name>"   # ストレージアカウント名
$containerName    = "<your-container-name>"         # コンテナ名
$folderPrefix     = "<your-folder-prefix>/"         # 仮想フォルダ名（末尾にスラッシュが必要）
$tenantId         = "<your-tenant-id>"              # Azure AD テナント ID
$subscriptionId   = "<your-subscription-id>"        # Azure サブスクリプション ID
```

---

### 3. ストレージコンテキスト作成

```powershell
$ctx = New-AzStorageContext -StorageAccountName $storageAccount -UseConnectedAccount
```

---

### 4. BLOB の一括削除と結果確認

- 対象の BLOB をすべて取得し、順に削除します。
- 削除に失敗した BLOB については警告とエラー詳細が表示されます。
- 最後に、残存している BLOB がないか確認されます。

---

## 🚨 注意点

- `$folderPrefix` の値は必ず **末尾にスラッシュ（`/`）** を付けてください。
- スクリプトは削除対象を完全に消去します。**復旧はできません**。
- `Remove-AzStorageBlob` に `-Force` オプションを指定しているため、確認なしに削除が実行されます。

---

## ✅ 実行例

```powershell
$storageAccount = "mystorage"
$containerName  = "backup"
$folderPrefix   = "daily-backup/"
$tenantId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$subscriptionId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"

# 実行
.\Remove-Blobs.ps1
```

---

## 📝 ライセンス

このスクリプトは MIT ライセンスの下で提供されます。自由にご利用・改変してください。
