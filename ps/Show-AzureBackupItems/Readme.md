## このスクリプトは、各Azure Recovery Services Vaultに関連するAzure VMのバックアップコンテナの情報を表示するものです。各Vaultの名前と、それに関連するバックアップコンテナの情報が表示されます。

## 実行イメージ
![2023-12-16_21h19_34](https://github.com/aktsmm/Scripts/assets/71251920/c27657e8-8430-4c80-99d5-099ea75cb42e)


## 解説
以下にコマンドの各部分を解説します：

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true":

この行は、Azure PowerShellモジュールが出力する警告メッセージを抑制するためのものです。
$vaults = Get-AzRecoveryServicesVault:

Get-AzRecoveryServicesVaultコマンドレットを使用して、Azure Recovery Services Vaultの情報を取得し、それを変数$vaultsに格納しています。
"------":

区切り線を表示するための文字列です。
foreach ($vault in $vaults) {...}:

取得したVault情報を元に、各Vaultに対して以下の処理を繰り返します。
"Recovery Services container name :" + $vault.name:

各Vaultの名前を表示します。
$backupItem = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -VaultId $vault.ID:

Get-AzRecoveryServicesBackupContainerコマンドレットを使用して、指定したVaultに関連するバックアップコンテナの情報を取得し、それを変数$backupItemに格納しています。このコマンドでは、バックアップコンテナのタイプが "AzureVM" に制限されています。
if($null -ne $backupItem) {...}:

バックアップコンテナが存在する場合、その情報を表示します。存在しない場合は "None" と表示します。
"------":

サイクルごとの区切り線を表示します。