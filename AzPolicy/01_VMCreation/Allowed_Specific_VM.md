# Azure Policy: Virtual Machine and Scale Set Image Restrictions

## 概要
このAzure Policyは、仮想マシンおよび仮想マシンスケールセット (VMSS) のイメージに関する制限を設定し、特定のパブリッシャー、カスタムイメージ、およびディスクに基づいたVMの作成を制御するためのものです。また、特定のタグが付与されたVMSSは制限をバイパスできます。

## ポリシールールの説明
このポリシールールは以下の条件に基づいて適用されます。

### 仮想マシン (Microsoft.Compute/virtualMachines)
- イメージのパブリッシャー、リソースID、またはディスクIDが許可されたリストに含まれていない場合にVMの作成を拒否します。

### 仮想マシンスケールセット (Microsoft.Compute/virtualMachineScaleSets)
- 設定されたタグ (`tagName`) が存在しないVMSSに対してイメージ制限を適用し、条件を満たさない場合に作成を拒否します。

## パラメーター
以下のパラメーターによって柔軟なポリシー設定が可能です。

| パラメーター名 | 種類 | 説明 | デフォルト値 |
| --- | --- | --- | --- |
| `listOfAllowedImagePublishers` | Array | 許可されるイメージのパブリッシャーのリスト | ["RedHat"] |
| `listOfAllowedImageOffers` | Array | 許可されるイメージオファーのリスト | ["UbuntuServer", "microsoftsqlserver"] |
| `listOfAllowedImagesResourceIDs` | Array | 許可されるカスタムイメージのリソースID | ["/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm"] |
| `allowedDiskIdPattern` | String | 許可されるディスクIDに含まれる文字列パターン | "-osdisk-20" |
| `vmssNamePrefix` | String | VMSSがイメージ制限をバイパスするために必要なリソースプレフィックス名 | "aks-" |


## 適用条件
- **仮想マシン:** 許可されるパブリッシャー、カスタムイメージ、またはディスクIDパターンが条件に一致しない場合、VMの作成は拒否されます。
- **仮想マシンスケールセット:** 許可されたタグが設定されていない場合、イメージ制限が適用され、条件に一致しない場合は拒否されます。

## ポリシーの詳細構造
```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "anyOf": [
        {
          "allOf": [
            {
              "field": "type",
              "equals": "Microsoft.Compute/virtualMachines"
            },
            {
              "not": {
                "anyOf": [
                  {
                    "field": "Microsoft.Compute/virtualMachines/storageProfile.imageReference.publisher",
                    "in": "[parameters('listOfAllowedImagePublishers')]"
                  },
                  {
                    "field": "Microsoft.Compute/virtualMachines/storageProfile.imageReference.id",
                    "in": "[parameters('listOfAllowedImagesResourceIDs')]"
                  },
                  {
                    "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.id",
                    "contains": "[parameters('allowedDiskIdPattern')]"
                  }
                ]
              }
            }
          ]
        },
        {
          "allOf": [
            {
              "field": "type",
              "equals": "Microsoft.Compute/virtualMachineScaleSets"
            },
            {
              "not": {
                "anyOf": [
                  {
                    "field": "[concat('tags[\"', parameters('tagName'), '\"]')]",
                    "exists": true
                  }
                ]
              }
            }
          ]
        }
      ]
    },
      "then": {
        "effect": "deny"
      }
    },
    "parameters": {
      "listOfAllowedImagePublishers": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Image Publishers",
          "description": "List of allowed image publishers. Only images from these publishers are permitted. Example: [\"RedHat\"]"
        },
        "defaultValue": [
          "RedHat"
        ]
      },
      "listOfAllowedImageOffers": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Image Offers for VMs",
          "description": "List of allowed image offers. Only images with these offers are permitted. Example: [\"UbuntuServer\",\"microsoftsqlserver\"]"
        },
        "defaultValue": [
          "UbuntuServer",
          "microsoftsqlserver"
        ]
      },
      "listOfAllowedImagesResourceIDs": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Images Resource IDs for Custum Images",
          "description": "List of allowed custom image resource IDs. Only these custom images are permitted. Example: [\"/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm\"]"
        },
        "defaultValue": [
          "/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm"
        ]
      },
      "allowedDiskIdPattern": {
        "type": "String",
        "metadata": {
          "displayName": "Allowed Disk ID Pattern (Contains Any Specified String)",
          "description": "Allows the creation of VMs from disks that contain any specified string. The default value is intended for disks restored by Azure VM Backup"
        },
        "defaultValue": "-osdisk-20"
      },
      "vmssNamePrefix": {
        "type": "String",
        "metadata": {
          "displayName": "Allowed VMSS Name Prefix",
          "description": "VM scale sets with names starting with this prefix are allowed."
        },
        "defaultValue": "aks-"
      }
    }
  }
```

## 使用方法
1. Azure Portalにログインします。
2. [ポリシー] ブレードに移動し、新しいポリシー定義を作成します。
3. 上記のポリシー定義を貼り付け、パラメーターを必要に応じて設定します。
4. ポリシーを適用するリソースグループやサブスクリプションを指定し、ポリシーの割り当てを行います。

## ライセンス
このプロジェクトは [MITライセンス](./LICENSE) の下で公開されています。

