## 概要
* コマンドラインで入力を受けつけてる
* Key Vaultを作成
* login name と password を作成したKey Vaultのシークレットに格納する

## 実行画面ショット
![image](https://github.com/aktsmm/Scripts/assets/71251920/412fd9e9-c463-4af0-acfd-2cfb9525cbe5)

## 作成されたリソース
![image](https://github.com/aktsmm/Scripts/assets/71251920/4befd1ff-3681-4d4f-931e-ac8e83a1b163)

## 関連
```(Get-AzKeyVault -Name $keyVaultName).ResourceId``` で作成したKey VaultのリソースIDを利用する
![image](https://github.com/aktsmm/Scripts/assets/71251920/9b2da11d-1bd1-455f-bc45-c987bc311ab7)
