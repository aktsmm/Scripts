## このスクリプトは、Azure Recovery Services Vaultの一覧を取得し、それぞれのVaultの名前を表示しています

## 解説
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true":

この行は、Azure PowerShellモジュールが出力する警告メッセージを抑制するためのものです。
$vaults = Get-AzRecoveryServicesVault:

Get-AzRecoveryServicesVaultコマンドレットを使用して、Azure Recovery Services Vaultの情報を取得し、それを変数$vaultsに格納しています。
foreach ($vault in $vaults) {...}:

取得したVault情報を元に、各Vaultに対して以下の処理を繰り返します。
"Recovery Services container name :" + $vault.name:

各Vaultの名前を表示します。

## 実行イメージ
![2023-12-16_21h22_16](https://github.com/aktsmm/Scripts/assets/71251920/48cc4530-a1d4-40e2-89db-71644a161505)
