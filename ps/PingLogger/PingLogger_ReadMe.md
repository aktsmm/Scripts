### README: Ping ロガー（タイムアウト付き）
## 概要
この PowerShell スクリプトは、指定したホストに 3 秒ごとに ping を実行し、10 秒以内に応答がなければ「TIMEOUT」 としてログに記録します。Enterキー または Ctrl + C でいつでも停止可能です。停止後は、自動的に CSV ファイルを既定アプリケーション（通常は Excel）で開き、結果をすぐに確認できます。

## 特徴
+ インターバル・タイムアウトのカスタマイズ
PingInterval で ping の間隔 を設定（初期値 3 秒）
PingTimeout で 応答待ちの上限 を設定（初期値 10 秒）

+ Enter で停止 → ログを開く
Enterキー を押すと、スクリプトは優雅に終了し、CSVを自動で開きます。
Ctrl + C でも停止可能ですが、スクリプトが強制終了するため CSV は自動的に開かれません。
CSV への記録

+ <ホスト>_ping_<YYYYMMDDHHmm>.csv というファイル名で、下記の列を順序固定で出力します。
TimeStamp
Ping
Source
Destination
Address
DisplayAddress
Latency
Status
BufferSize
タイムアウト時のステータス は "<PingTimeout> Sec TIMEOUT" として記録されます。
応答があった場合は通常 Success などのステータスが入ります。
Enter にて スクリプト終了後に CSV を自動オープン

ログ採取後、Invoke-Item で CSV を開く → Windows では通常 Excel が関連付けられているため、すぐに結果を閲覧できます。

## 使い方
### スクリプトを実行
```.\ping_logger_lite.ps1 -TargetHost 8.8.8.8```
TargetHost には IP または ホスト名を指定してください。

### 設定を変更
スクリプト上部で以下の変数を変更できます：
```$PingInterval = 3  # Ping の間隔（秒）```
```$PingTimeout  = 10 # タイムアウト（秒）```
たとえば、5秒おきに送って15秒以内に応答がなければTIMEOUTという設定にしたい場合、上記2値を書き換えます。

### 停止方法
+ Enterキー → ログ採取を完了し CSV を開く
+ Ctrl + C → スクリプト強制終了（ログは書かれるが CSV は自動で開かない）

## 前提条件
+ Windows PowerShell 5.1 以上が望ましい
Test-Connection に -Timeout パラメータを使用するため。
古いバージョンでは -Timeout が存在せず、別の方法でタイムアウト制御が必要になる場合があります。
+ Windows で CSV ファイルの関連付けが Excel になっていれば、停止後に Excel で自動表示されます。(Enter終了した場合)


## ソース

```Powershell
<#
.SYNOPSIS
  指定したホストに3秒ごとにPingを実行し、10秒以内に応答がない場合はTIMEOUTとして記録します。
  Enterキーまたは Ctrl + C で停止します。

.PARAMETER TargetHost
  Pingを実行する対象のホスト (FQDN または IP)

.EXAMPLE
  .\PingLogger.ps1 -TargetHost 8.8.8.8
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$TargetHost
)

# ========== 設定 ==========
$PingInterval = 3     # Pingの間隔（秒）
$PingTimeout  = 10    # 応答がない場合にTIMEOUTとする時間（秒）

# CSVファイルのパス
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$CsvPath   = ".\\${TargetHost}_ping_${timestamp}.csv"

Write-Host "===================================================="
Write-Host " $TargetHost へのPingを $PingInterval 秒ごとに実行"
Write-Host " 応答が $PingTimeout 秒以内にない場合はTIMEOUTとして記録"
Write-Host " CSV出力ファイル: $CsvPath"
Write-Host " [Enter]キーまたは [Ctrl + C] で停止"
Write-Host "===================================================="

# CSVのヘッダーを定義
$columns = 'タイムスタンプ','Ping','送信元','送信先','アドレス','表示アドレス','遅延時間','ステータス','バッファサイズ'
if (!(Test-Path $CsvPath)) {
    $columns -join ',' | Out-File $CsvPath
}

$stop = $false
while (-not $stop) {
    # Enterキーでループを停止
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) {
            Write-Host "Enterキーが押されたため停止します..."
            $stop = $true
            break
        }
    }

    # Ping実行
    $pingResult = $null
    $errMsg = $null
    $responseTime = (Measure-Command {
        $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -TimeoutSeconds $PingTimeout -ErrorAction SilentlyContinue -ErrorVariable errMsg
    }).TotalMilliseconds

    # 初期値
    $pingVal        = ''
    $source         = ''
    $destination    = $TargetHost
    $address        = ''
    $displayAddress = ''
    $latency        = ''
    $status         = "TIMEOUT ($PingTimeout 秒)"
    $bufferSize     = ''

    if ($pingResult) {
        $reply = $pingResult[0]
        $pingVal        = $reply.Ping
        $source         = $reply.Source
        $destination    = $reply.Destination
        $address        = $reply.Address
        $displayAddress = $reply.DisplayAddress
        $latency        = $reply.Latency
        $status         = $reply.Status
        $bufferSize     = $reply.BufferSize
    } elseif ($errMsg) {
        $status = "TIMEOUT (エラー: $errMsg)"
    }

    # タイムスタンプ
    $timeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    # CSV行を作成
    $csvRow = [PSCustomObject]@{
        タイムスタンプ  = $timeStamp
        Ping           = $pingVal
        送信元         = $source
        送信先         = $destination
        アドレス       = $address
        表示アドレス   = $displayAddress
        遅延時間       = $latency
        ステータス     = $status
        バッファサイズ = $bufferSize
    }
    $csvRow | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Add-Content -Path $CsvPath

    # 次のPingまで待機
    Start-Sleep -Seconds $PingInterval
}

Write-Host "ログ記録を終了しました。"
Write-Host "結果ファイル: $CsvPath"
Write-Host "CSVファイルを開きます..."

Invoke-Item $CsvPath
Write-Host "完了しました。"
```