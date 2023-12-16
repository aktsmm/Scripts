
RG="rg-loadbalancer-l100"
LOC="japaneast"
VM_NAME="vm-ubuntu1804"
VM_SIZE="Standard_B2s"
VM_IMAGE="Canonical:UbuntuServer:18.04-LTS:latest"
VM_USERNAME="azureuser"
VM_PASSWORD='WindowsAzure!2010'

cat <<EOF >cloud-init.txt
#cloud-config
package_upgrade: true
packages:
  - nginx
  - nodejs
  - npm
write_files:
  - owner: www-data:www-data
    path: /etc/nginx/sites-available/default
    content: |
      server {
        listen 80;
        location / {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade \$http_upgrade;
          proxy_set_header Connection keep-alive;
          proxy_set_header Host \$host;
          proxy_cache_bypass \$http_upgrade;
        }
      }
  - owner: ${VM_USERNAME}:${VM_USERNAME}
    path: /home/${VM_USERNAME}/myapp/index.js
    content: |
      var express = require('express')
      var app = express()
      var os = require('os');
      app.get('/', function (req, res) {
        res.send('Hi, this is ' + os.hostname() + '!')
      })
      app.listen(3000, function () {
        console.log('Hello world app listening on port 3000!')
      })
runcmd:
  - service nginx restart
  - cd "/home/${VM_USERNAME}/myapp"
  - npm init
  - npm install express -y
  - nodejs index.js
EOF

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
