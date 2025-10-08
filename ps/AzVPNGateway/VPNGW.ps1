##変数名などは環境に合わせて変更してください
#Get-Date -Format "yyyyMMddhhmmss"
$Ctime=Get-Date -Format "hhmmss"

# Set required paramerters (Please change the parameters according to your environment)
## 2025/09/ 現在 VpnGw1 or VpnGw1AZ SKU ＋ Basic Public IP の構成は VpnGw1 or VpnGw1AZ SKU が Basic Public IP に対応していないため使えないです。
## ✅ Basic VPN GW + Basic PIP (Dynamic)     → 作成可（9月30日まで）
## ❌ Basic VPN GW + Standard PIP (Static)   → 作成不可(そのうち対応？)
## ❌VpnGw1-5Az VPN GW + Basic PIP (Dynamic)   → 作成不可
## ✅ VpnGw1-5Az VPN GW + Standard PIP (Static) → 作成可（今後メイン商用VPNGW)
$GatewaySku = "Basic" ## Basic or VpnGw1 or VpnGw1AZ　
$resourceGroupName = "rg-"+$GatewaySku +$Ctime
$location = "japaneast"
$vnetName = "vnet-"+$GatewaySku
$vnetAddress = "10.0.0.0/16"
$gatewaySubnetAddress = "10.0.100.0/24"
$vmSubnetAddress = "10.0.0.0/24"
$gatewaySubnetName = "GatewaySubnet"
$SubnetName = "defaultSubnet"
$gatewayIPConfigName = "ipconfig1"
$vpnGatewayName = "VpnGw-"+$GatewaySku
$publicIpName = "VpnGw-pip"

 
 # Login to Azure #if you need
#$subscriptionId = "XXXXX-XXXXXXX-XXXXXXXXX-XXX-XXX"
#Connect-AzAccount
#Select-AzSubscription -SubscriptionId $subscriptionId
 
# Create Resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location
 
# Prepare Subnets
$gatewaySubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName -AddressPrefix $gatewaySubnetAddress
$vmSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $vmSubnetAddress
 
# Create VNet
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddress -Subnet $gatewaySubnetConfig,$vmSubnetConfig
 
# Create Public IP for VPN Gateway (Dynamic, Basic)
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic -Sku Basic
 
# Create VPN Gateway
$ipConfig = New-AzVirtualNetworkGatewayIpConfig -Name $gatewayIPConfigName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id
New-AzVirtualNetworkGateway -Name $vpnGatewayName -ResourceGroupName $resourceGroupName -Location $location -IpConfigurations $ipConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku $GatewaySku
