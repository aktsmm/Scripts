# VM Creation Azure Policy

このフォルダには、Azure Policyを使用して仮想マシンを作成を制限するためのものが含まれています

## フォルダ構成

- `01_VMCreation/`
    - `readme.md` - このファイルです。フォルダの内容と使用方法を説明します。
    - その他のjsonファイル 

## コントリビューション

バグ報告や機能追加の提案は、GitHubのIssueを通じて行ってください。

# 各 json (Azure Policy)の仕様

## Allowed_Specific_VM.json
このAzureポリシーは、仮想マシンおよび仮想マシンスケールセットの作成や更新時に、指定された条件を満たさないリソースの操作を自動的に拒否することで、セキュリティやコンプライアンスの維持を支援します。具体的には、以下の条件を満たす場合にリソースの操作が許可されます：

### 仮想マシン（VM）の場合:
+ 許可されたイメージのパブリッシャーからのイメージを使用している。（規定値 ```RedHat```はRedHat製イメージのみを許可）
+ 許可されたカスタムイメージのリソースIDを使用している。（規定値 ```/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm```は特定のカスタムイメージを許可）
+ 許可されたイメージオファーを使用している。（規定値 ```UbuntuServer```および```microsoftsqlserver```は、一般的なLinuxおよびWindows Server向けイメージを許可）
+ OSディスクIDが特定のパターンを含んでいる。（規定値 ```-osdisk-20```は Azure Backup 向け)


### 仮想マシンスケールセット（VMSS）の場合:
+ 指定されたタグ名がリソースに存在する。（規定値 ```aks-managed-creationSource``` はAzure Kubernetes Service (AKS) で管理されるリソースを対象）


## disk_tag_Operation.json

このAzureポリシーは、管理ディスク（Managed Disks）の作成時に、指定されたタグが存在しない場合、その作成を自動的に**拒否（deny）**します。具体的には、管理ディスクにrequiredTagNameパラメーターで指定されたタグ（デフォルトは "RSVaultBackup"）が存在しない場合、ディスクの作成がブロックされます。

+ ポリシーの効果:
  タグが存在しない管理ディスクの作成を拒否します。
+ パラメーター:
requiredTagName	String	管理ディスクに存在しなければならないタグの名前。	
規定値："RSVaultBackup"(Azure Backupでリストアしたディスクに付くモノ)


## restore_specific_diskname.json
+ type が Microsoft.Compute/virtualMachines（仮想マシン）である場合にポリシーが適用される。
OSディスクの条件:

+ 仮想マシンの OS ディスク ID (Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.id) に、指定された文字列パターン（allowedDiskIdPattern）が含まれていない場合にポリシーが適用される。

+ ポリシーの効果:
  上記の条件を満たす場合、仮想マシンの作成や更新は**拒否（deny）**される。

+ デフォルト設定:
  allowedDiskIdPattern のデフォルト値は "-osdisk-20"。(Azure Backupでリストアしたディスクで含まれるモノ)


## restore_specific_Regex_imcomp.json
**未完成、正規表現マッチがうまく動作しない**
+ type が Microsoft.Compute/virtualMachines（仮想マシン）である場合にポリシーが適用される。

### OSディスク名の条件:
+ 仮想マシンのOSディスク名 (Microsoft.Compute/virtualMachines/storageProfile.osDisk.name) が、指定された正規表現パターン（osDiskNamePattern）に一致しない場合にポリシーが適用される。
ポリシーの効果:

+ 上記条件を満たす場合、仮想マシンの作成や更新は**拒否（deny）**される。
デフォルトの正規表現パターン:

+ デフォルト値は .*osdisk-\d{8}-\d{6}$。
例: osdisk-20240101-123456 の形式に一致します。

## SCREEN SHOT

以下は、ポリシー適用後のスクリーンショット例です。

### ポリシー適用結果の例 1
![ScreenShot01](./ScreenShot01.png)

### ポリシー適用結果の例 2
![ScreenShot02](./ScreenShot02.png)