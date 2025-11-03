# ==========================================
# 🔧 Azure PowerShell で未登録プロバイダーを一括登録
# ==========================================

# サブスクリプション選択（必要に応じて設定）
# Set-AzContext -Subscription "<your-subscription-id>"

# 未登録のリソースプロバイダー一覧を取得
$providers = Get-AzResourceProvider | Where-Object { $_.RegistrationState -ne "Registered" }

if ($providers.Count -eq 0) {
    Write-Host "✅ すべてのリソースプロバイダーが登録済みです。" -ForegroundColor Green
    return
}

# 登録処理
foreach ($p in $providers) {
    Write-Host "⏳ 登録中: $($p.ProviderNamespace)"
    try {
        Register-AzResourceProvider -ProviderNamespace $p.ProviderNamespace -ErrorAction Stop
        Write-Host "✅ 登録完了: $($p.ProviderNamespace)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ 登録失敗: $($p.ProviderNamespace) - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 すべての登録が完了しました（反映には数分かかります）" -ForegroundColor Cyan
