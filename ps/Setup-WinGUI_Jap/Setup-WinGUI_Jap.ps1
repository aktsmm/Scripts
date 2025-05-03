<#
.SYNOPSIS
    Set-JapanLocale.ps1
    Installs Japanese (ja-JP) language pack and configures full Japanese
    experience (UI, culture, geo, keyboard, IME, time zone).

.DESCRIPTION
    • Adds ja-JP language capabilities.
    • Sets Display/UI language, System locale, Culture, Geo, TimeZone.
    • Registers Japanese keyboard (TIP 0411:00000411) and makes IME default.
    • Idempotent on re-run.
    Tested on Windows Server 2019 / 2022 / vNext (Desktop Exp).

.NOTES
    Run as local Administrator. Reboot required after execution.
#>

param (
    [string]$LanguageTag = 'ja-JP',
    [string]$TimeZoneId  = 'Tokyo Standard Time',
    [int]   $GeoId       = 122,
    [string]$JaImeTip    = '0411:00000411'
)

$ErrorActionPreference = 'Stop'

# --------------------------------------------------------------------
# 1. Language pack installation & verification
# --------------------------------------------------------------------
Write-Host "▶ Checking language pack status..." -ForegroundColor Cyan
$languageBasic = "Language.Basic~~~$LanguageTag~0.0.1.0"
$installed = Get-WindowsCapability -Online | Where-Object {
    $_.Name -eq $languageBasic -and $_.State -eq 'Installed'
}

if (-not $installed) {
    Write-Host "▶ Installing language capabilities..." -ForegroundColor Cyan
    $caps = @(
        "Language.Basic~~~$LanguageTag~0.0.1.0",
        "Language.Handwriting~~~$LanguageTag~0.0.1.0",
        "Language.OCR~~~$LanguageTag~0.0.1.0",
        "Language.Speech~~~$LanguageTag~0.0.1.0",
        "Language.TextToSpeech~~~$LanguageTag~0.0.1.0"
    )
    foreach ($cap in $caps) {
        Add-WindowsCapability -Online -Name $cap -ErrorAction Stop
    }

    Write-Host "⏳ Waiting for language pack installation..." -ForegroundColor Cyan
    do {
        Start-Sleep -Seconds 5
        $status = (Get-WindowsCapability -Online | Where-Object { $_.Name -eq $languageBasic }).State
        Write-Host "  - Current state: $status" -ForegroundColor Yellow
    } until ($status -eq 'Installed')

    Write-Host "✔ Language pack installed successfully." -ForegroundColor Green
} else {
    Write-Host "✔ Language pack already installed." -ForegroundColor Green
}

# --------------------------------------------------------------------
# 2. Locale, culture, and region settings
# --------------------------------------------------------------------
Write-Host "▶ Configuring system locale and culture..." -ForegroundColor Cyan
Set-WinSystemLocale           $LanguageTag
Set-Culture                   $LanguageTag
Set-WinUILanguageOverride     $LanguageTag
Set-WinHomeLocation          -GeoId $GeoId

# --------------------------------------------------------------------
# 3. User language and IME keyboard
# --------------------------------------------------------------------
Write-Host "▶ Configuring user language & keyboard..." -ForegroundColor Cyan
$newList = New-WinUserLanguageList $LanguageTag
$newList[0].Handwriting = $true
$newList[0].InputMethodTips.Clear()
[void]$newList[0].InputMethodTips.Add($JaImeTip)
Set-WinUserLanguageList $newList -Force
Set-WinDefaultInputMethodOverride -InputTip $JaImeTip

# --------------------------------------------------------------------
# 4. Time zone
# --------------------------------------------------------------------
Write-Host "▶ Configuring time zone to '$TimeZoneId'..." -ForegroundColor Cyan
Set-TimeZone -Id $TimeZoneId

# --------------------------------------------------------------------
# 5. Registry-based UI language override for user
# --------------------------------------------------------------------
Write-Host "▶ Setting UI language in registry..." -ForegroundColor Cyan
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'PreferredUILanguages' -Value $LanguageTag -Force
Set-ItemProperty 'HKCU:\Control Panel\Desktop\MuiCached' -Name 'MachinePreferredUILanguages' -Value $LanguageTag -Force
Set-ItemProperty 'HKCU:\Control Panel\International\User Profile' -Name 'Languages' -Value $LanguageTag -Force

# --------------------------------------------------------------------
# 6. Boot-time language settings
# --------------------------------------------------------------------
Write-Host "▶ Applying boot-time locale settings..." -ForegroundColor Cyan
bcdedit /set {current} locale $LanguageTag | Out-Null
bcdedit /set {bootmgr} locale $LanguageTag | Out-Null
bcdedit /set {current} quietboot Yes       | Out-Null

# --------------------------------------------------------------------
# 7. Done
# --------------------------------------------------------------------
Write-Host "`n✔ Japanese locale & UI configuration complete. Please reboot now." -ForegroundColor Green
