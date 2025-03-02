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
CSVを開く既定アプリケーション

+ Windows で CSV ファイルの関連付けが Excel になっていれば、停止後に Excel で自動表示されます。


## ソース

```Powershell
<#
.SYNOPSIS
  指定ホストに3秒おきにpingし、10秒以内に応答がなければ TIMEOUT として記録。
  EnterキーまたはCtrl + Cで停止。

.DESCRIPTION
  - 変数 $PingInterval = 3 により、3秒おきに Ping
  - 変数 $PingTimeout = 10 により、Ping応答が10秒以内に得られなければ TIMEOUT
  - 応答が得られた場合は従来通り Status=Success
  - ループ終了後にCSVファイルを開く

.PARAMETER TargetHost
  ping先 (FQDN or IP)

.EXAMPLE
  .\ping_logger_lite.ps1 -TargetHost 8.8.8.8
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$TargetHost
)

# ========== 設定変数 ==========
# 3秒おきにPing
$PingInterval = 3
# 10秒以内に応答がなければ TIMEOUT
$PingTimeout  = 10

# CSV ファイル名: <Host>_ping_<yyyyMMddHHmm>.csv
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$CsvPath   = ".\\${TargetHost}_ping_${timestamp}.csv"

Write-Host "===================================================="
Write-Host " Ping to $TargetHost every $PingInterval sec"
Write-Host " Timeout if no response in $PingTimeout sec → $PingTimeout Sec TIMEOUT"
Write-Host " CSV Output: $CsvPath"
Write-Host " [Enter] or [Ctrl + C] to stop"
Write-Host "===================================================="

# 1) CSVヘッダの列名を定義
$columns = 'TimeStamp','Ping','Source','Destination','Address','DisplayAddress','Latency','Status','BufferSize'

# 2) ファイルがなければヘッダ行を作成
if (!(Test-Path $CsvPath)) {
    $columns -join ',' | Out-File $CsvPath
}

$stop = $false
while (-not $stop) {
    # Enterキーでループ終了
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) {
            Write-Host "Stopping via Enter key..."
            $stop = $true
            break
        }
    }

    # ==============================
    # Ping (Test-Connection) 実行
    # ==============================
    # -Count 1 : 単発
    # -Timeout <秒>: 応答がなければ TIMEOUT 扱い
    #   → 古いバージョンのPowerShellだと -Timeout パラメータがない場合も。要注意。
    #   → なければ代替策で Measure-Command 等を使う方法もあり。
    $pingResult = Test-Connection -ComputerName $TargetHost -Count 1 -Timeout $PingTimeout -ErrorAction SilentlyContinue

    # 初期値
    $pingVal        = ''
    $source         = ''
    $destination    = $TargetHost
    $address        = ''
    $displayAddress = ''
    $latency        = ''
    $status         = "$PingTimeout Sec TIMEOUT"# 先にTIMEOUTとし、応答があったら上書き
    $bufferSize     = ''

    if ($pingResult) {
        # 応答があった場合
        $reply = $pingResult[0]
        $pingVal        = $reply.Ping
        $source         = $reply.Source
        $destination    = $reply.Destination
        $address        = $reply.Address
        $displayAddress = $reply.DisplayAddress
        $latency        = $reply.Latency
        $status         = $reply.Status  # 通常 'Success'
        $bufferSize     = $reply.BufferSize
    }

    # タイムスタンプ (秒単位)
    $timeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    # CSV用の1行を組み立て
    $csvLine = @(
        $timeStamp,
        $pingVal,
        $source,
        $destination,
        $address,
        $displayAddress,
        $latency,
        $status,
        $bufferSize
    ) -join ','

    # ログに追記
    Add-Content -Path $CsvPath -Value $csvLine

    # === 指定した間隔で待機 (3秒) ===
    Start-Sleep -Seconds $PingInterval
}

Write-Host "Logging finished."
Write-Host "Check result file: $CsvPath"
Write-Host "Opening CSV..."

Invoke-Item $CsvPath
Write-Host "Done."

```