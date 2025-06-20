
### 一番の注意
まず、操作対象のSubscriptionであることを確認してください
下記コマンドを用いて現在のSubscription IDが正しいか確認しましょう。
```
Get-AzContext
```
or

+ ログイン時 ```Connect-AzAccount``` を利用する際にオプション ```-Subscription (Subscription ID)``` を利用して正しい Subscription にログインしましょう。
**誤って権限のある他人の検証環境に入った状態で実行してしまうことは避けましょう!**
  ```
  Connect-AzAccount -Subscription <Subscription ID>
  ```
![image](https://github.com/aktsmm/Scripts/assets/71251920/6b8c3197-1263-4748-957a-5ca262a972ab)

参考までにAzure CLI の場合は
+ 現在のテナント、Subscription の情報を確認
```
az account show
```
+ テナント名を指定してログイン
```
az login --tenant <テナントドメイン(例:XXXXXX.onmicrosoft.com)> or <オブジェクトID> 
```
+ Subscription ID を指定してログイン
```
az account set -n <Subscription ID>
```


### その他の注意
* Azure のリソースを全消しします。
* 例えば個人の検証環境をクリーンにしたくなる時に使います。
* このコードを実行する前に、Azureアカウントに管理者アクセス権限があることを確認してください。
* 大体きれいに全消しはできないです。簡単に削除できるものを削除します。
* 残ったリソースはリソースロックや、論理削除が有効になってたりします。それらの設定を確認して変更してください。
* その他バグったリソースなどは消せないことがあります。 このコマンドはそうした削除できなくなったリソースには効果がありません。
その場合は、下記の方法を確認してください。
 • Azure PowerShellで正しい値に設定しなおす
 • Resource Explorerで正しい値に設定しなおす
 • JSONテンプレートの完全デプロイを試す

* もし、特定のリソースを削除したくない場合は、適切にコードを修正してください。
* 「-Force」オプションおよび「-Confirm:$false」オプションを使用することで、確認メッセージが表示されずにリソースが削除されます。
* これにより、誤ってリソースを削除するリスクが高まるので、注意して使用してください。
* また、上記のコードは一度に全てのリソースを削除しますが、通常はそのような大規模な削除操作は避けるべきです。必要なリソースだけを選択的に削除することをお勧めします。

## 実行途中の画面：ロックがかかってるリソースは失敗している
![image](https://github.com/aktsmm/Scripts/assets/71251920/b9c438c8-e0f0-4fde-8342-7d1428a90a58)

