
<#
========================================================================
 PowerShell Script: Setup_IIS_Debug_Env.ps1
 Windows Server 2019+ / PowerShell 5.1 専用

 ◉ 自動セットアップ項目:
    - IIS + Classic ASP + HTTPS 対応 + 自己署名証明書
    - IIS ログにカスタムヘッダー情報を出力 (W3C + customFields)
    - IE ESC 無効化（管理者/ユーザー）
    - ファイアウォール自動開放 (HTTP/HTTPS/RDP)
    - index.asp による全ヘッダー情報＋ClientIP＋デプロイ毎固定の SN(8桁ハッシュ)
      ・Accept: application/json または ?format=json で JSON 出力
========================================================================
#>

# ========================
# 0. エラー即停止 & 初期設定
# ========================
$ErrorActionPreference = "Stop"
$SiteName    = "Default Web Site"
$WebRoot     = "C:\inetpub\wwwroot"
$CertSubject = "CN=localhost"

## Error Message 表示設定

Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/httpErrors" -name errorMode -value "Detailed"

Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/asp" -name "scriptErrorSentToBrowser" -value "True"

Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/asp" -name "scriptErrorMessage" -value "ASP Error"


# ========================
# 1. IIS 機能インストール
# ========================
Write-Host "▶ 1. Installing IIS features..." -ForegroundColor Cyan
if (-not (Get-WindowsFeature Web-Server).Installed) {
    Install-WindowsFeature -Name Web-Server,Web-ASP -IncludeManagementTools
}

# ========================
# 2. 不要ファイル初期化
# ========================
Write-Host "▶ 2. Cleaning default files..." -ForegroundColor Cyan
Get-ChildItem -Path $WebRoot -Exclude "web.config" |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# ========================
# 3. 自己署名証明書の作成
# ========================
Write-Host "▶ 3. Creating self-signed certificate..." -ForegroundColor Cyan
$existingCert = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -eq $CertSubject }
if ($existingCert) { $existingCert | Remove-Item }
$cert = New-SelfSignedCertificate -DnsName "localhost" `
    -CertStoreLocation "Cert:\LocalMachine\My"

# ========================
# 4. IIS バインディング構成
# ========================
Write-Host "▶ 4. Configuring IIS bindings..." -ForegroundColor Cyan
Import-Module WebAdministration
if (-not (Get-Website | Where-Object { $_.Name -eq $SiteName })) {
    New-Website -Name $SiteName -Port 80 -PhysicalPath $WebRoot -Force
}
# HTTPS バインド再作成
if (Get-WebBinding -Name $SiteName -Protocol https -ErrorAction SilentlyContinue) {
    Remove-WebBinding -Name $SiteName -Protocol https
}
New-WebBinding -Name $SiteName -Protocol https -Port 443 -IPAddress "*"
$bindingPath = "IIS:\SslBindings\0.0.0.0!443"
if (Test-Path $bindingPath) { Remove-Item $bindingPath }
New-Item $bindingPath -Thumbprint $cert.Thumbprint -SSLFlags 0

# ========================
# 5. IIS ログ カスタムフィールド設定（改良版）
# ========================
Write-Host "▶ 5. Configuring IIS log custom fields..." -ForegroundColor Cyan

# (A) W3C ログ形式に設定
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.applicationHost/sites/site[@name='$SiteName']/logFile" `
  -name "logFormat" -value "W3C"

# (B) 既存の customFields をすべてクリア
Clear-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.applicationHost/sites/site[@name='$SiteName']/logFile/customFields"

# (C) 追加するカスタムフィールド定義
$customFields = @(
  @{ logFieldName="ServerAddr";       sourceName="LOCAL_ADDR";        sourceType="ServerVariable" },
  @{ logFieldName="Hostname";         sourceName="SERVER_NAME";       sourceType="ServerVariable" },
  @{ logFieldName="RemoteAddr";       sourceName="REMOTE_ADDR";       sourceType="ServerVariable" },
  @{ logFieldName="X-Forwarded-For";  sourceName="X-Forwarded-For";   sourceType="RequestHeader"   },
  @{ logFieldName="X-Real-IP";        sourceName="X-Real-IP";         sourceType="RequestHeader"   },
  @{ logFieldName="HostHeader";       sourceName="Host";              sourceType="RequestHeader"   },
  @{ logFieldName="UserAgent";        sourceName="User-Agent";        sourceType="RequestHeader"   },
  @{ logFieldName="Referer";          sourceName="Referer";           sourceType="RequestHeader"   }
)

