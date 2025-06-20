#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Azure CLI と Azure PowerShell をインストールするスクリプト

.DESCRIPTION
    このスクリプトは以下の機能を提供します:
    - Azure CLI のインストール
    - Azure PowerShell モジュールのインストール
    - 既存インストールの確認と更新
    - エラーハンドリングとログ出力
    - インストール後の検証

.PARAMETER InstallAzureCLI
    Azure CLI をインストールするかどうか (デフォルト: $true)

.PARAMETER InstallAzurePowerShell
    Azure PowerShell をインストールするかどうか (デフォルト: $true)

.PARAMETER Force
    既存のインストールを強制的に更新するかどうか (デフォルト: $false)

.PARAMETER LogPath
    ログファイルの出力パス (デフォルト: カレントディレクトリ)

.EXAMPLE
    .\SetupAzureTools.ps1
    両方のツールをインストール

.EXAMPLE
    .\SetupAzureTools.ps1 -InstallAzureCLI $false
    Azure PowerShell のみインストール

.EXAMPLE
    .\SetupAzureTools.ps1 -Force
    既存インストールを強制更新
#>

[CmdletBinding()]
param(
    [bool]$InstallAzureCLI = $true,
    [bool]$InstallAzurePowerShell = $true,
    [bool]$Force = $false,
    [string]$LogPath = $PWD.Path
)

# ログ設定
$LogFile = Join-Path $LogPath "AzureToolsSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorActionPreference = "Stop"

# ログ関数
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # コンソールとファイルの両方に出力
    switch ($Level) {
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogMessage -ForegroundColor Green }
        default { Write-Host $LogMessage }
    }
    
    Add-Content -Path $LogFile -Value $LogMessage
}

# プログレス表示関数
function Write-Progress-Custom {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [string]$CurrentOperation = ""
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
    Write-Log "[$PercentComplete%] $Activity - $Status $CurrentOperation" "INFO"
}

# ダウンロード進行状況付きWebRequest
function Download-FileWithProgress {
    param(
        [string]$Uri,
        [string]$OutFile,
        [string]$Activity = "ダウンロード中"
    )
    
    try {
        $webClient = New-Object System.Net.WebClient
        
        # プログレスイベントの登録
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            $totalMB = [Math]::Round($Event.SourceEventArgs.TotalBytesToReceive / 1MB, 2)
            $receivedMB = [Math]::Round($Event.SourceEventArgs.BytesReceived / 1MB, 2)
            
            Write-Progress -Activity $using:Activity -Status "$receivedMB MB / $totalMB MB" -PercentComplete $percent
        } | Out-Null
        
        # ダウンロード開始
        $webClient.DownloadFileTaskAsync($Uri, $OutFile)
        
        # 完了まで待機
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }
        
        # イベントの登録解除
        Get-EventSubscriber | Unregister-Event
        $webClient.Dispose()
        
        Write-Progress -Activity $Activity -Completed
        
    } catch {
        Write-Progress -Activity $Activity -Completed
        throw
    }
}

