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
