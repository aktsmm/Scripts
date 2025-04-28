<#
.SYNOPSIS
    Install Wireshark, Npcap, and Google Chrome via direct download, 
    Npcap is installed with minimum options automatically (semi-silent).

.DESCRIPTION
    - Skips if already installed.
    - Downloads and installs Wireshark and Chrome silently.
    - Npcap installer opens GUI but with preset options.
    - Pins Wireshark and Chrome to taskbar.
#>

$ErrorActionPreference = 'Stop'

# アプリ定義
$apps = @(
    @{
        Name          = "Npcap"
        Url           = "https://npcap.com/dist/npcap-1.78.exe"
        InstallerName = "Npcap-setup.exe"
        InstallArg    = "/winpcap_mode=yes /admin_only=yes /loopback_support=yes /dot11_support=yes"
        CheckPath     = "C:\Windows\System32\drivers\npf.sys"
        IsDriver      = $true
    },
    @{
        Name          = "Wireshark"
        Url           = "https://2.na.dl.wireshark.org/win64/Wireshark-4.4.6-x64.exe"
        InstallerName = "Wireshark-setup.exe"
        InstallArg    = "/S"
        CheckExe      = "Wireshark.exe"
        IsDriver      = $false
    },
    @{
        Name          = "Google Chrome"
        Url           = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        InstallerName = "Chrome-setup.exe"
        InstallArg    = "/silent /install"
        CheckExe      = "chrome.exe"
        IsDriver      = $false
    }
)

# タスクバーへピン留めする関数
function Pin-ExeToTaskbar {
    param([string]$ExePath)

    $pinned = Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Filter '*.lnk' -ErrorAction SilentlyContinue
    $wshell = New-Object -ComObject WScript.Shell
    foreach ($lnk in $pinned) {
        if ($wshell.CreateShortcut($lnk.FullName).TargetPath -ieq $ExePath) {
            Write-Host "• $(Split-Path $ExePath -Leaf) は既にピン留め済み - skip" -ForegroundColor DarkGray
            return
        }
    }

    $cmdHandler = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin').ExplorerCommandHandler
    $tempVerb   = 'PinMeToTaskBar_' + ([guid]::NewGuid().Guid)
    $regPath    = "HKCU:\SOFTWARE\Classes\*\shell\$tempVerb"
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name ExplorerCommandHandler -Value $cmdHandler -Force | Out-Null

    $shell  = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Split-Path $ExePath))
    $item   = $folder.ParseName((Split-Path $ExePath -Leaf))
    $item.InvokeVerb($tempVerb)

    Remove-Item -Path $regPath -Recurse -Force
    Write-Host "✔ $(Split-Path $ExePath -Leaf) をタスクバーにピン留めしました" -ForegroundColor Cyan
}

# メイン処理
foreach ($app in $apps) {
    Write-Host "▶ Checking $($app.Name)..." -ForegroundColor Cyan

    $alreadyInstalled = $false
    $installedPath    = $null

    if ($app.IsDriver) {
        if (Test-Path $app.CheckPath) {
            $alreadyInstalled = $true
        }
    }
    else {
        $installedPath = Get-ChildItem -Path "C:\Program Files", "C:\Program Files (x86)" -Recurse -Include $app.CheckExe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($installedPath) {
            $alreadyInstalled = $true
        }
    }

    if ($alreadyInstalled) {
        Write-Host "✔ $($app.Name) is already installed. Skipping installation." -ForegroundColor Green
    }
    else {
        $installerPath = Join-Path $env:TEMP $app.InstallerName
        Write-Host "▶ Downloading $($app.Name) installer..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $app.Url -OutFile $installerPath

        Write-Host "▶ Installing $($app.Name)..." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath -ArgumentList $app.InstallArg -Wait

        Remove-Item $installerPath -Force
        Start-Sleep -Seconds 5

        if (-not $app.IsDriver) {
            $installedPath = Get-ChildItem -Path "C:\Program Files", "C:\Program Files (x86)" -Recurse -Include $app.CheckExe -ErrorAction SilentlyContinue | Select-Object -First 1
        }
    }

    if (-not $app.IsDriver -and $installedPath) {
        Pin-ExeToTaskbar $installedPath.FullName
    }
}

# Explorer 再起動
Write-Host "▶ Restarting Explorer to apply taskbar changes..." -ForegroundColor Cyan
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process explorer.exe

Write-Host "✔ All setups complete. Please check your taskbar." -ForegroundColor Green