foreach ($f in $customFields) {
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
      -filter "system.applicationHost/sites/site[@name='$SiteName']/logFile/customFields" `
      -name "." -value $f
}


# ========================
# 6. デプロイ毎固定の 8 桁ハッシュ SN 生成
# ========================
Add-Type -AssemblyName System.Security
$guid  = [System.Guid]::NewGuid().ToString("N")
$md5   = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($guid)
$hash  = (
    $md5.ComputeHash($bytes) |
    ForEach-Object { $_.ToString("x2") }
) -join ""
$SN    = $hash.Substring(0,8)

# ========================
# 7. index.asp の生成（SN 埋め込み＋JSON/HTML 切り替え）
# ========================
Write-Host "▶ 7. Creating index.asp for header info (SN=$SN)..." -ForegroundColor Cyan
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$FQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

$asp = @"
<%@ Language="VBScript" CodePage="65001" %>
<% 
  Response.CodePage = 65001
  Response.CharSet  = "utf-8"

  ' Begin JSON/HTML toggling logic
  Dim wantJson: wantJson = False
  If LCase(Request.QueryString("format")) = "json" Then wantJson = True
  If InStr(Request.ServerVariables("HTTP_ACCEPT"), "application/json") > 0 Then wantJson = True

  ' Fetch public IP from ipify
  Dim xmlhttp, jsonText, ipPos, globalIP
On Error Resume Next
Set xmlhttp = Server.CreateObject("MSXML2.ServerXMLHTTP")
xmlhttp.open "GET", "https://api.ipify.org?format=json", False
xmlhttp.send
If Err.Number <> 0 Then
  globalIP = "Unable to access api.ipify.org"
  Err.Clear
Else
  jsonText = xmlhttp.responseText
  ipPos = InStr(jsonText, """ip"":""")
  If ipPos > 0 Then
    globalIP = Mid(jsonText, ipPos + 6, InStr(ipPos + 6, jsonText, """") - (ipPos + 6))
  Else
    globalIP = "N/A"
  End If
End If
On Error GoTo 0


  If wantJson Then
    Response.ContentType = "application/json"
    Dim json
  json = "{"
  json = json & """HostnameFQDN"":""" & "$FQDN" & """," ' ①
  json = json & """ServerAddrPrivateIP"":""" & Request.ServerVariables("LOCAL_ADDR") & """," ' ②
  json = json & """ServerAddrPublicIP"":""" & globalIP & """," ' ③
  json = json & """RemoteAddr"":""" & Request.ServerVariables("REMOTE_ADDR") & """," ' ④
  json = json & """ClientIP"":""" & Request.ServerVariables("HTTP_X_REAL_IP") & """," ' ⑤
  json = json & """X-Forwarded-For"":""" & Request.ServerVariables("HTTP_X_FORWARDED_FOR") & """," ' ⑥
  json = json & """X-Real-IP"":""" & Request.ServerVariables("HTTP_X_REAL_IP") & """," ' ⑦
  json = json & """Host"":""" & Request.ServerVariables("HTTP_HOST") & """," ' ⑧
  json = json & """UserAgent"":""" & Request.ServerVariables("HTTP_USER_AGENT") & """," ' ⑨
  json = json & """Referer"":""" & Request.ServerVariables("HTTP_REFERER") & """" ' ⑩
  json = json & "}"

    Response.Write json
  Else
    Response.ContentType = "text/html"
    Dim o, titleChars, colors, i, colorCount
    titleChars = Array("I","I","S"," ","D","e","b","u","g"," ","P","o","r","t","a","l")
    colors     = Array("red","orange","green","blue","indigo","violet")
    colorCount = UBound(colors) + 1

    '---- HTML Header ----
    o = "<!DOCTYPE html><html lang='ja'><head><meta charset='UTF-8'><title>IIS Debug Portal</title>"
    o = o & "<style>body{font-family:'Segoe UI',sans-serif;background:#f8f8f8;padding:2em;}h1{font-size:2em;margin-bottom:0.5em;}pre{background:#fff;padding:1em;border:1px solid #ccc;white-space:pre-wrap;}dl{background:#fff;padding:1em;border:1px solid #ccc;}dt{font-weight:bold;}dd{margin:0 0 1em 1em;}</style>"
    o = o & "</head><body><h1>"
    For i = 0 To UBound(titleChars)
        If titleChars(i) = " " Then
            o = o & "&nbsp;"
        Else
            o = o & "<span style='color:" & colors(i Mod colorCount) & ";'>" & titleChars(i) & "</span>"
        End If
    Next
    o = o & "</h1>"

    '---- Serial & Headers ----
    o = o & "<p>Serial Number: <strong>$SN</strong></p>"
    o = o & "<p>Server & Connection Info</p><pre>"
    o = o & "HostnameFQDN                          :" & "$FQDN" & vbCrLf
    o = o & "ServerAddrPrivateIP                   :" & Request.ServerVariables("LOCAL_ADDR") & vbCrLf
    o = o & "ServerAddrPublicIP (*api.ipify.org)   :" & globalIP                      & vbCrLf
    o = o & "RemoteAddr(Your IP from IP Layer)     :" & Request.ServerVariables("REMOTE_ADDR") & vbCrLf
     o = o & "</pre>"

    o = o & "<p>HTTP Headers</p><pre>"
    o = o & "X-Forwarded-For    :" & Request.ServerVariables("HTTP_X_FORWARDED_FOR") & vbCrLf
    o = o & "X-Real-IP          :" & Request.ServerVariables("HTTP_X_REAL_IP") & vbCrLf
    o = o & "Host Header        :" & Request.ServerVariables("HTTP_HOST") & vbCrLf
    o = o & "User-Agent         :" & Request.ServerVariables("HTTP_USER_AGENT") & vbCrLf
    o = o & "Referer            :" & Request.ServerVariables("HTTP_REFERER") & vbCrLf
    o = o & "</pre>"

   '---- JSON Retrieval Instructions ----
    hostName = Request.ServerVariables("HTTP_HOST")
    o = o & "<hr><h2>JSON 出力の取得方法 / JSON Retrieval Methods</h2>"
    o = o & "<p>以下のいずれかの方法で JSON 出力が取得できます。<br>You can obtain the JSON response by one of the following:</p><ul>"
    o = o & "<li><code>curl -H ""Accept: application/json"" https://" & hostName & "/</code></li>"
    o = o & "<li><code>Invoke-RestMethod -Uri 'https://" & hostName & "/?format=json'</code></li>"
    o = o & "<li>ブラウザで<a href='/?format=json' target='_blank'>https://" & hostName & "/?format=json</a> を確認</li>"
    o = o & "</ul>"


    '---- Header Descriptions ----
    o = o & "<hr><h2>Header Descriptions</h2><dl>"
    o = o & "<dt>ServerAddrPrivate</dt><dd>サーバーが受信したリクエストのローカルIPアドレス。通常はNICに割り当てられたプライベートIPです。<br>Private IP address of the server that received the request</dd>"
    o = o & "<dt>ServerAddrPublicIP</dt><dd>api.ipify.org によって取得されたグローバルIPアドレス。<br>Public IP address retrieved from api.ipify.org</dd>"
    o = o & "<dt>Hostname</dt><dd>SERVER_NAME の値。通常は Host ヘッダーまたはIISのバインディング設定に基づきます。<br>The value of SERVER_NAME, usually based on the Host header or binding configuration</dd>"
    o = o & "<dt>RemoteAddr</dt><dd>サーバー側が認識するクライアントの送信元IPアドレス。<br>Client IP address as seen by the server</dd>"
    o = o & "<dt>X-Forwarded-For</dt><dd>プロキシを通過したクライアントIPのカンマ区切りリスト。左端がオリジナルのクライアントIP。<br>Comma-separated list of IPs through proxy chain (leftmost is original client)</dd>"
    o = o & "<dt>X-Real-IP</dt><dd>リバースプロキシが明示的に指定したクライアントIPアドレス（X-Real-IP ヘッダー）。<br>Client IP as provided by the reverse proxy (X-Real-IP header)</dd>"
    o = o & "<dt>Host</dt><dd>クライアントが送信した HTTP Host ヘッダーの値。FQDNまたはIPアドレスが入り、IPでアクセスした場合はIPが表示されます。<br>The value of the HTTP Host header sent by the client. This is typically a domain name, but if accessed via IP address, the IP will appear here.</dd>"
    o = o & "<dt>User-Agent</dt><dd>クライアントのブラウザやツール識別子（例：curl、Chrome など）。<br>Client's browser or tool identifier (e.g., curl, Chrome)</dd>"
    o = o & "<dt>Referer</dt><dd>現在のリクエストにリンクしていた直前のページのURL。空になる場合もあります。<br>URL of the page that linked to the current request (may be empty)</dd>"
    o = o & "</dl>"

    '---- Live Log Viewing ----
    o = o & "<hr><h2>Live Log Viewing (tail -f)</h2>"
    o = o & "<p>To monitor IIS logs in real time:</p><ul>"
    o = o & "<li><code>PowerShell: Get-Content -Path 'C:\\inetpub\\logs\\LogFiles\\W3SVC1\\u_ex*.log' -Tail 10 -Wait</code></li>"
    o = o & "<li><code>WSL/Linux: tail -f /mnt/c/inetpub/logs/LogFiles/W3SVC1/u_ex*.log</code></li>"
    o = o & "</ul>"

    o = o & "</body></html>"
    Response.Write o
  End If
%>
"@

# BOM付き UTF-8 で書き込み
$writer = New-Object System.IO.StreamWriter("$WebRoot\index.asp", $false, $utf8Bom)
$writer.Write($asp)
$writer.Close()




# ========================
# 8. Default Document 設定（重複回避）
# ========================
Write-Host "▶ 8. Configuring Default Document..." -ForegroundColor Cyan
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/defaultDocument" -name enabled -value true
Remove-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/defaultDocument/files" -name "." `
  -AtElement @{value="index.asp"} -ErrorAction SilentlyContinue
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
  -filter "system.webServer/defaultDocument/files" -name "." `
  -value @{value="index.asp"}

# ========================
# 9. IE Enhanced Security 無効化
# ========================
#----------------  Disable-IE ESC  ----------------
#----------------  Disable-IE ESC  ----------------
$base = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components'
$adminKey = "$base\{A509B1A7-37EF-4B3F-8CFC-4F3A74704073}" # Administrators
$userKey  = "$base\{A509B1A8-37EF-4B3F-8CFC-4F3A74704073}" # Users

@($adminKey, $userKey) | ForEach-Object {
    if (Test-Path $_) {
        # ① ESC を無効化
        Set-ItemProperty -Path $_ -Name IsInstalled -Value 0   -Force
        # ② 初回ログオン時に ESC を再び有効化させる起動コマンドを無効化
        Set-ItemProperty -Path $_ -Name StubPath   -Value ''  -Force
    }
}

Write-Host '✔ IE ESC disabled for both Administrators and Users. Please reopen Server Manager or relogin to reflect the change.' -ForegroundColor Cyan
#--------------------------------------------------


# ========================
# 10. ファイアウォール開放
# ========================
Write-Host "▶ 10. Configuring Firewall Rules..." -ForegroundColor Cyan
$rules = @(
    @{ Name = "Allow HTTP";  Port = 80   },
    @{ Name = "Allow HTTPS"; Port = 443  },
    @{ Name = "Allow RDP";   Port = 3389 }
)
foreach ($r in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $r.Name `
          -Direction Inbound -Protocol TCP -LocalPort $r.Port -Action Allow
    }
}

# ========================
# 11. IIS 再起動
# ========================
Write-Host "▶ 11. Restarting IIS..." -ForegroundColor Cyan
iisreset

Write-Host "`n✅ Setup Complete!"
Write-Host "👉 ブラウザで https://<サーバーIP>/?format=json または通常アクセスで HTML を確認できます"