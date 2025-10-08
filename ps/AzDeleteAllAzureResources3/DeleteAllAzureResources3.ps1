<#
===============================================
Azure 全リソースグループ削除スクリプト
(ロック削除オプション + Firewall待機改善 + リトライ付き)
===============================================
#>

# 0. 初期設定
$ErrorActionPreference = "Stop"

# 1. Azureにログインしていなければログイン
if (-not (Get-AzContext)) {
    Connect-AzAccount
}

# 2. 現在のコンテキスト情報取得
$currentContext    = Get-AzContext
$tenantId          = $currentContext.Tenant.Id
$subscriptionId    = $currentContext.Subscription.Id
$subscriptionName  = $currentContext.Subscription.Name

# 3. テナント・サブスクリプション情報表示
Write-Host "`nTenant ID        : $tenantId" -ForegroundColor Cyan
Write-Host "Subscription ID  : $subscriptionId" -ForegroundColor Cyan
Write-Host "Subscription Name: $subscriptionName" -ForegroundColor Cyan
Write-Host ""

# 4. リソースロック確認
Write-Host "リソースロックの確認中..." -ForegroundColor Cyan
$allResourceGroups = Get-AzResourceGroup
$lockedResourceGroups = @()

foreach ($rg in $allResourceGroups) {
    $locks = Get-AzResourceLock -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
    if ($locks) {
        $lockedResourceGroups += $rg.ResourceGroupName
    }
}

if ($lockedResourceGroups.Count -gt 0) {
    Write-Host "`n⚠️ 以下のリソースグループにロックがかかっています:" -ForegroundColor Yellow
    foreach ($rgName in $lockedResourceGroups) {
        Write-Host "  - $rgName" -ForegroundColor Yellow
    }
    Write-Host ""
}

# 5. ユーザー確認
$confirmation = Read-Host "このサブスクリプションで本当にリソース削除を実行しますか？ (Yes/No)"
if ($confirmation -ne "Yes") {
    Write-Host "処理を中断しました。" -ForegroundColor Yellow
    exit
}

# 6. ロック削除オプション
$removeLocks = $false
if ($lockedResourceGroups.Count -gt 0) {
    $lockConfirmation = Read-Host "`nロックがかかっているリソースグループのロックを削除して削除を実行しますか？ (Yes/No)"
    if ($lockConfirmation -eq "Yes") {
        $removeLocks = $true
        Write-Host "✅ ロックを削除してから削除を実行します。" -ForegroundColor Green
    } else {
        Write-Host "⚠️ ロックがかかっているリソースグループはスキップします。" -ForegroundColor Yellow
    }
}

