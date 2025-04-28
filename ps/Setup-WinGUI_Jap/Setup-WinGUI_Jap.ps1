<#
.SYNOPSIS
    Set-JapanLocale.ps1
    Installs Japanese (ja-JP) language pack and configures full Japanese
    experience (UI, culture, geo, keyboard, IME, time zone).

.DESCRIPTION
    • Adds ja-JP language capabilities (ODC or Install-Language).
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
# Language pack installation & completion check
# --------------------------------------------------------------------
Write-Host "▶ Checking language pack status..." -ForegroundColor Cyan
if (-not (Get-WindowsCapability -Online | 
          Where-Object { $_.Name -like "Language.Basic~~~$LanguageTag~*" -and $_.State -eq 'Installed' })) {

    Write-Host "▶ Installing language capabilities..." -ForegroundColor Cyan
    $caps = @(
        "Language.Basic~~~$LanguageTag~0.0.1.0",
        "Language.Handwriting~~~$LanguageTag~0.0.1.0",
        "Language.OCR~~~$LanguageTag~0.0.1.0",
        "Language.Speech~~~$LanguageTag~0.0.1.0",
        "Language.TextToSpeech~~~$LanguageTag~0.0.1.0"
    )
    foreach ($cap in $caps) {
        Add-WindowsCapability -Online -Name $cap
    }

    Write-Host "⏳ Waiting for language pack installation..." -ForegroundColor Cyan
    do {
        Start-Sleep -Seconds 5
        $LangStatus = Get-WindowsCapability -Online |
                      Where-Object { $_.Name -like "Language.Basic~~~$LanguageTag~*" }
        if ($LangStatus.State -eq 'Installed') {
            Write-Host "✔ Language pack installed successfully." -ForegroundColor Green
            break
        } else {
            Write-Host "  - Current state: $($LangStatus.State)" -ForegroundColor Yellow
        }
    } while ($true)
}
else {
    Write-Host "✔ Language pack already installed." -ForegroundColor Green
}

# --------------------------------------------------------------------
# Set Locale, UI, and Region
# --------------------------------------------------------------------
Write-Host "▶ Configuring system locale and culture..." -ForegroundColor Cyan
Set-WinSystemLocale $LanguageTag
Set-Culture        $LanguageTag
Set-WinUILanguageOverride $LanguageTag
Set-WinHomeLocation -GeoId $GeoId

# --------------------------------------------------------------------
# User language list & IME keyboard setup
# --------------------------------------------------------------------
Write-Host "▶ Configuring user language & keyboard..." -ForegroundColor Cyan
$newList = New-WinUserLanguageList $LanguageTag
$newList[0].Handwriting = $true
$newList[0].InputMethodTips.Clear()
[void]$newList[0].InputMethodTips.Add($JaImeTip)
Set-WinUserLanguageList $newList -Force

Set-WinDefaultInputMethodOverride -InputTip $JaImeTip

# --------------------------------------------------------------------
# Time zone setting
# --------------------------------------------------------------------
Write-Host "▶ Configuring time zone to $TimeZoneId..." -ForegroundColor Cyan
Set-TimeZone -Id $TimeZoneId

# --------------------------------------------------------------------
# Explicitly set UI language via registry for user session
# --------------------------------------------------------------------
Write-Host "▶ Explicitly setting UI language in registry..." -ForegroundColor Cyan
Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'PreferredUILanguages' -Value $LanguageTag -Force
Set-ItemProperty 'HKCU:\Control Panel\Desktop\MuiCached' -Name 'MachinePreferredUILanguages' -Value $LanguageTag -Force
Set-ItemProperty 'HKCU:\Control Panel\International\User Profile' -Name 'Languages' -Value $LanguageTag -Force

# --------------------------------------------------------------------
# BCD locale settings for boot-time language
# --------------------------------------------------------------------
Write-Host "▶ Applying boot-time locale settings..." -ForegroundColor Cyan
bcdedit /set {current} locale $LanguageTag | Out-Null
bcdedit /set {bootmgr} locale $LanguageTag | Out-Null
bcdedit /set {current} quietboot Yes | Out-Null

Write-Host "`n✔ Japanese locale & UI configuration complete. Please reboot now." -ForegroundColor Green
