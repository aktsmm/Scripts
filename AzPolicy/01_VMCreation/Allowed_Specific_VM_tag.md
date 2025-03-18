# Allowed_Specific_VM_tag.json

## 概要

このポリシーは、Azure環境において、仮想マシン（VM）および仮想マシンスケールセット（VMSS）の作成時に使用できるイメージを制限するためのものです。

VMの場合は、許可されたイメージのパブリッシャー、カスタムイメージ、または特定のディスクIDパターンに一致する場合のみ作成を許可します。

VMSSの場合は、特定のタグが設定されている場合のみ作成を許可します。

---

## Allowed_Specific_VM.jsonとの違い

| 項目                           | Allowed_Specific_VM.json               | Allowed_Specific_VM_tag.json（本ポリシー） |
|--------------------------------|----------------------------------------|---------------------------------------------|
| VMの制限方法                    | パブリッシャー、オファー名、イメージID、ディスクID | パブリッシャー、カスタムイメージID、ディスクIDパターン（オファー名の制限なし） |
| VMSSの制限方法                  | 特定のタグが存在する場合は制限を回避できる | 特定のタグが**存在しない場合に作成を拒否**   |

- **Allowed_Specific_VM_tag.jsonは、「特定のタグがないとVMSSが作成できない」という点が特徴です。**
- Allowed_Specific_VM.json は、「指定タグが存在すれば、イメージの制限を回避できる」という許可型です。

---

## パラメータ説明

| パラメータ                     | 説明                                         | 例 |
|--------------------------------|---------------------------------------------|--------------------------------------------------------|
| `listOfAllowedImagePublishers` | 許可されたイメージ発行元のリストです。      | ` ["UbuntuServer","microsoftsqlserver"]`         |
| `listOfAllowedImagesResourceIDs` | 許可されたカスタムイメージのリソースID。   | `["/subscriptions/xxxxxx/resourceGroups/rg/providers/..."]` |
| `tagName`                      | VMSSが作成される際に必須となるタグ名です。  | `"aks-managed-creationSource"`                 |
| `allowedDiskIdPattern`         | 許可されたディスクIDに含まれる文字列。      | `"-osdisk-20"`                                 |

---

## 想定されるユースケース

- セキュリティ要件に基づいて、特定のパブリッシャーまたはカスタムイメージの使用のみを許可したい場合
- VMSSを管理・監視する目的で特定のタグを強制したい場合（例：AKSなど）

---

以上が、本ポリシー（Allowed_Specific_VM_tag.json）の概要とポイントの解説です。
内容をご確認の上、ご活用ください。

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
          "description": "List of allowed image publishers. Only images from these publishers are permitted. Example: [\"center-for-internet-security-inc\"]"
        },
        "defaultValue": [
            "UbuntuServer",
            "microsoftsqlserver"
          ]
      },
      "listOfAllowedImagesResourceIDs": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed Images Resource IDs for Custom Images",
          "description": "List of allowed custom image resource IDs. Only these custom images are permitted. Example: [\"/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm\"]"
        },
        "defaultValue": [
            "/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm"
          ]
      },
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name to Bypass Image Restrictions for VMSS",
          "description": "The tag name that must exist on a VM scale set to bypass image restrictions. The default value is intended for VM Scale Sets managed by Azure Kubernetes Service (AKS). Example: \"aks-managed-creationSource\""
        },
        "defaultValue": "aks-managed-creationSource"
      },
      "allowedDiskIdPattern": {
        "type": "String",
        "metadata": {
          "displayName": "Allowed Disk ID Pattern (Contains Any Specified String)",
          "description": "Allows the creation of VMs from disks that contain any specified string. The default value is intended for disks restored by Azure VM Backup"
        },
        "defaultValue": "-osdisk-20"
      }
    }
  }
```