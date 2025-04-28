<#
.SYNOPSIS
    Install Wireshark, Google Chrome, and Npcap via direct download,
    Wireshark and Chrome install silently, Npcap installs GUI-minimized with preset options.

.DESCRIPTION
    - Skips install if already present.
    - Installs Wireshark and Chrome silently.
    - Launches Npcap GUI installer with minimum options preset.
    - Pins Wireshark and Chrome to the taskbar.

.NOTES
    Requires Administrator privileges.
#>

$ErrorActionPreference = 'Stop'

# アプリ定義（Npcap を最後に移動）
$apps = @(
    @{ Name = 'Wireshark';    Url = 'https://2.na.dl.wireshark.org/win64/Wireshark-4.4.6-x64.exe'; InstallerName = 'Wireshark-setup.exe'; Args = '/S';           CheckExe = 'Wireshark.exe'; Type = 'Exe';  Pin = $true  },
    @{ Name = 'Google Chrome'; Url = 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'; InstallerName = 'Chrome-setup.exe';    Args = '/silent /install'; CheckExe = 'chrome.exe';     Type = 'Exe';  Pin = $true  },
    @{ Name = 'Npcap';        Url = 'https://npcap.com/dist/npcap-1.78.exe';               InstallerName = 'Npcap-setup.exe';       Args = '/winpcap_mode=yes /admin_only=yes /loopback_support=yes /dot11_support=yes'; CheckPath = 'C:\Windows\System32\drivers\npf.sys'; Type = 'Driver'; Pin = $false }
)

# タスクバーへピン留めする関数
function Add-TaskbarPin {
    param(
        [Parameter(Mandatory)] [string]$ExePath
    )
    $pinned = Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Filter '*.lnk' -ErrorAction SilentlyContinue
    $wshell = New-Object -ComObject WScript.Shell
    foreach ($lnk in $pinned) {
        if ($wshell.CreateShortcut($lnk.FullName).TargetPath -ieq $ExePath) { return }
    }
    $cmdHandler = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin').ExplorerCommandHandler
    $tempVerb   = 'PinMeToTaskBar_' + ([guid]::NewGuid().Guid)
    $regPath    = "HKCU:\SOFTWARE\Classes\*\shell\$tempVerb"
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name ExplorerCommandHandler -Value $cmdHandler -Force | Out-Null
    $shell = New-Object -ComObject Shell.Application
    $item  = $shell.Namespace((Split-Path $ExePath)).ParseName((Split-Path $ExePath -Leaf))
    $item.InvokeVerb($tempVerb)
    Remove-Item -Path $regPath -Recurse -Force
}

# メイン処理
foreach ($app in $apps) {
    Write-Host "▶ Checking $($app.Name)..." -ForegroundColor Cyan
    $installed = $false
    # チェック
    if ($app.Type -eq 'Driver') {
        if (Test-Path $app.CheckPath) { $installed = $true }
    } else {
        $path = Get-ChildItem -Path 'C:\Program Files','C:\Program Files (x86)' -Recurse -Include $app.CheckExe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($path) { $installed = $true; $exePath = $path.FullName }
    }
    if ($installed) {
        Write-Host "✔ $($app.Name) is already installed; skipping." -ForegroundColor Green
        if ($app.Pin -and $path) { Add-TaskbarPin -ExePath $exePath }
        continue
    }
    # ダウンロード & インストール
    $installer = Join-Path $env:TEMP $app.InstallerName
    Invoke-WebRequest -Uri $app.Url -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList $app.Args -Wait
    Remove-Item $installer -Force
    Start-Sleep -Seconds 5
    # インストール後ピン留め
    if ($app.Type -ne 'Driver') {
        $path = Get-ChildItem -Path 'C:\Program Files','C:\Program Files (x86)' -Recurse -Include $app.CheckExe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($path -and $app.Pin) { Add-TaskbarPin -ExePath $path.FullName }
    }
}

# Explorer再起動
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process explorer.exe

Write-Host '✔ Setup_default-app complete.' -ForegroundColor Green
