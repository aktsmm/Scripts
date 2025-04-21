## このBashスクリプトは、Azure上に仮想マシンを作成し、nginxとNode.jsを使用して簡単なWebサーバーをセットアップするものです。

## 説明

変数の設定:

RG="rg-loadbalancer-l100"
LOC="japaneast"
VM_NAME="vm-ubuntu1804"
VM_SIZE="Standard_B2s"
VM_IMAGE="Canonical:UbuntuServer:18.04-LTS:latest"
VM_USERNAME="azureuser"
VM_PASSWORD='WindowsAzure!2010'
スクリプトで使用する各種変数を設定しています。これらの変数には、リソースグループ、場所、仮想マシンの名前、サイズ、イメージ、ユーザー名、パスワードなどが含まれています。
cloud-init ファイルの生成:

bash
Copy code
cat <<EOF >cloud-init.txt
#cloud-config
package_upgrade: true
packages:
  - nginx
  - nodejs
  - npm
runcmd:
  - service nginx restart
  - cd "/home/${VM_USERNAME}/myapp"
  - npm init
  - npm install express -y
  - nodejs index.js
EOF
ここでは、cloud-init ファイルを生成しています。このファイルは、仮想マシンの初期構成として使用されます。nginxの設定やNode.jsアプリケーションのセットアップが含まれています。
Azure リソースの作成:

bash
Copy code
az network public-ip create --name "$VM_NAME-pip" -g $RG -l $LOC \
    --sku Standard \
    --zone 1 2 3
az network nic create --name "$VM_NAME-nic" -g $RG -l $LOC \
    --vnet-name vnet-main \
    --subnet backend \
    --public-ip-address "$VM_NAME-pip"
az vm create --name $VM_NAME -g $RG -l $LOC \
    --image $VM_IMAGE \
    --size $VM_SIZE \
    --nics "$VM_NAME-nic" \
    --os-disk-name "$VM_NAME-osdisk" \
    --admin-username $VM_USERNAME \
    --admin-password "$VM_PASSWORD" \
    --custom-data cloud-init.txt
最後に、Azure CLIコマンドを使用して公開IP、NIC（ネットワーク インターフェイス カード）、および仮想マシンを作成しています。--custom-dataオプションを使用して、cloud-initファイルをカスタムデータとして仮想マシンに渡しています。