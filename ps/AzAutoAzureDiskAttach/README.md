# AutoAzureDiskAttach

このスクリプト「AutoAzureDiskAttach」は、対象のAzure VMから実行し、Azure PowerShellとマネージドIDを利用して、指定されたLUN番号でディスクをアタッチし、必要に応じてドライブレターを割り当てるためのものです。スクリプトは、適切な権限が付与されていることを前提としています。

## 変数の説明

- `$resourceGroupName`: ディスクとVMが存在するリソースグループの名前
- `$vmName`: ディスクをアタッチする対象のVMの名前
- `$diskName`: アタッチするディスクの名前
- `$location`: ディスクのリージョン（例: "JapanEast"）
- `$lun`: ディスクをアタッチするLUN（論理ユニット番号）
- `$dletter`: 割り当てるドライブレター（例: "E"）
- `$tenantId`: Azure AD テナント ID
- `$subscriptionId`: Azure サブスクリプション ID

## スクリプトの説明

1. **変数設定**: スクリプトの実行に必要な変数を設定します。
2. **ログファイルのパス設定**: 現在のタイムスタンプに基づいてログファイルのパスを設定します。
3. **ログ関数の定義**: ログメッセージを書き込む関数 `Write-Log` を定義します。
4. **Azureへの接続**: マネージドIDを使ってAzureに接続し、ログに接続状況を記録します。
5. **サブスクリプションの設定**: 指定したサブスクリプションIDとテナントIDでAzureサブスクリプションのコンテキストを設定し、ログに設定状況を記録します。
6. **ディスクのアタッチ**: 
   - **VMとディスクの情報取得**: `Get-AzVM` と `Get-AzDisk` コマンドレットを使用して、指定したVMとディスクの情報を取得します。
   - **LUNの確認**: 指定されたLUN番号がすでに使用されているか確認します。すでにディスクがアタッチされている場合、メッセージをログに記録し、処理を終了します。
   - **ディスクのアタッチ**: LUNが使用されていない場合、`Add-AzVMDataDisk` コマンドレットを使ってディスクをVMにアタッチします。
7. **VM設定の更新**: ディスクアタッチ後に `Update-AzVM` コマンドレットを使用してVMの設定を更新し、ログに更新状況を記録します。
8. **ディスクのドライブレター割り当て**:
   - **オフラインディスクの取得**: `Get-Disk` コマンドレットを使って、オフラインかつRAWパーティションスタイルでないディスクを取得します。該当するディスクがない場合、エラーメッセージを出力してスクリプトを終了します。
   - **ディスクの設定変更**: 取得したディスクがオフラインであれば、`Set-Disk` コマンドレットを使ってディスクをオンラインにし、読み取り専用属性を解除します。
   - **パーティションのドライブレター割り当て**: `Get-Partition` コマンドレットでドライブレターが割り当てられていないパーティションを取得し、`Set-Partition` コマンドレットでドライブレターを割り当てます。
   
## 実行方法

1. スクリプト内の変数を適切な値に設定します。
2. Azure VMからスクリプトを実行します。


# AutoAzureDiskAttach

The script "AutoAzureDiskAttach" is designed to be executed from an Azure VM using Azure PowerShell and a managed identity. It attaches a disk to the VM at a specified LUN and assigns a drive letter if needed. The script assumes that the necessary permissions are already granted.

## Variable Descriptions

- `$resourceGroupName`: Name of the resource group where the disk and VM exist
- `$vmName`: Name of the VM to which the disk will be attached
- `$diskName`: Name of the disk to attach
- `$location`: Region of the disk (e.g., "JapanEast")
- `$lun`: LUN (Logical Unit Number) where the disk will be attached
- `$dletter`: Drive letter to assign (e.g., "E")
- `$tenantId`: Azure AD Tenant ID
- `$subscriptionId`: Azure Subscription ID

## Script Description

1. **Variable Setting**: Set the necessary variables for script execution.
2. **Log File Path Setting**: Define the log file path based on the current timestamp.
3. **Log Function Definition**: Define a function `Write-Log` to write log messages.
4. **Connect to Azure**: Connect to Azure using the managed identity and log the connection status.
5. **Set Subscription Context**: Set the Azure subscription context with the specified Subscription ID and Tenant ID and log the context setting.
6. **Attach Disk**: 
   - **Retrieve VM and Disk Information**: Use `Get-AzVM` and `Get-AzDisk` cmdlets to retrieve the specified VM and disk information.
   - **Check LUN**: Verify if the specified LUN number is already in use. If a disk is already attached at that LUN, log the message and terminate the script.
   - **Attach Disk**: If the LUN is available, use `Add-AzVMDataDisk` cmdlet to attach the disk to the VM.
7. **Update VM Configuration**: After attaching the disk, use `Update-AzVM` cmdlet to update the VM configuration and log the update status.
8. **Assign Drive Letter**:
   - **Retrieve Offline Disks**: Use `Get-Disk` cmdlet to retrieve offline disks that are not RAW partition style. If no such disks are found, output an error message and terminate the script.
   - **Change Disk Settings**: If an offline disk is found, use `Set-Disk` cmdlet to bring the disk online and remove the read-only attribute.
   - **Assign Drive Letter to Partition**: Use `Get-Partition` cmdlet to get partitions without a drive letter and `Set-Partition` cmdlet to assign the specified drive letter.
   
## Execution

1. Configure the script variables with appropriate values.
2. Execute the script from the Azure VM.
