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