# 管理者権限チェック
function Test-AdminRights {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# インストール済みツールの確認
function Test-AzureCLIInstalled {
    try {
        $null = Get-Command az -ErrorAction Stop
        $Version = (az version --output json | ConvertFrom-Json).'azure-cli'
        return @{ Installed = $true; Version = $Version }
    }
    catch {
        return @{ Installed = $false; Version = $null }
    }
}

function Test-AzurePowerShellInstalled {
    try {
        $Module = Get-Module -Name Az -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        if ($Module) {
            return @{ Installed = $true; Version = $Module.Version.ToString() }
        }
        else {
            return @{ Installed = $false; Version = $null }
        }
    }
    catch {
        return @{ Installed = $false; Version = $null }
    }
}

# Azure CLI インストール関数
function Install-AzureCLI {
    param([bool]$ForceInstall = $false)
    
    Write-Progress-Custom -Activity "Azure CLI インストール" -Status "開始" -PercentComplete 0
    Write-Log "Azure CLI のインストールを開始します..." "INFO"
    
    try {
        Write-Progress-Custom -Activity "Azure CLI インストール" -Status "インストール状況確認中" -PercentComplete 10
        $CLIStatus = Test-AzureCLIInstalled
        
        if ($CLIStatus.Installed -and -not $ForceInstall) {
            Write-Log "Azure CLI は既にインストールされています (バージョン: $($CLIStatus.Version))" "INFO"
            $Choice = Read-Host "更新しますか? (y/N)"
            if ($Choice -ne 'y' -and $Choice -ne 'Y') {
                Write-Log "Azure CLI のインストールをスキップしました" "INFO"
                Write-Progress -Activity "Azure CLI インストール" -Completed
                return
            }
        }
        
        Write-Progress-Custom -Activity "Azure CLI インストール" -Status "インストール方法を決定中" -PercentComplete 20
        
        # Chocolatey を使用してインストール (推奨方法)
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "Chocolatey でインストール中" -PercentComplete 30 -CurrentOperation "choco install azure-cli"
            Write-Log "Chocolatey を使用して Azure CLI をインストールします..." "INFO"
            
            $chocoProcess = Start-Process choco -ArgumentList "install", "azure-cli", "-y" -PassThru -NoNewWindow
            
            while (-not $chocoProcess.HasExited) {
                Write-Progress-Custom -Activity "Azure CLI インストール" -Status "Chocolatey でインストール中" -PercentComplete 50 -CurrentOperation "実行中... (PID: $($chocoProcess.Id))"
                Start-Sleep -Seconds 2
            }
            
            if ($chocoProcess.ExitCode -ne 0) {
                throw "Chocolatey インストールがエラーコード $($chocoProcess.ExitCode) で終了しました"
            }
        }
        else {
            # MSI インストーラーを使用
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "MSI インストーラーを準備中" -PercentComplete 30
            Write-Log "MSI インストーラーを使用して Azure CLI をインストールします..." "INFO"
            
            $DownloadUrl = "https://aka.ms/installazurecliwindows"
            $InstallerPath = Join-Path $env:TEMP "AzureCLI.msi"
            
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "インストーラーをダウンロード中" -PercentComplete 40
            Write-Log "Azure CLI インストーラーをダウンロードしています..." "INFO"
            
            # プログレス付きダウンロード
            try {
                Download-FileWithProgress -Uri $DownloadUrl -OutFile $InstallerPath -Activity "Azure CLI ダウンロード"
            } catch {
                # フォールバック: 通常のダウンロード
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing
            }
            
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "MSI インストーラーを実行中" -PercentComplete 60 -CurrentOperation "msiexec.exe"
            Write-Log "Azure CLI をインストールしています..." "INFO"
            
            $msiProcess = Start-Process msiexec.exe -ArgumentList "/i", "`"$InstallerPath`"", "/quiet", "/norestart" -PassThru -Wait
            
            if ($msiProcess.ExitCode -ne 0) {
                throw "MSI インストールがエラーコード $($msiProcess.ExitCode) で終了しました"
            }
            
            # インストーラーファイルを削除
            Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
        }
        
        Write-Progress-Custom -Activity "Azure CLI インストール" -Status "環境変数を更新中" -PercentComplete 80
        # PATH の更新
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        Write-Progress-Custom -Activity "Azure CLI インストール" -Status "インストール確認中" -PercentComplete 90
        # インストール確認
        Write-Log "インストールの確認を行っています..." "INFO"
        Start-Sleep -Seconds 3
        
        for ($i = 1; $i -le 5; $i++) {
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "インストール確認中" -PercentComplete (90 + $i) -CurrentOperation "試行 $i/5"
            $NewCLIStatus = Test-AzureCLIInstalled
            if ($NewCLIStatus.Installed) {
                break
            }
            Start-Sleep -Seconds 2
        }
        
        if ($NewCLIStatus.Installed) {
            Write-Progress-Custom -Activity "Azure CLI インストール" -Status "完了" -PercentComplete 100
            Write-Log "Azure CLI のインストールが完了しました (バージョン: $($NewCLIStatus.Version))" "SUCCESS"
        }
        else {
            throw "Azure CLI のインストール後に確認できませんでした"
        }
        
        Write-Progress -Activity "Azure CLI インストール" -Completed
    }
    catch {
        Write-Progress -Activity "Azure CLI インストール" -Completed
        Write-Log "Azure CLI のインストール中にエラーが発生しました: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Azure PowerShell インストール関数
function Install-AzurePowerShell {
    param([bool]$ForceInstall = $false)
    
    Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "開始" -PercentComplete 0
    Write-Log "Azure PowerShell のインストールを開始します..." "INFO"
    
    try {
        Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "インストール状況確認中" -PercentComplete 10
        $PSStatus = Test-AzurePowerShellInstalled
        
        if ($PSStatus.Installed -and -not $ForceInstall) {
            Write-Log "Azure PowerShell は既にインストールされています (バージョン: $($PSStatus.Version))" "INFO"
            $Choice = Read-Host "更新しますか? (y/N)"
            if ($Choice -ne 'y' -and $Choice -ne 'Y') {
                Write-Log "Azure PowerShell のインストールをスキップしました" "INFO"
                Write-Progress -Activity "Azure PowerShell インストール" -Completed
                return
            }
        }
        
        # PowerShell Gallery からインストール
        Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "PowerShell Gallery を準備中" -PercentComplete 20
        Write-Log "PowerShell Gallery から Azure PowerShell をインストールします..." "INFO"
        
        # NuGet プロバイダーの確認・インストール
        Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "NuGet プロバイダーを確認中" -PercentComplete 30
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "NuGet プロバイダーをインストール中" -PercentComplete 35 -CurrentOperation "Install-PackageProvider NuGet"
            Write-Log "NuGet プロバイダーをインストールしています..." "INFO"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
        }
        
        # PowerShell Gallery を信頼済みリポジトリに設定
        Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "PowerShell Gallery を信頼済みに設定中" -PercentComplete 40
        if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
            Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "PowerShell Gallery を信頼済みに設定中" -PercentComplete 45 -CurrentOperation "Set-PSRepository PSGallery"
            Write-Log "PowerShell Gallery を信頼済みリポジトリに設定しています..." "INFO"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        
        # Az モジュールのインストール
        if ($PSStatus.Installed) {
            Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "Azure PowerShell を更新中" -PercentComplete 50 -CurrentOperation "Update-Module Az"
            Write-Log "Azure PowerShell を更新しています..." "INFO"
            Write-Log "注意: Azure PowerShell の更新には数分かかる場合があります..." "WARNING"
            
            # バックグラウンドジョブで実行してプログレスを表示
            $updateJob = Start-Job -ScriptBlock {
                Update-Module -Name Az -Force -AllowClobber -Scope AllUsers
            }
            
            $progressCount = 50
            while ($updateJob.State -eq "Running") {
                $progressCount = ($progressCount + 1) % 90
                if ($progressCount -lt 50) { $progressCount = 50 }
                
                Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "Azure PowerShell を更新中 (実行中...)" -PercentComplete $progressCount -CurrentOperation "Update-Module Az"
                Start-Sleep -Seconds 3
            }
            
            $updateResult = Receive-Job -Job $updateJob
            Remove-Job -Job $updateJob
            
            if ($updateJob.State -eq "Failed") {
                throw "Azure PowerShell の更新に失敗しました"
            }
        }
        else {
            Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "Azure PowerShell をインストール中" -PercentComplete 50 -CurrentOperation "Install-Module Az"
            Write-Log "Azure PowerShell をインストールしています..." "INFO"
            Write-Log "注意: Azure PowerShell のインストールには数分かかる場合があります..." "WARNING"
            
            # バックグラウンドジョブで実行してプログレスを表示
            $installJob = Start-Job -ScriptBlock {
                Install-Module -Name Az -Force -AllowClobber -Scope AllUsers
            }
            
            $progressCount = 50
            while ($installJob.State -eq "Running") {
                $progressCount = ($progressCount + 1) % 90
                if ($progressCount -lt 50) { $progressCount = 50 }
                
                Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "Azure PowerShell をインストール中 (実行中...)" -PercentComplete $progressCount -CurrentOperation "Install-Module Az"
                Start-Sleep -Seconds 3
            }
            
            $installResult = Receive-Job -Job $installJob
            Remove-Job -Job $installJob
            
            if ($installJob.State -eq "Failed") {
                throw "Azure PowerShell のインストールに失敗しました"
            }
        }
        
        Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "インストール確認中" -PercentComplete 90
        # インストール確認
        Write-Log "インストールの確認を行っています..." "INFO"
        $NewPSStatus = Test-AzurePowerShellInstalled
        
        if ($NewPSStatus.Installed) {
            Write-Progress-Custom -Activity "Azure PowerShell インストール" -Status "完了" -PercentComplete 100
            Write-Log "Azure PowerShell のインストールが完了しました (バージョン: $($NewPSStatus.Version))" "SUCCESS"
        }
        else {
            throw "Azure PowerShell のインストール後に確認できませんでした"
        }
        
        Write-Progress -Activity "Azure PowerShell インストール" -Completed
    }
    catch {
        Write-Progress -Activity "Azure PowerShell インストール" -Completed
        Write-Log "Azure PowerShell のインストール中にエラーが発生しました: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# インストール後の検証
function Test-InstallationSuccess {
    Write-Log "インストール結果を検証しています..." "INFO"
    
    $Results = @{
        AzureCLI = @{ Success = $false; Version = $null; Error = $null }
        AzurePowerShell = @{ Success = $false; Version = $null; Error = $null }
    }
    
    # Azure CLI の確認
    if ($InstallAzureCLI) {
        try {
            $CLIStatus = Test-AzureCLIInstalled
            if ($CLIStatus.Installed) {
                $Results.AzureCLI.Success = $true
                $Results.AzureCLI.Version = $CLIStatus.Version
                Write-Log "✓ Azure CLI: バージョン $($CLIStatus.Version)" "SUCCESS"
            }
            else {
                $Results.AzureCLI.Error = "インストールが確認できませんでした"
                Write-Log "✗ Azure CLI: インストールが確認できませんでした" "ERROR"
            }
        }
        catch {
            $Results.AzureCLI.Error = $_.Exception.Message
            Write-Log "✗ Azure CLI: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Azure PowerShell の確認
    if ($InstallAzurePowerShell) {
        try {
            $PSStatus = Test-AzurePowerShellInstalled
            if ($PSStatus.Installed) {
                $Results.AzurePowerShell.Success = $true
                $Results.AzurePowerShell.Version = $PSStatus.Version
                Write-Log "✓ Azure PowerShell: バージョン $($PSStatus.Version)" "SUCCESS"
            }
            else {
                $Results.AzurePowerShell.Error = "インストールが確認できませんでした"
                Write-Log "✗ Azure PowerShell: インストールが確認できませんでした" "ERROR"
            }
        }
        catch {
            $Results.AzurePowerShell.Error = $_.Exception.Message
            Write-Log "✗ Azure PowerShell: $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $Results
}

# メイン処理
function Main {
    try {
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "開始" -PercentComplete 0
        Write-Log "=== Azure ツールセットアップスクリプト開始 ===" "INFO"
        Write-Log "ログファイル: $LogFile" "INFO"
        
        # 管理者権限チェック
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "管理者権限を確認中" -PercentComplete 5
        if (-not (Test-AdminRights)) {
            Write-Log "このスクリプトは管理者権限で実行する必要があります" "ERROR"
            Write-Log "PowerShell を管理者として実行してから再実行してください" "ERROR"
            exit 1
        }
        
        Write-Log "管理者権限を確認しました" "INFO"
        
        # システム情報の記録
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "システム情報を取得中" -PercentComplete 10
        Write-Log "システム情報:" "INFO"
        
        # PowerShell 5.1 と 7+ の互換性対応
        try {
            if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
                $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
            } elseif (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
                $OSInfo = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
            } else {
                $OSInfo = "情報取得不可"
            }
            Write-Log "  OS: $OSInfo" "INFO"
        }
        catch {
            Write-Log "  OS: 情報取得に失敗しました" "WARNING"
        }
        
        Write-Log "  PowerShell バージョン: $($PSVersionTable.PSVersion)" "INFO"
        
        # .NET バージョンの取得（PowerShell 7では CLRVersion が存在しない場合がある）
        if ($PSVersionTable.CLRVersion) {
            Write-Log "  .NET CLR バージョン: $($PSVersionTable.CLRVersion)" "INFO"
        }
        if ($PSVersionTable.ContainsKey('OS')) {
            Write-Log "  実行OS: $($PSVersionTable.OS)" "INFO"
        }
        
        # 現在のインストール状況確認
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "現在のインストール状況を確認中" -PercentComplete 15
        Write-Log "現在のインストール状況を確認しています..." "INFO"
        
        $installTasks = @()
        
        if ($InstallAzureCLI) {
            $CLIStatus = Test-AzureCLIInstalled
            if ($CLIStatus.Installed) {
                Write-Log "Azure CLI: インストール済み (バージョン: $($CLIStatus.Version))" "INFO"
            }
            else {
                Write-Log "Azure CLI: 未インストール" "INFO"
                $installTasks += "Azure CLI"
            }
        }
        
        if ($InstallAzurePowerShell) {
            $PSStatus = Test-AzurePowerShellInstalled
            if ($PSStatus.Installed) {
                Write-Log "Azure PowerShell: インストール済み (バージョン: $($PSStatus.Version))" "INFO"
            }
            else {
                Write-Log "Azure PowerShell: 未インストール" "INFO"
                $installTasks += "Azure PowerShell"
            }
        }
        
        if ($installTasks.Count -gt 0) {
            Write-Log "インストール予定: $($installTasks -join ', ')" "INFO"
        } else {
            Write-Log "すべてのツールが既にインストールされています" "INFO"
        }
        
        # インストール実行
        $currentTask = 1
        $totalTasks = ($InstallAzureCLI -and $InstallAzurePowerShell) ? 2 : 1
        
        if ($InstallAzureCLI) {
            Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "Azure CLI をインストール中 ($currentTask/$totalTasks)" -PercentComplete 20
            Install-AzureCLI -ForceInstall $Force
            $currentTask++
        }
        
        if ($InstallAzurePowerShell) {
            Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "Azure PowerShell をインストール中 ($currentTask/$totalTasks)" -PercentComplete 60
            Install-AzurePowerShell -ForceInstall $Force
        }
        
        # 結果の検証
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "インストール結果を検証中" -PercentComplete 90
        $Results = Test-InstallationSuccess
        
        Write-Progress-Custom -Activity "Azure ツールセットアップ" -Status "完了" -PercentComplete 100
        Write-Log "=== インストール完了 ===" "SUCCESS"
        
        # インストール結果サマリー
        Write-Host "`n" -NoNewline
        Write-Host "=" * 50 -ForegroundColor Cyan
        Write-Host "  インストール結果サマリー" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Cyan
        
        if ($InstallAzureCLI) {
            if ($Results.AzureCLI.Success) {
                Write-Host "✓ Azure CLI: インストール成功 (v$($Results.AzureCLI.Version))" -ForegroundColor Green
            } else {
                Write-Host "✗ Azure CLI: インストール失敗 - $($Results.AzureCLI.Error)" -ForegroundColor Red
            }
        }
        
        if ($InstallAzurePowerShell) {
            if ($Results.AzurePowerShell.Success) {
                Write-Host "✓ Azure PowerShell: インストール成功 (v$($Results.AzurePowerShell.Version))" -ForegroundColor Green
            } else {
                Write-Host "✗ Azure PowerShell: インストール失敗 - $($Results.AzurePowerShell.Error)" -ForegroundColor Red
            }
        }
        
        Write-Host "=" * 50 -ForegroundColor Cyan
        
        # 次のステップの案内
        Write-Log "" "INFO"
        Write-Log "次のステップ:" "INFO"
        Write-Log "1. 新しいPowerShellセッションを開始するか、'refreshenv' を実行してください" "INFO"
        Write-Log "2. Azure にサインインしてください:" "INFO"
        if ($Results.AzureCLI.Success) {
            Write-Log "   Azure CLI: az login" "INFO"
        }
        if ($Results.AzurePowerShell.Success) {
            Write-Log "   Azure PowerShell: Connect-AzAccount" "INFO"
        }
        Write-Log "3. インストールを確認してください:" "INFO"
        if ($Results.AzureCLI.Success) {
            Write-Log "   Azure CLI: az --version" "INFO"
        }
        if ($Results.AzurePowerShell.Success) {
            Write-Log "   Azure PowerShell: Get-Module Az -ListAvailable" "INFO"
        }
        
        Write-Log "ログファイルが保存されました: $LogFile" "INFO"
        Write-Progress -Activity "Azure ツールセットアップ" -Completed
        
    }
    catch {
        Write-Progress -Activity "Azure ツールセットアップ" -Completed
        Write-Log "スクリプト実行中に予期しないエラーが発生しました: $($_.Exception.Message)" "ERROR"
        Write-Log "詳細なエラー情報: $($_.Exception.ToString())" "ERROR"
        exit 1
    }
}

# メイン処理実行
Main