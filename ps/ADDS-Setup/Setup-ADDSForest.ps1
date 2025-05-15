<#
.SYNOPSIS
    自動で AD DS フォレストを新規構成し、ドメイン コントローラーへ昇格します。

.PARAMETER DomainName
    新規フォレストの FQDN (例: contoso.local)

.PARAMETER SafeModeAdminPassword
    Directory Services Restore Mode 用パスワード（平文で OK。スクリプト内で SecureString 化）

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Setup-ADDSForest.ps1 `
      -DomainName contoso.local -SafeModeAdminPassword P@ssw0rd123
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [string]$SafeModeAdminPassword
)

#----------------------------
# Helper: simple logger
#----------------------------
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $prefix = "[ADDS-Setup][$Level]"
    Write-Host "$ts $prefix $Message"
}

#----------------------------
# Guard clause – already DC?
#----------------------------
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $null = Get-ADDomain -ErrorAction Stop
    Write-Log "既にドメイン コントローラーです。処理をスキップします。" 'INFO'
    return
}
catch {
    Write-Log "まだドメイン コントローラーではありません。セットアップを開始します。" 'INFO'
}

#----------------------------
# 1. Install AD DS role
#----------------------------
Write-Log "AD DS 役割をインストール中..." 'INFO'
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -ErrorAction Stop

#----------------------------
# 2. Promote to new forest
#----------------------------
$securePwd = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force
$netbios = ($DomainName.Split('.')[0]).ToUpper()

Write-Log "新規フォレスト '$DomainName' (NETBIOS: $netbios) を構成します..." 'INFO'
Install-ADDSForest `
    -DomainName              $DomainName `
    -DomainNetbiosName       $netbios `
    -InstallDNS `
    -SafeModeAdministratorPassword $securePwd `
    -Force

#----------------------------
# 3. Reboot to finish
#----------------------------
Write-Log "再起動して昇格を完了します..." 'INFO'
Restart-Computer -Force
