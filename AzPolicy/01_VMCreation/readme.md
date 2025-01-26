# VM Creation Azure Policy

このフォルダには、Azure Policyを使用して仮想マシンを作成を制限するためのものが含まれています

## フォルダ構成

- `01_VMCreation/`
    - `readme.md` - このファイルです。フォルダの内容と使用方法を説明します。
    - その他のjsonファイル 

## コントリビューション

バグ報告や機能追加の提案は、GitHubのIssueを通じて行ってください。プルリクエストも歓迎します。

# 各 json (Azure Policy)の仕様

## restore_specific_Regex_imcomp.json

- **目的**: 特定の正規表現パターンに一致しないOSディスク名を持つVMの作成を禁止します。
- **主なフィールド**:
  - `osDiskNamePattern`: 許可されたOSディスク名の正規表現パターンを定義します。
  - `policyRule`: ポリシーのルールを定義します。OSディスク名が正規表現パターンに一致しない場合にVMの作成を禁止します。
- **デフォルトバリュー**:
  - `osDiskNamePattern`: `.*osdisk-\\d{8}-\\d{6}$`

### 動作例
このファイルは、OSディスク名が特定の正規表現パターンに一致しない場合にVMの作成を禁止するポリシーを定義する場合に使用されます。

## policyDefinition.json

- **目的**: Azure Policyの定義を記述します。
- **主なフィールド**:
  - `policyRule`: ポリシーのルールを定義します。リソースが特定の条件を満たすかどうかを評価します。
  - `parameters`: ポリシーのパラメータを定義します。ポリシーの動作をカスタマイズするために使用されます。
- **デフォルトバリュー**:
  - `listOfAllowedImagePublishers`: `["RedHat"]`
  - `listOfAllowedImageOffers`: `["UbuntuServer", "microsoftsqlserver"]`
  - `listOfAllowedImagesResourceIDs`: `["/subscriptions/XXXXXXXXXXX/resourceGroups/rg-test/providers/Microsoft.Compute/images/image-from-vm"]`
  - `tagName`: `"aks-managed-creationSource"`
  - `allowedDiskIdPattern`: `"-osdisk-20"`

### 動作例
このファイルは、特定の条件を満たさないVMやVMSSの作成を禁止するポリシーを定義する場合に使用されます。

## managed_disk_tag_policy.json

- **目的**: 特定のタグが存在しないマネージドディスクの作成を禁止します。
- **主なフィールド**:
  - `requiredTagName`: 必須のタグ名を定義します。
  - `policyRule`: ポリシーのルールを定義します。タグが存在しない場合にマネージドディスクの作成を禁止します。
- **デフォルトバリュー**:
  - `requiredTagName`: `"RSVaultBackup"`

### 動作例
このファイルは、特定のタグが存在しないマネージドディスクの作成を禁止するポリシーを定義する場合に使用されます。

## vm_disk_id_policy.json

- **目的**: 特定のディスクIDパターンに一致しないディスクを持つVMの作成を禁止します。
- **主なフィールド**:
  - `allowedDiskIdPattern`: 許可されたディスクIDパターンを定義します。
  - `policyRule`: ポリシーのルールを定義します。ディスクIDがパターンに一致しない場合にVMの作成を禁止します。
- **デフォルトバリュー**:
  - `allowedDiskIdPattern`: `"-osdisk-20"`

### 動作例
このファイルは、ディスクIDが特定のパターンに一致しない場合にVMの作成を禁止するポリシーを定義する場合に使用されます。

