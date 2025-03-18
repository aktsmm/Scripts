# Allowed_Specific_VM_re.json ReadMe
## Azure Policy: VM および VMSS イメージ制限ポリシー / Virtual Machine and Scale Set Image Restrictions

## 概要

この Azure Policy は、仮想マシン (VM) および仮想マシン スケール セット (VMSS) の作成を制限し、承認されたイメージ ソースからのみデプロイを許可します。これにより、Azure 環境で信頼できる承認済みのイメージのみが使用されることを確保し、セキュリティとコンプライアンスを維持します。

## ポリシーの詳細

このポリシーは `All` モードで動作し、割り当てられたすべてのリソース グループとサブスクリプションに適用されます。ポリシーは `deny` エフェクトを使用して、非準拠のデプロイをブロックします。

### このポリシーが制御するもの

1. **仮想マシン (VM)**: 以下の条件を満たす VM の作成のみを許可します：
   - 特定の承認済みパブリッシャー
   - 特定の承認済みカスタムイメージ（リソース ID による）
   - 特定のパターンに一致する OS ディスク（バックアップからの復元に有用）

2. **仮想マシン スケール セット (VMSS)**: 以下の条件を満たす VMSS の作成のみを許可します：
   - VMSS の名前が指定されたプレフィックスで始まる（デフォルトは "aks-"）
   - イメージが承認済みパブリッシャーからのもの

## パラメータ

| パラメータ | 種類 | 説明 | デフォルト値 |
|-----------|------|-------------|---------------|
| `listOfAllowedImagePublishers` | 配列 | 許可されたイメージパブリッシャーのリスト | `["center-for-internet-security-inc"]` |
| `listOfAllowedImagesResourceIDs` | 配列 | 許可されたカスタムイメージのリソース ID のリスト | 特定のカスタムイメージ ID |
| `allowedDiskIdPattern` | 文字列 | 許可される OS ディスクのパターン（含む） | `-osdisk-20` |
| `vmssNamePrefix` | 文字列 | 許可される VMSS 名のプレフィックス | `aks-` |

## 動作原理

### 仮想マシンの場合
以下の条件がすべて真である場合、ポリシーは VM の作成を拒否します：
- リソースが VM である
- VM のイメージパブリッシャーが許可リストにない
- VM のイメージ ID が許可されたカスタムイメージリストにない
- VM の OS ディスク ID が指定されたパターンを含まない

### 仮想マシン スケール セットの場合
以下の条件がすべて真である場合、ポリシーは VMSS の作成を拒否します：
- リソースが VMSS である
- VMSS の名前が指定されたプレフィックスで始まらない
- VMSS のイメージパブリッシャーが許可リストにない

## カスタマイズ

環境に合わせてこのポリシーをカスタマイズするには：

1. `listOfAllowedImagePublishers` を組織の信頼できるパブリッシャーを含むように変更
2. `listOfAllowedImagesResourceIDs` を組織の承認済みカスタムイメージで更新
3. 復元されたディスクに特定の命名規則がある場合は `allowedDiskIdPattern` を調整
4. VMSS リソースに異なる命名規則を使用する場合は `vmssNamePrefix` を変更

## 実装に関する注意

- 一貫した適用を確保するため、このポリシーは管理グループまたはサブスクリプション レベルで割り当てるべきです
- 本番環境にデプロイする前に、非本番環境でテストしてください
- 最初は影響を理解するために監査モードを使用し、その後、拒否モードに切り替えることを検討してください

## 関連ドキュメント

- [Azure Policy の概要](https://docs.microsoft.com/ja-jp/azure/governance/policy/overview)
- [Azure Policy サンプル](https://docs.microsoft.com/ja-jp/azure/governance/policy/samples/)
- [Azure VM イメージ](https://docs.microsoft.com/ja-jp/azure/virtual-machines/windows/image-builder-overview)

## 実装のベストプラクティス

```json:Sample Json Policy - Allowed_Specific_VM_re.json
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
          "description": "List of allowed image offers. Only images with these offers are permitted. Example: [\"UbuntuServer\", \"microsoftsqlserver\"]"
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
      "tagName": {
        "type": "String",
        "metadata": {
        "displayName": "Tag Name to Bypass Image Restrictions for VMSS",
        "description": "The tag name that must exist on a VM scale set to bypass image restrictions. The default value is intended for VM Scale Sets managed by Azure Kubernetes Service (AKS). Example: \"aks-managed-creationSource\""        },
        "defaultValue": "aks-managed-creationSource"
      },
      "allowedDiskIdPattern": {
        "type": "String",
        "metadata": {
          "displayName": "Allowed Disk ID Pattern (Contains Any Specified String)",
          "description": "Allows the creation of VMs from disks that contain any specified string.The default value is intended for disks restored by Azure VM Backup"
        },
        "defaultValue": "-osdisk-20"
      }
    }
  }
  
```

## 関連ドキュメント

- [Azure Policy の概要](https://docs.microsoft.com/ja-jp/azure/governance/policy/overview)
- [Azure Policy の定義構造](https://docs.microsoft.com/ja-jp/azure/governance/policy/concepts/definition-structure)
- [Azure VM イメージ](https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/cli-ps-findimage)
- [Azure VMSS の概要](https://docs.microsoft.com/ja-jp/azure/virtual-machine-scale-sets/overview)

