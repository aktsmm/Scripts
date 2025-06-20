# 全てのリソースグループを取得してループで処理
$resourceGroups = Get-AzResourceGroup
foreach ($resourceGroup in $resourceGroups) {
    # リソースグループ内のリソースを全て削除
    $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
    foreach ($resource in $resources) {
        Write-Host "Deleting resource: $($resource.Name)..."
        Remove-AzResource -ResourceId $resource.ResourceId -Force -Confirm:$false
    }
    
    # リソースグループ自体を削除
    Write-Host "Deleting resource group: $($resourceGroup.ResourceGroupName)..."
    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force -Confirm:$false
}

Write-Host "All resources have been deleted."
