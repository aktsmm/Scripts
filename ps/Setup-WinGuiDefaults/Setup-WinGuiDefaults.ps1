<#
======================================================================
 Init-GuiTweaks.ps1
  Windows Server 2019 / Windows 10 以降（GUI）向け初期セットアップ
   1. Notepad / PowerShell をタスクバーへピン留め（冪等）
   2. Explorer 設定
      └ 隠しファイル表示・保護 OS ファイル表示・拡張子表示
   3. Internet Explorer ESC を無効化
======================================================================
#>

param(
    [string[]]$AppsToPin = @(
        "$env:windir\system32\notepad.exe",
        "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe"
    )
)

$ErrorActionPreference = 'Stop'

#--------------------------------------------------------------------
# 1) タスクバーへアプリをピン留め
#--------------------------------------------------------------------
function Test-TaskbarPinned {
    param([string]$ExePath)
    $pinned = Get-ChildItem "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" -Filter '*.lnk' -EA 0
    $wshell = New-Object -ComObject WScript.Shell
    foreach ($lnk in $pinned) {
        if ($wshell.CreateShortcut($lnk.FullName).TargetPath -ieq $ExePath) { return $true }
    }
    return $false
}

function Add-TaskbarPin  {
    param([string]$ExePath)

    if (Test-TaskbarPinned $ExePath) {
        Write-Host "• $(Split-Path $ExePath -Leaf) は既にピン留め済み - skip" -ForegroundColor DarkGray
        return
    }

    $cmdHandler = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.taskbarpin').ExplorerCommandHandler
    $tempVerb   = 'PinMeToTaskBar_' + ([guid]::NewGuid().Guid)
    $regPath    = "HKCU:\SOFTWARE\Classes\*\shell\$tempVerb"
    New-Item -Path $regPath -Force  | Out-Null
    New-ItemProperty -Path $regPath -Name ExplorerCommandHandler -Value $cmdHandler -Force | Out-Null

    $shell  = New-Object -ComObject Shell.Application
    $folder = $shell.Namespace((Split-Path $ExePath))
    $item   = $folder.ParseName((Split-Path $ExePath -Leaf))
    $item.InvokeVerb($tempVerb)

    Remove-Item -Path $regPath -Recurse -Force
    Write-Host "✔ $(Split-Path $ExePath -Leaf) をタスクバーにピン留めしました" -ForegroundColor Cyan
}

foreach ($app in $AppsToPin) {
    if (Test-Path $app) { Add-TaskbarPin  $app } else { Write-Warning "$app が見つかりませんでした" }
}

#--------------------------------------------------------------------
# 2) Explorer：隠しファイル・保護 OS ファイル・拡張子を表示
#--------------------------------------------------------------------
$adv = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $adv Hidden          1 -Force   # 隠しファイルを表示
Set-ItemProperty $adv ShowSuperHidden 1 -Force   # 保護された OS ファイルも表示
Set-ItemProperty $adv HideFileExt     0 -Force   # 拡張子を表示

# Explorer を再起動して設定を即時反映
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process explorer.exe
Write-Host '✔ Explorer 設定を更新しました（隠しファイル & 拡張子を表示）。' -ForegroundColor Cyan

#--------------------------------------------------------------------
# 3) Internet Explorer Enhanced Security Configuration を無効化
#--------------------------------------------------------------------
$base      = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components'
$adminKey  = "$base\{A509B1A7-37EF-4B3F-8CFC-4F3A74704073}"
$userKey   = "$base\{A509B1A8-37EF-4B3F-8CFC-4F3A74704073}"

@($adminKey, $userKey) | ForEach-Object {
    if (Test-Path $_) {
        Set-ItemProperty $_ IsInstalled 0 -Force
        Set-ItemProperty $_ StubPath    '' -Force
    }
}

Write-Host '✔ IE ESC disabled for Administrators & Users. 再ログインで反映。' -ForegroundColor Cyan
#--------------------------------------------------------------------