# 7. リソース削除関数
function Remove-AllResourceGroups {
    param(
        [switch]$RetryPhase,
        [bool]$RemoveLocks
    )

    if ($RetryPhase) {
        Write-Host "`n▶ リトライフェーズを開始します..." -ForegroundColor Magenta
    } else {
        Write-Host "`n▶ リソースグループ削除を開始します..." -ForegroundColor Green
    }

    $resourceGroups = Get-AzResourceGroup

    foreach ($resourceGroup in $resourceGroups) {
        $rgName = $resourceGroup.ResourceGroupName
        Write-Host "`nChecking resource group: $rgName ..." -ForegroundColor Cyan

        # リソースグループが削除中ならスキップ
        if ($resourceGroup.ProvisioningState -eq "Deleting") {
            Write-Host "⚠️ Resource group '$rgName' is already being deleted. Skipping." -ForegroundColor Yellow
            continue
        }

        # リソースロック確認と処理
        $locks = Get-AzResourceLock -ResourceGroupName $rgName -ErrorAction SilentlyContinue
        if ($locks) {
            if ($RemoveLocks) {
                Write-Host "🔓 Removing locks from resource group '$rgName'..." -ForegroundColor Yellow
                foreach ($lock in $locks) {
                    try {
                        Remove-AzResourceLock -LockId $lock.LockId -Force -Confirm:$false
                        Write-Host "  ✅ Lock removed: $($lock.Name)" -ForegroundColor Green
                    } catch {
                        Write-Host "  ❌ Failed to remove lock: $($lock.Name)" -ForegroundColor Red
                        Write-Host "  Skipping resource group '$rgName'." -ForegroundColor Yellow
                        continue
                    }
                }
            } else {
                Write-Host "❌ Lock detected on resource group '$rgName'. Skipping deletion." -ForegroundColor Yellow
                continue
            }
        }

        Write-Host "✅ No lock detected. Proceeding with resource deletion in '$rgName'..." -ForegroundColor Green

        # リソース一覧取得
        $resources = Get-AzResource -ResourceGroupName $rgName

        # リソース削除優先順位
        $priorityOrder = @(
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Network/networkInterfaces",
            "Microsoft.Network/publicIPAddresses",
            "Microsoft.Network/networkSecurityGroups",
            "Microsoft.Network/azureFirewalls",
            "Microsoft.Network/loadBalancers",
            "Microsoft.Network/virtualNetworks"
        )

        $orderedResources = $resources | Sort-Object {
            $priority = $priorityOrder.IndexOf($_.ResourceType)
            if ($priority -eq -1) { 100 } else { $priority }
        }

        # リソース削除
        foreach ($resource in $orderedResources) {

            # NSG関連付け解除
            if ($resource.ResourceType -eq "Microsoft.Network/networkSecurityGroups") {
                Write-Host "Checking if NSG $($resource.Name) is associated with any subnet..." -ForegroundColor Cyan
                $vnets = Get-AzVirtualNetwork -ResourceGroupName $rgName
                foreach ($vnet in $vnets) {
                    foreach ($subnet in $vnet.Subnets) {
                        if ($subnet.NetworkSecurityGroup -and $subnet.NetworkSecurityGroup.Id -eq $resource.ResourceId) {
                            Write-Host "Removing NSG from subnet: $($subnet.Name) in VNET: $($vnet.Name)..." -ForegroundColor Yellow
                            $subnet.NetworkSecurityGroup = $null
                            Set-AzVirtualNetwork -VirtualNetwork $vnet
                        }
                    }
                }
            }

            # Public IP → Firewall解除
            elseif ($resource.ResourceType -eq "Microsoft.Network/publicIPAddresses") {
                Write-Host "Checking if Public IP $($resource.Name) is associated with Azure Firewall..." -ForegroundColor Cyan
                $firewalls = Get-AzFirewall -ResourceGroupName $rgName -ErrorAction SilentlyContinue
                foreach ($firewall in $firewalls) {
                    $updated = $false
                    foreach ($ipconfig in $firewall.IpConfigurations) {
                        if ($ipconfig.PublicIpAddress.Id -eq $resource.ResourceId) {
                            Write-Host "Removing Public IP from Azure Firewall: $($firewall.Name)..." -ForegroundColor Yellow
                            $firewall.IpConfigurations = @()
                            try {
                                Set-AzFirewall -AzureFirewall $firewall
                                $updated = $true
                            } catch {
                                Write-Host "⚠️ Firewall update failed. Skipping..." -ForegroundColor Yellow
                                continue
                            }
                        }
                    }

                    # Firewall更新監視
                    if ($updated) {
                        Write-Host "Waiting for Azure Firewall update operation to complete..." -ForegroundColor Yellow

                        $retryCount = 0
                        $maxRetries = 2

                        do {
                            Start-Sleep -Seconds 5
                            $currentFirewall = Get-AzFirewall -Name $firewall.Name -ResourceGroupName $rgName -ErrorAction SilentlyContinue
                            if (-not $currentFirewall) {
                                Write-Host "Firewall not found. Skipping wait." -ForegroundColor Yellow
                                break
                            }

                            $provisioningState = $currentFirewall.ProvisioningState
                            Write-Host "Current provisioning state: $provisioningState" -ForegroundColor Gray

                            if ($provisioningState -eq "Deleting" -or $provisioningState -eq "Failed") {
                                Write-Host "Firewall is in '$provisioningState' state. Skipping wait." -ForegroundColor Yellow
                                break
                            }
                            $retryCount++
                        } while ($provisioningState -ne "Succeeded" -and $retryCount -lt $maxRetries)

                        if ($retryCount -ge $maxRetries) {
                            Write-Host "Timeout waiting for Firewall provisioning. Skipping." -ForegroundColor Yellow
                        } else {
                            Write-Host "Azure Firewall update completed!" -ForegroundColor Green
                        }
                    }
                }
            }

            # リソース削除
            Write-Host "Deleting resource: $($resource.Name) ($($resource.ResourceType))..." -ForegroundColor Gray
            try {
                Remove-AzResource -ResourceId $resource.ResourceId -Force -Confirm:$false
            } catch {
                Write-Host "⚠️ Failed to delete resource: $($resource.Name). Skipping." -ForegroundColor Yellow
            }
        }

        # リソースグループ削除
        Write-Host "Deleting resource group: $rgName..." -ForegroundColor Magenta
        try {
            Remove-AzResourceGroup -Name $rgName -Force -Confirm:$false

            # 削除完了待機
            $waitCount = 0
            $maxWait = 20
            do {
                Start-Sleep -Seconds 5
                $exists = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
                if (-not $exists) {
                    Write-Host "✅ Resource group '$rgName' deleted successfully." -ForegroundColor Green
                    break
                }
                Write-Host "⏳ Waiting for resource group '$rgName' to be deleted..." -ForegroundColor Gray
                $waitCount++
            } while ($waitCount -lt $maxWait)

            if ($waitCount -ge $maxWait) {
                Write-Host "⚠️ Timeout waiting for resource group '$rgName' deletion." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️ Failed to delete resource group: $rgName. Please check manually." -ForegroundColor Yellow
        }
    }
}

# 8. 削除処理 1回目実行
Remove-AllResourceGroups -RemoveLocks $removeLocks

# 9. 削除処理 リトライ2回目
Remove-AllResourceGroups -RetryPhase -RemoveLocks $removeLocks

# 10. 完了メッセージ
Write-Host "`n🎉 全処理完了しました！" -ForegroundColor Green