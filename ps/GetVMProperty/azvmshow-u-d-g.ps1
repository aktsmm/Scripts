echo "az vm show -u -d -g RG-APPSTEST -n VM-AppUbuntu --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g RG-APPSTEST -n VM-AppUbuntu --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g RG-LBNAT -n VM-ubuntu-LBNAT --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g RG-LBNAT -n VM-ubuntu-LBNAT --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g RG-LBNAT -n VM-WinS-LBNAT --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g RG-LBNAT -n VM-WinS-LBNAT --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g rg-temp -n VM-Origin --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g rg-temp -n VM-Origin --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g rg-temp -n VM-temp1  --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g rg-temp -n VM-temp1  --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g rg-temp -n VM-temp2  --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g rg-temp -n VM-temp2  --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g rg-temp -n VM-tempp --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g rg-temp -n VM-tempp --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g RG-TEST-16  -n Vnet-Hub-Ubu --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g RG-TEST-16  -n Vnet-Hub-Ubu --query storageProfile.osDisk.deleteOption
echo "az vm show -u -d -g RG-TEST-16   -n Vnet-Hub-Win --query storageProfile.osDisk.deleteOption"
az vm show -u -d -g RG-TEST-16   -n Vnet-Hub-Win --query storageProfile.osDisk.deleteOption
   Read-Host -Prompt "Script Done! Press Enter to exit"
   