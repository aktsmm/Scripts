# -------------------------------
# 認証処理＜ログイン済みであれば省略可＞
# -------------------------------
# Write-Host "🔐 Azure にログイン中..."
# Connect-AzAccount -TenantId $tenantId | Out-Null

# Write-Host "📌 サブスクリプションを選択中..."
# Select-AzSubscription -SubscriptionId $subscriptionId | Out-Null


# -------------------------------
# 変数定義（必要に応じて書き換えてください）
# -------------------------------
# ストレージアカウント名
$storageAccount = "<your-storage-account-name>"   # 例: "hinokuni"
# BLOB コンテナ名
$containerName = "<your-container-name>"         # 例: "testdata"
# 削除対象の仮想フォルダ（末尾にスラッシュ必須）
$folderPrefix = "<your-folder-prefix>/"         # 例: "rehydrate/"
# テナント ID
$tenantId = "<your-tenant-id>"              # 例: "892fd90b-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# サブスクリプション ID
$subscriptionId = "<your-subscription-id>"        # 例: "7134d7ae-xxxx-xxxx-xxxx-xxxxxxxxxxxx"



# -------------------------------
# ストレージコンテキストの作成
# -------------------------------
$ctx = New-AzStorageContext -StorageAccountName $storageAccount -UseConnectedAccount

# -------------------------------
# BLOB 一括削除処理
# -------------------------------
Write-Host "`n🚮 [$folderPrefix] 配下のBLOBを削除開始..."

$blobs = Get-AzStorageBlob -Container $containerName -Context $ctx -Prefix $folderPrefix

if ($blobs.Count -eq 0) {
    Write-Host "⚠️ 削除対象の BLOB が存在しませんでした。"
}
else {
    foreach ($blob in $blobs) {
        try {
            Remove-AzStorageBlob -Blob $blob.Name -Container $containerName -Context $ctx -Force
            Write-Host "✅ Deleted: $($blob.Name)"
        }
        catch {
            Write-Warning "❗ Failed to delete: $($blob.Name)"
            $_ | Format-List *  # エラー詳細出力
        }
    }

    # -------------------------------
    # 削除後の確認
    # -------------------------------
    Start-Sleep -Seconds 5  # 反映待ち

    $remaining = Get-AzStorageBlob -Container $containerName -Context $ctx -Prefix $folderPrefix

    if ($remaining.Count -eq 0) {
        Write-Host "`n🎉 フォルダ [$folderPrefix] 配下のすべてのBLOBは正常に削除されました。"
    }
    else {
        Write-Warning "`n❗ 一部のBLOBが削除されていません:"
        $remaining | Select-Object Name
    }
}
