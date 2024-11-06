# このスクリプトは、Azure PowerShellを使用してService PrincipalでAzureにログインし、デバッグ出力やログ情報をファイルおよびイベントログに記録する手順を示しています。
# 主な処理内容:
# 1. デバッグログの保存:
#    - 現在の日時を使用してログファイル名を設定し、`Start-Transcript` コマンドでデバッグ出力を `$debug_LOG_PATH` に記録します。
# 2. イベントログのソース登録:
#    - 「Application」ログに「TestScript」ソースが存在しない場合、管理者権限で作成します。
# 3. Service Principalの情報を変数に代入:
#    - クライアントID、テナントID、シークレットを使用して、Service Principalの認証情報を設定します。
# 4. Service PrincipalでAzureにログイン:
#    - `Connect-AzAccount` コマンドを使用してService PrincipalでAzureにログインします。`-Confirm:$false`オプションで確認プロンプトをスキップし、`-Debug` オプションでデバッグ情報を表示・保存します。
# 5. イベントログへのメッセージ書き込み:
#    - ログイン成功後、Applicationイベントログに「Azureへ接続します。」のメッセージを情報レベルで記録します。
# 6. デバッグログの終了:
#    - `Stop-Transcript` コマンドでデバッグ出力の保存を終了します。

#########################

# 日時を取得してファイル名を設定
$timestamp = (Get-Date -Format "yyMMddHHmmss")
$debug_LOG_PATH = "D:\99_temp\02_log\debug.Message_$timestamp.log"  # ログファイルのフルパスを指定

# Debug出力をキャプチャしてファイルに保存
Start-Transcript -Path $debug_LOG_PATH -Append

# イベントログ書き込み
# 管理者権限で実行し、イベントログソースを作成（「TestScript」ソースが存在しない場合のみ）
if (-not [System.Diagnostics.EventLog]::SourceExists("TestScript")) {
    New-EventLog -LogName "Application" -Source "TestScript"  # ソース名「TestScript」をApplicationログに作成
}

# Service Principal情報を変数に代入
$ClientId = "XXXXXXca-0d40-4a4e-XXXX-XXXX17eeb6b46"          # クライアントID (AppId)
$TenantId = "XXXXfd90b-XXXX-42d0-XXXX-41f9e1ba23f3"          # テナントID
$ClientSecret = "RHXXQ~CAHEOBqXXXXXXwKTr-XXXXwruXXXXpbRD"    # シークレット（パスワード）

# クライアントシークレットをセキュアな形式に変換（安全に取り扱うため）
$SecurePassword = ConvertTo-SecureString $ClientSecret -AsPlainText -Force

# Service Principalの資格情報を設定
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecurePassword

# Service PrincipalでAzureにログイン
# -ServicePrincipal: Service Principalを利用してログインするための指定
# -Tenant: ログインするテナントIDを指定
# -Credential: Service Principalの資格情報（クライアントIDとシークレット）を指定
# -Confirm:$false: 確認プロンプトをスキップして実行
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Credential -Confirm:$false -Debug | Out-Null

# イベントログにメッセージを書き込み（管理者権限で実行しないとエラーが発生する可能性がある）
Write-EventLog -LogName "Application" -Source "TestScript" -EventID 65535 -EntryType Information -Message "Azureへ接続します。"

# Debugメッセージの保存を終了
Stop-Transcript
