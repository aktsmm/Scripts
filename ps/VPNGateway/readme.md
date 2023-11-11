## VPN GATWWAY を作ります
**BasicSkuはAzure Portal からは作成できないことになっているのでAzure PowerShellなどで作る必要がある**
**BasicSKUは将来的に廃止が決まってるのが、VpnGw1でもそこそこコストがかかるのでBasicSKUを使いたい人がいるはず**
**ただしSKU:BasicSKUはP2Sには対応していないので、P２S環境を作りたい場合はSKU:VpnGw1を使う必要がある**

### VPNGWSKUの詳細
・https://learn.microsoft.com/ja-jp/azure/vpn-gateway/vpn-gateway-about-vpngateways#gwsku
![2023-11-11_23h59_40](https://github.com/aktsmm/Scripts/assets/71251920/da7d4e54-48f9-49d0-bd98-e9dc34caa78a)

## 既存の環境にVPNGATEWAY(とGatewaysubnet)をつくる
VPNGW_add.ps1

## 新規でVnetとVPNGATEWAY(とGatewaysubnet)をつくる
VPNGW_add.ps1
