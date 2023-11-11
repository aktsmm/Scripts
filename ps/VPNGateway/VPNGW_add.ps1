####
##Gatewaysubnetがない場合は作成します。
##ある場合はそれを利用します。

######変数設定
# Set required parameters for existing resource group and Vnet (Please change the parameters according to your environment)
$location = "japaneast"
$subscriptionId = "xxxxxxxxxxxx" #if you need
$existingResourceGroupName = "rg-XXXX"
$existingVnetName = "XXXX"

# Set vpngw name parameters
$vpnGatewayName = "vpngw"
$GatewaySku = "Basic" ## Basic or VpnGw1 or VpnGw1AZ
$publicIpName = "$vpnGatewayName-pip"
$gatewayIPConfigName = "$vpnGatewayName-config"
# Set other vpngw parameters
$gatewaySubnetName = "GatewaySubnet" #DO NOT CHANGE
$gatewaySubnetAddress = "10.100.0.0/24"

######コマンド実行
# Login to Azure
#Connect-AzAccount -Subscription $subscriptionId ##if you need

# 現在のSubscriptionを取得
get-azContext


# Get existing Vnet and Resource Group
$existingVnet = Get-AzVirtualNetwork -Name $existingVnetName -ResourceGroupName $existingResourceGroupName

# Create Gateway Subnet if it doesn't exist
$existingGatewaySubnet = $existingVnet.Subnets | Where-Object { $_.Name -eq $gatewaySubnetName }

if (-not $existingGatewaySubnet) {
    Write-Host "Creating Gateway Subnet..."
    
    $gatewaySubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName -AddressPrefix $gatewaySubnetAddress
    $existingVnet | Add-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetConfig.Name -AddressPrefix $gatewaySubnetConfig.AddressPrefix
    $existingVnet | Set-AzVirtualNetwork
    Write-Host "Gateway Subnet created."
}else{
    Write-Host "Gateway Subnet already exists."
}

# Wait for 10 seconds
#Write-Host "Waiting for 10 seconds..."
#Start-Sleep -Seconds 10

# Get existing Vnet and Resource Group
$existingVnet = Get-AzVirtualNetwork -Name $existingVnetName -ResourceGroupName $existingResourceGroupName

# Get Gateway Subnet Id
$gatewaySubnetId = ($existingVnet.Subnets | Where-Object { $_.Name -eq $gatewaySubnetName }).Id

# $gatewaySubnetId が null である場合はエラーメッセージを表示して終了
if ($null -eq $gatewaySubnetId) {
    Write-Host "Error: Gateway Subnet ID is null. Please check if the Gateway Subnet exists."
    return
}

# Create Public IP for VPN Gateway (Dynamic, Basic)
Write-Host "Creating Public IP for VPN Gateway..."
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $existingResourceGroupName -Location $location -AllocationMethod Dynamic -Sku Basic
Write-Host "Public IP created."

# Create VPN Gateway
Write-Host "Creating VPN Gateway..."
$ipConfig = New-AzVirtualNetworkGatewayIpConfig -Name $gatewayIPConfigName -SubnetId $gatewaySubnetId -PublicIpAddressId $publicIp.Id
New-AzVirtualNetworkGateway -Name $vpnGatewayName -ResourceGroupName $existingResourceGroupName -Location $location -IpConfigurations $ipConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku $GatewaySku
Write-Host "VPN Gateway created."
