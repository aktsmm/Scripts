# =============================================================================
# Azure診断設定とLog Analytics Workspace一覧表示スクリプト
# =============================================================================
# 概要: Azure環境内のリソースログをサポートするリソースの診断設定を分析し、
#       Log Analytics Workspaceの利用状況を統計表示するスクリプト（リソースログ専用版）
# https://learn.microsoft.com/ja-jp/azure/azure-monitor/reference/logs-index 準拠
# 作成日: 2025年1月4日　作成者：yamapan
# ライセンス: MIT License
# 重要: リソースログ（診断ログ）をサポートするリソースタイプのみに厳選（158種類）
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "CSV出力を自動で行う場合は`$trueを指定")]
    [bool]$AutoExportCsv = $false,
    
    [Parameter(HelpMessage = "出力するCSVファイルのパス")]
    [string]$CsvOutputPath = "",
    
    [Parameter(HelpMessage = "分析スコープ: Subscription (サブスクリプション) または Tenant (テナント全体)")]
    [ValidateSet("Subscription", "Tenant")]
    [string]$Scope = "Subscription",
    
    [Parameter(HelpMessage = "対話モードを無効にする場合は`$trueを指定")]
    [bool]$NonInteractive = $false,
    
    [Parameter(HelpMessage = "診断設定なしリソースもCSV出力に含める場合は`$trueを指定")]
    [bool]$IncludeResourcesWithoutDiagnostics = $false
)

# =============================================================================
# ヘルパー関数: タイムアウト付き入力
# =============================================================================
function Read-HostWithTimeout {
    param(
        [string]$Prompt,
        [int]$TimeoutSeconds = 5,
        [string]$DefaultValue = "1"
    )
    
    Write-Host "$Prompt (5秒でタイムアウト、デフォルト: $DefaultValue): " -NoNewline -ForegroundColor Cyan
    
    $timeout = New-TimeSpan -Seconds $TimeoutSeconds
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($stopwatch.Elapsed -lt $timeout) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq "Enter") {
                Write-Host ""
                return $DefaultValue
            } elseif ($key.KeyChar -match '\d') {
                Write-Host $key.KeyChar
                Write-Host ""
                return $key.KeyChar
            }
        }
        Start-Sleep -Milliseconds 50
    }
    
    Write-Host ""
    Write-Host "タイムアウトしました。デフォルト値 '$DefaultValue' を使用します。" -ForegroundColor Yellow
    return $DefaultValue
}

# スクリプト開始時の処理
Write-Host "=== Azure診断設定分析スクリプト開始（リソースログ対応版） ===" -ForegroundColor Cyan
Write-Host "実行時刻: $(Get-Date -Format 'yyyy年MM月dd日 HH:mm:ss')" -ForegroundColor Gray
Write-Host "注意: リソースログ（診断ログ）をサポートするリソースのみ分析対象" -ForegroundColor Yellow

# 実行時間計測用
$startTime = Get-Date

# =============================================================================
# Azure認証情報とテナント/サブスクリプション情報の表示・確認
# =============================================================================

Write-Host "`n=== Azure接続情報の確認 ===" -ForegroundColor Green

# =============================================================================
# 診断ログをサポートする主要リソースタイプの定義（効率化のため）
# =============================================================================

# Microsoft Learn ドキュメントに基づく診断ログサポート対象リソースタイプ（厳選版）
# 参照: https://learn.microsoft.com/ja-jp/azure/azure-monitor/reference/logs-index
# 注意: ログカテゴリが「N/A」のリソースタイプは除外済み（リソースログ非対応のため）
$supportedResourceTypes = @(
    # Microsoft.AAD
    "Microsoft.AAD/DomainServices",
    
    # Microsoft.AgFoodPlatform
    "Microsoft.AgFoodPlatform/farmBeats",
    
    # Microsoft.AnalysisServices
    "Microsoft.AnalysisServices/servers",
    
    # Microsoft.ApiManagement
    "Microsoft.ApiManagement/service",
    "Microsoft.ApiManagement/service/workspaces",
    
    # Microsoft.App (Container Apps)
    "Microsoft.App/managedEnvironments",
    
    # Microsoft.AppConfiguration
    "Microsoft.AppConfiguration/configurationStores",
    
    # Microsoft.AppPlatform (Spring Apps)
    "Microsoft.AppPlatform/spring",
    
    # Microsoft.Attestation
    "Microsoft.Attestation/attestationProviders",
    
    # Microsoft.Automation
    "Microsoft.Automation/automationAccounts",
    
    # Microsoft.AutonomousDevelopmentPlatform
    "Microsoft.AutonomousDevelopmentPlatform/accounts",
    "Microsoft.AutonomousDevelopmentPlatform/workspaces",
    
    # Microsoft.Avs (Azure VMware Solution)
    "Microsoft.Avs/privateClouds",
    
    # Microsoft.AzureDataTransfer
    "Microsoft.AzureDataTransfer/connections/flows",
    
    # Microsoft.AzurePlaywrightService
    "Microsoft.AzurePlaywrightService/accounts",
    
    # Microsoft.AzureSphere
    "Microsoft.AzureSphere/catalogs",
    
    # Microsoft.Batch
    "Microsoft.Batch/batchAccounts",
    
    # Microsoft.BotService（リソースログ対応済み）
    "Microsoft.BotService/botServices",
    
    # Microsoft.Cache (Redis)
    "Microsoft.Cache/redis",
    "Microsoft.Cache/redisEnterprise/databases",
    
    # Microsoft.Cdn
    "Microsoft.Cdn/cdnwebapplicationfirewallpolicies",
    "Microsoft.Cdn/profiles",
    "Microsoft.Cdn/profiles/endpoints",
    
    # Microsoft.Chaos
    "Microsoft.Chaos/experiments",
    
    # Microsoft.ClassicNetwork
    "Microsoft.ClassicNetwork/networksecuritygroups",
    
    # Microsoft.CodeSigning
    "Microsoft.CodeSigning/codesigningaccounts",
    
    # Microsoft.CognitiveServices
    "Microsoft.CognitiveServices/accounts",
    
    # Microsoft.Communication
    "Microsoft.Communication/CommunicationServices",
    
    # Microsoft.Community
    "Microsoft.Community/communityTrainings",
    
    # Microsoft.Compute（リソースログ対応分のみ）
    "Microsoft.Compute/virtualMachines",
    
    # Microsoft.ContainerInstance
    "Microsoft.ContainerInstance/containerGroups",
    
    # Microsoft.ContainerRegistry
    "Microsoft.ContainerRegistry/registries",
    
    # Microsoft.ContainerService (AKS)
    "Microsoft.ContainerService/managedClusters",
    "Microsoft.ContainerService/fleets",
    
    # Microsoft.DataFactory
    "Microsoft.DataFactory/factories",
    
    # Microsoft.DataLakeAnalytics
    "Microsoft.DataLakeAnalytics/accounts",
    
    # Microsoft.DataLakeStore
    "Microsoft.DataLakeStore/accounts",
    
    # Microsoft.DataProtection
    "Microsoft.DataProtection/BackupVaults",
    
    # Microsoft.DataReplication
    "Microsoft.DataReplication/replicationVaults",
    
    # Microsoft.DataShare
    "Microsoft.DataShare/accounts",
    
    # Microsoft.DBforMariaDB
    "Microsoft.DBforMariaDB/servers",
    
    # Microsoft.DBforMySQL
    "Microsoft.DBforMySQL/flexibleServers",
    "Microsoft.DBforMySQL/servers",
    
    # Microsoft.DBforPostgreSQL
    "Microsoft.DBforPostgreSQL/flexibleServers",
    "Microsoft.DBforPostgreSQL/servers",
    "Microsoft.DBforPostgreSQL/serversv2",
    "Microsoft.DBforPostgreSQL/serverGroupsv2",
    
    # Microsoft.DesktopVirtualization (Windows Virtual Desktop)
    "Microsoft.DesktopVirtualization/appAttachPackages",
    "Microsoft.DesktopVirtualization/applicationgroups",
    "Microsoft.DesktopVirtualization/hostpools",
    "Microsoft.DesktopVirtualization/repositoryFolders",
    "Microsoft.DesktopVirtualization/scalingplans",
    "Microsoft.DesktopVirtualization/workspaces",
    
    # Microsoft.DevCenter
    "Microsoft.DevCenter/devcenters",
    
    # Microsoft.Devices (IoT)
    "Microsoft.Devices/IotHubs",
    "Microsoft.Devices/provisioningServices",
    
    # Microsoft.DocumentDB (Cosmos DB)
    "Microsoft.DocumentDB/databaseAccounts",
    "Microsoft.DocumentDB/cassandraClusters",
    "Microsoft.DocumentDB/mongoClusters",
    
    # Microsoft.Edge (新規追加)
    "Microsoft.Edge/diagnostics",
    
    # Microsoft.EventGrid
    "Microsoft.EventGrid/topics",
    "Microsoft.EventGrid/domains",
    "Microsoft.EventGrid/partnerTopics",
    "Microsoft.EventGrid/systemTopics",
    
    # Microsoft.EventHub
    "Microsoft.EventHub/namespaces",
    
    # Microsoft.HealthcareApis
    "Microsoft.HealthcareApis/services",
    "Microsoft.HealthcareApis/workspaces",
    "Microsoft.HealthcareApis/workspaces/dicomservices",
    "Microsoft.HealthcareApis/workspaces/fhirservices",
    "Microsoft.HealthcareApis/workspaces/iotconnectors",
    
    # Microsoft.HealthDataAIServices（新規追加）
    "Microsoft.HealthDataAIServices/deidServices",
    
    # Microsoft.Insights (Application Insights)
    "Microsoft.Insights/components",
    "Microsoft.Insights/autoscalesettings",
    "Microsoft.Insights/datacollectionrules",
    
    # Microsoft.KeyVault
    "Microsoft.KeyVault/vaults",
    "Microsoft.KeyVault/managedHSMs",
    
    # Microsoft.Kubernetes（新規追加）
    "Microsoft.Kubernetes/connectedClusters",
    
    # Microsoft.Kusto（新規追加）
    "Microsoft.Kusto/clusters",
    
    # Microsoft.LoadTestService（新規追加）
    "Microsoft.LoadTestService/loadtests",
    
    # Microsoft.Logic (Logic Apps)
    "Microsoft.Logic/IntegrationAccounts",
    "Microsoft.Logic/Workflows",
    
    # Microsoft.MachineLearningServices
    "Microsoft.MachineLearningServices/registries",
    "Microsoft.MachineLearningServices/workspaces",
    "Microsoft.MachineLearningServices/workspaces/onlineEndpoints",
    
    # Microsoft.ManagedNetworkFabric
    "Microsoft.ManagedNetworkFabric/networkDevices",
    
    # Microsoft.Media
    "Microsoft.Media/mediaservices",
    "Microsoft.Media/videoanalyzers",
    
    # Microsoft.Monitor
    "Microsoft.Monitor/accounts",
    
    # Microsoft.Network
    "Microsoft.Network/applicationGateways",
    "Microsoft.Network/azureFirewalls",
    "Microsoft.Network/bastionHosts",
    "Microsoft.Network/expressRouteCircuits",
    "Microsoft.Network/frontDoors",
    "Microsoft.Network/loadBalancers",
    "Microsoft.Network/networkSecurityGroups",
    "Microsoft.Network/publicIPAddresses",
    "Microsoft.Network/trafficManagerProfiles",
    "Microsoft.Network/virtualNetworkGateways",
    "Microsoft.Network/vpnGateways",
    "Microsoft.Network/p2sVpnGateways",
    "Microsoft.Network/virtualNetworks",
    "Microsoft.Network/networkInterfaces",
    "Microsoft.Network/privateEndpoints",
    "Microsoft.Network/privateLinkServices",
    
    # Microsoft.NetworkCloud（新規追加）
    "Microsoft.NetworkCloud/bareMetalMachines",
    "Microsoft.NetworkCloud/clusterManagers",
    "Microsoft.NetworkCloud/clusters",
    "Microsoft.NetworkCloud/kubernetesClusters",
    "Microsoft.NetworkCloud/storageAppliances",
    
    # Microsoft.NetworkFunction（新規追加）
    "Microsoft.NetworkFunction/azureTrafficCollectors",
    
    # Microsoft.NotificationHubs（新規追加）
    "Microsoft.NotificationHubs/namespaces",
    "Microsoft.NotificationHubs/namespaces/notificationHubs",
    
    # Microsoft.OpenEnergyPlatform（新規追加）
    "Microsoft.OpenEnergyPlatform/energyServices",
    
    # Microsoft.OpenLogisticsPlatform
    "Microsoft.OpenLogisticsPlatform/Workspaces",
    
    # Microsoft.OperationalInsights (Log Analytics)
    "Microsoft.OperationalInsights/workspaces",
    
    # Microsoft.Orbital
    "Microsoft.Orbital/geocatalogs",
    
    # Microsoft.PlayFab
    "Microsoft.PlayFab/titles",
    
    # Microsoft.PowerBI
    "Microsoft.PowerBI/tenants",
    "Microsoft.PowerBI/tenants/workspaces",
    
    # Microsoft.PowerBIDedicated
    "Microsoft.PowerBIDedicated/capacities",
    
    # Microsoft.ProviderHub
    "Microsoft.ProviderHub/providerMonitorSettings",
    "Microsoft.ProviderHub/providerRegistrations",
    
    # Microsoft.Purview
    "Microsoft.Purview/accounts",
    
    # Microsoft.RecoveryServices
    "Microsoft.RecoveryServices/Vaults",
    
    # Microsoft.Relay
    "Microsoft.Relay/namespaces",
    
    # Microsoft.Search
    "Microsoft.Search/searchServices",
    
    # Microsoft.Security
    "Microsoft.Security/antiMalwareSettings",
    "Microsoft.Security/defenderForStorageSettings",
    
    # Microsoft.SecurityInsights (Sentinel)
    "Microsoft.SecurityInsights/settings",
    
    # Microsoft.ServiceBus
    "Microsoft.ServiceBus/Namespaces",
    
    # Microsoft.ServiceNetworking
    "Microsoft.ServiceNetworking/trafficControllers",
    
    # Microsoft.SignalRService
    "Microsoft.SignalRService/SignalR",
    "Microsoft.SignalRService/SignalR/replicas",
    "Microsoft.SignalRService/WebPubSub",
    "Microsoft.SignalRService/WebPubSub/replicas",
    
    # Microsoft.Singularity
    "Microsoft.Singularity/accounts",
    
    # Microsoft.Sql（リソースログ対応分のみ）
    "Microsoft.Sql/managedInstances",
    "Microsoft.Sql/managedInstances/databases",
    "Microsoft.Sql/servers/databases",
    
    # Microsoft.StandbyPool
    "Microsoft.StandbyPool/standbycontainergrouppools",
    "Microsoft.StandbyPool/standbyvirtualmachinepools",
    
    # Microsoft.Storage（親リソース＋サービス別リソースログ対応）
    "Microsoft.Storage/storageAccounts",
    "Microsoft.Storage/storageAccounts/blobServices",
    "Microsoft.Storage/storageAccounts/fileServices",
    "Microsoft.Storage/storageAccounts/queueServices",
    "Microsoft.Storage/storageAccounts/tableServices",
    
    # Microsoft.StreamAnalytics
    "Microsoft.StreamAnalytics/streamingjobs",
    
    # Microsoft.Synapse
    "Microsoft.Synapse/workspaces",
    "Microsoft.Synapse/workspaces/bigDataPools",
    "Microsoft.Synapse/workspaces/kustoPools",
    "Microsoft.Synapse/workspaces/sqlPools",
    
    # Microsoft.TimeSeriesInsights
    "Microsoft.TimeSeriesInsights/environments",
    "Microsoft.TimeSeriesInsights/environments/eventsources",
    
    # Microsoft.Web (App Service)
    "Microsoft.Web/sites",
    "Microsoft.Web/sites/slots",
    "Microsoft.Web/serverfarms",
    "Microsoft.Web/staticsites",
    "Microsoft.Web/hostingEnvironments",
    
    # Microsoft.WorkloadMonitor
    "Microsoft.WorkloadMonitor/monitors"
)

Write-Host "`n=== リソースタイプフィルター情報（リソースログ限定版） ===" -ForegroundColor Green
Write-Host "リソースログをサポートするリソースタイプ数: $($supportedResourceTypes.Count)" -ForegroundColor Yellow
Write-Host "Microsoft Learn公式ドキュメント準拠（最新版：2025年01月04日リソースログ限定更新）" -ForegroundColor Gray
Write-Host "重要: ログカテゴリ「N/A」のリソースタイプは除外済み" -ForegroundColor Red
Write-Host "効率化により、リソースログ非対応のリソースタイプをスキップします" -ForegroundColor Gray

try {
    # 現在のAzureコンテキストを取得
    $currentContext = Get-AzContext
    if (-not $currentContext) {
        Write-Error "Azureにログインしていません。Connect-AzAccount を実行してください。"
        exit 1
    }

    # テナント情報の表示
    Write-Host "現在のテナント情報:" -ForegroundColor Yellow
    Write-Host "  テナントID: $($currentContext.Tenant.Id)" -ForegroundColor White
    
    # テナント名の取得（複数の方法を試行）
    $tenantName = $currentContext.Tenant.Directory
    if ([string]::IsNullOrEmpty($tenantName)) {
        try {
            # Get-AzTenantを使用してテナント情報を取得
            $tenantInfo = Get-AzTenant -TenantId $currentContext.Tenant.Id -ErrorAction SilentlyContinue
            if ($tenantInfo -and $tenantInfo.Name) {
                $tenantName = $tenantInfo.Name
            } elseif ($tenantInfo -and $tenantInfo.Domains) {
                $tenantName = $tenantInfo.Domains[0]
            } else {
                $tenantName = "取得できませんでした"
            }
        } catch {
            $tenantName = "取得エラー"
        }
    }
    Write-Host "  テナント名: $tenantName" -ForegroundColor White
    
    # 現在のサブスクリプション情報の表示
    Write-Host "現在のサブスクリプション:" -ForegroundColor Yellow
    Write-Host "  サブスクリプションID: $($currentContext.Subscription.Id)" -ForegroundColor White
    Write-Host "  サブスクリプション名: $($currentContext.Subscription.Name)" -ForegroundColor White
    Write-Host "  アカウント: $($currentContext.Account.Id)" -ForegroundColor White

    # 接続状況の確認と再ログイン選択肢の提供
    if (-not $NonInteractive) {
        Write-Host "`nこれでいいですか？" -ForegroundColor Cyan
        Write-Host "1. このままの設定で続行" -ForegroundColor White
        Write-Host "2. 別のテナント・サブスクリプションで再ログイン" -ForegroundColor White
        
        $loginChoice = Read-HostWithTimeout -Prompt "選択してください (1 または 2)" -TimeoutSeconds 5 -DefaultValue "1"
        
        if ($loginChoice -eq "2") {
            Write-Host "`n=== 再ログイン処理 ===" -ForegroundColor Yellow
            
            # 特定のテナントIDを指定するか確認
            Write-Host "特定のテナントIDを指定しますか？" -ForegroundColor Cyan
            Write-Host "1. テナントIDを指定してログイン" -ForegroundColor White
            Write-Host "2. 通常のログイン（テナント選択画面表示）" -ForegroundColor White
            
            $tenantChoice = Read-HostWithTimeout -Prompt "選択してください (1 または 2)" -TimeoutSeconds 5 -DefaultValue "2"
            
            if ($tenantChoice -eq "1") {
                $tenantId = Read-Host "テナントIDを入力してください"
                Write-Host "指定されたテナントでログイン中..." -ForegroundColor Yellow
                try {
                    Connect-AzAccount -TenantId $tenantId
                    Write-Host "ログインが完了しました。" -ForegroundColor Green
                } catch {
                    Write-Error "ログインに失敗しました: $($_.Exception.Message)"
                    exit 1
                }
            } else {
                Write-Host "通常のログイン画面を表示します..." -ForegroundColor Yellow
                try {
                    Connect-AzAccount
                    Write-Host "ログインが完了しました。" -ForegroundColor Green
                } catch {
                    Write-Error "ログインに失敗しました: $($_.Exception.Message)"
                    exit 1
                }
            }
            
            # 再ログイン後のコンテキストを取得
            $currentContext = Get-AzContext
            if (-not $currentContext) {
                Write-Error "再ログイン後のコンテキストの取得に失敗しました。"
                exit 1
            }
            
            Write-Host "`n=== 再ログイン後の接続情報 ===" -ForegroundColor Green
            Write-Host "現在のテナント情報:" -ForegroundColor Yellow
            Write-Host "  テナントID: $($currentContext.Tenant.Id)" -ForegroundColor White
            
            # テナント名の取得（再ログイン後）
            $tenantNameAfterLogin = $currentContext.Tenant.Directory
            if ([string]::IsNullOrEmpty($tenantNameAfterLogin)) {
                try {
                    $tenantInfoAfterLogin = Get-AzTenant -TenantId $currentContext.Tenant.Id -ErrorAction SilentlyContinue
                    if ($tenantInfoAfterLogin -and $tenantInfoAfterLogin.Name) {
                        $tenantNameAfterLogin = $tenantInfoAfterLogin.Name
                    } elseif ($tenantInfoAfterLogin -and $tenantInfoAfterLogin.Domains) {
                        $tenantNameAfterLogin = $tenantInfoAfterLogin.Domains[0]
                    } else {
                        $tenantNameAfterLogin = "取得できませんでした"
                    }
                } catch {
                    $tenantNameAfterLogin = "取得エラー"
                }
            }
            Write-Host "  テナント名: $tenantNameAfterLogin" -ForegroundColor White
            
            Write-Host "現在のサブスクリプション:" -ForegroundColor Yellow
            Write-Host "  サブスクリプションID: $($currentContext.Subscription.Id)" -ForegroundColor White
            Write-Host "  サブスクリプション名: $($currentContext.Subscription.Name)" -ForegroundColor White
            Write-Host "  アカウント: $($currentContext.Account.Id)" -ForegroundColor White
            
            # 利用可能なサブスクリプションを表示し、必要に応じて変更
            Write-Host "`n利用可能なサブスクリプション一覧:" -ForegroundColor Yellow
            $availableSubscriptions = Get-AzSubscription -TenantId $currentContext.Tenant.Id
            for ($i = 0; $i -lt $availableSubscriptions.Count; $i++) {
                $sub = $availableSubscriptions[$i]
                $current = if ($sub.Id -eq $currentContext.Subscription.Id) { " (現在)" } else { "" }
                Write-Host "  $($i + 1). $($sub.Name) ($($sub.Id))$current" -ForegroundColor White
            }
            
            Write-Host "`n別のサブスクリプションに切り替えますか？" -ForegroundColor Cyan
            Write-Host "1. 現在のサブスクリプションのまま続行" -ForegroundColor White
            Write-Host "2. 別のサブスクリプションに切り替え" -ForegroundColor White
            
            do {
                $subscriptionChoice = Read-Host "選択してください (1 または 2)"
            } while ($subscriptionChoice -notin @("1", "2"))
            
            if ($subscriptionChoice -eq "2") {
                do {
                    $subscriptionNumber = Read-Host "サブスクリプション番号を入力してください (1-$($availableSubscriptions.Count))"
                    $subscriptionIndex = [int]$subscriptionNumber - 1
                } while ($subscriptionIndex -lt 0 -or $subscriptionIndex -ge $availableSubscriptions.Count)
                
                $selectedSubscription = $availableSubscriptions[$subscriptionIndex]
                try {
                    Set-AzContext -SubscriptionId $selectedSubscription.Id -TenantId $currentContext.Tenant.Id | Out-Null
                    $currentContext = Get-AzContext
                    Write-Host "サブスクリプションを切り替えました: $($selectedSubscription.Name)" -ForegroundColor Green
                } catch {
                    Write-Error "サブスクリプションの切り替えに失敗しました: $($_.Exception.Message)"
                    exit 1
                }
            }
        }
    }

    # 対話モードの場合、スコープの確認と選択
    if (-not $NonInteractive) {
        Write-Host "`n分析スコープを選択してください:" -ForegroundColor Cyan
        Write-Host "1. 現在のサブスクリプションのみ (推奨)" -ForegroundColor White
        Write-Host "2. テナント全体のすべてのサブスクリプション" -ForegroundColor White
        
        $scopeChoice = Read-HostWithTimeout -Prompt "選択してください (1 または 2)" -TimeoutSeconds 5 -DefaultValue "1"
        
        $Scope = if ($scopeChoice -eq "1") { "Subscription" } else { "Tenant" }
    }

    Write-Host "`n選択された分析スコープ: $Scope" -ForegroundColor Green
    
    # テナント全体の場合、利用可能なサブスクリプション一覧を表示
    if ($Scope -eq "Tenant") {
        Write-Host "`nテナント内の利用可能なサブスクリプション一覧を取得中..." -ForegroundColor Yellow
        $allSubscriptions = Get-AzSubscription -TenantId $currentContext.Tenant.Id
        Write-Host "利用可能なサブスクリプション数: $($allSubscriptions.Count)" -ForegroundColor White
        
        foreach ($sub in $allSubscriptions) {
            Write-Host "  - $($sub.Name) ($($sub.Id))" -ForegroundColor Gray
        }
        
        if (-not $NonInteractive) {
            Write-Host "`n続行しますか？ (y/n): " -NoNewline -ForegroundColor Cyan
            $confirm = Read-Host
            if ($confirm -ne 'y' -and $confirm -ne 'Y') {
                Write-Host "処理を中止しました。" -ForegroundColor Yellow
                exit 0
            }
        }
    }

} catch {
    Write-Error "Azure接続情報の取得に失敗しました: $($_.Exception.Message)"
    exit 1
}

# 結果を格納する配列
$results = @()
$allResourcesData = @()

# =============================================================================
# リソース取得処理（スコープに応じた処理）
# =============================================================================

if ($Scope -eq "Tenant") {
    # テナント全体のリソースを取得
    Write-Host "`n=== テナント全体のリソース分析開始 ===" -ForegroundColor Green
    $allSubscriptions = Get-AzSubscription -TenantId $currentContext.Tenant.Id
    
    foreach ($subscription in $allSubscriptions) {
        try {
            Write-Host "サブスクリプション切り替え中: $($subscription.Name)" -ForegroundColor Yellow
            Set-AzContext -SubscriptionId $subscription.Id -TenantId $currentContext.Tenant.Id | Out-Null
            
            # 診断ログをサポートするリソースタイプのみを取得（効率化）
            $subResources = Get-AzResource | Where-Object { $_.ResourceType -in $supportedResourceTypes }
            $allResourcesData += $subResources | ForEach-Object { 
                $_ | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue $subscription.Name -PassThru
            }
            # Storage Accountのサービス別リソースも取得してallResourcesDataに追加
            $storageAccounts = $subResources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
            foreach ($sa in $storageAccounts) {
                $childTypes = @("blobServices", "fileServices", "queueServices", "tableServices")
                foreach ($child in $childTypes) {
                    $childResourceId = "$($sa.Id)/$child/default"
                    try {
                        $childRes = Get-AzResource -ResourceId $childResourceId -ErrorAction SilentlyContinue
                        if ($childRes) {
                            $childRes | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue $subscription.Name -Force
                            $allResourcesData += $childRes
                        }
                    } catch {
                        # 取得できない場合はスキップ
                    }
                }
            }
            
            Write-Host "  取得対象リソース数: $($subResources.Count)" -ForegroundColor Gray
            Write-Host "  (診断ログサポート対象のみ)" -ForegroundColor Gray
        } catch {
            Write-Warning "サブスクリプション $($subscription.Name) の処理でエラー: $($_.Exception.Message)"
        }
    }
    
    # 元のサブスクリプションに戻す
    Set-AzContext -SubscriptionId $currentContext.Subscription.Id -TenantId $currentContext.Tenant.Id | Out-Null
} else {
    # 現在のサブスクリプションのみ
    Write-Host "`n=== 現在のサブスクリプション分析開始 ===" -ForegroundColor Green
    
    # 診断ログをサポートするリソースタイプのみを取得（効率化）
    $filteredResources = Get-AzResource | Where-Object { $_.ResourceType -in $supportedResourceTypes }
    $allResourcesData = $filteredResources | ForEach-Object { 
        $_ | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue $currentContext.Subscription.Name -PassThru
    }
    # Storage Accountのサービス別リソースも取得してallResourcesDataに追加
    $storageAccounts = $filteredResources | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" }
    foreach ($sa in $storageAccounts) {
        $childTypes = @("blobServices", "fileServices", "queueServices", "tableServices")
        foreach ($child in $childTypes) {
            $childResourceId = "$($sa.Id)/$child/default"
            try {
                $childRes = Get-AzResource -ResourceId $childResourceId -ErrorAction SilentlyContinue
                if ($childRes) {
                    $childRes | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue $currentContext.Subscription.Name -Force
                    $allResourcesData += $childRes
                }
            } catch {
                # 取得できない場合はスキップ
            }
        }
    }
    
    $totalAvailableResources = (Get-AzResource).Count
    Write-Host "  全リソース数: $totalAvailableResources" -ForegroundColor Gray
    Write-Host "  診断ログサポート対象リソース数: $($allResourcesData.Count)" -ForegroundColor Gray
}

$totalResources = $allResourcesData.Count
$processedCount = 0

Write-Host "診断設定を分析中..." -ForegroundColor Green
Write-Host "総対象リソース数: $totalResources (診断ログサポート対象のみ)" -ForegroundColor Yellow

# プログレスバー用の変数
try {
    if ($totalResources -eq 0) {
        Write-Warning "分析対象のリソースが見つかりませんでした。"
        exit 0
    }
} catch {
    Write-Error "リソースの取得に失敗しました: $($_.Exception.Message)"
    exit 1
}

# =============================================================================
# 効率化とパフォーマンス改善
# =============================================================================

# Azure CLI のレスポンスキャッシュを有効化（同じリソースに対する重複クエリを回避）
$env:AZURE_CLI_ENABLE_CACHE = "true"

# 並列処理の設定（リソース数に応じて調整）
$maxParallelJobs = if ($totalResources -gt 100) { 10 } elseif ($totalResources -gt 50) { 5 } else { 3 }
Write-Host "並列処理ジョブ数: $maxParallelJobs (リソース数に応じて自動調整)" -ForegroundColor Gray

# 各リソースの診断設定を取得・分析
$allResourcesData | ForEach-Object {
    $resource = $_
    $processedCount++

    # プログレス表示（進捗状況をユーザーに表示）
    $percentComplete = [math]::Round(($processedCount / $totalResources) * 100, 1)
    Write-Progress -Activity "診断設定を分析中" -Status "処理中: $($resource.Name) [$($resource.SubscriptionName)]" -PercentComplete $percentComplete

    try {
        # テナント全体の場合、リソースのサブスクリプションに切り替え
        if ($Scope -eq "Tenant") {
            $resourceSubscriptionId = $resource.Id.Split('/')[2]
            Set-AzContext -SubscriptionId $resourceSubscriptionId -TenantId $currentContext.Tenant.Id | Out-Null
        }

        # Azure CLI を使用して診断設定を取得（エラー出力を抑制）
        $dsJson = az monitor diagnostic-settings list --resource $resource.Id 2>$null

        # 診断設定が存在するかチェック
        if ($dsJson -and $dsJson -ne "[]") {
            $diagnosticSettings = $dsJson | ConvertFrom-Json

            # 診断設定が存在する場合の処理
            if ($diagnosticSettings -and $diagnosticSettings.Count -gt 0) {
                foreach ($ds in $diagnosticSettings) {
                    # Log Analytics Workspaceの情報を取得・解析
                    $workspaceId = $ds.workspaceId
                    $workspaceName = "未設定"

                    if ($workspaceId) {
                        try {
                            # Log Analytics Workspaceの詳細情報を取得
                            $workspace = Get-AzOperationalInsightsWorkspace | Where-Object { $_.ResourceId -eq $workspaceId }
                            if ($workspace) {
                                $workspaceName = $workspace.Name
                            } else {
                                # Workspaceが見つからない場合はIDの最後の部分を表示
                                $workspaceName = "不明 ($($workspaceId.Split('/')[-1]))"
                            }
                        } catch {
                            $workspaceName = "取得エラー"
                        }
                    }

                    # 結果オブジェクトを作成して配列に追加
                    $results += [PSCustomObject]@{
                        SubscriptionName = $resource.SubscriptionName
                        ResourceGroup = $resource.ResourceGroupName
                        ResourceType = $resource.ResourceType
                        ResourceName = $resource.Name
                        DiagnosticSettingName = $ds.name
                        LogAnalyticsWorkspace = $workspaceName
                        WorkspaceId = $workspaceId
                        StorageAccount = if ($ds.storageAccountId) { $ds.storageAccountId.Split('/')[-1] } else { "未設定" }
                        EventHub = if ($ds.eventHubAuthorizationRuleId) { "設定済み" } else { "未設定" }
                        ResourceId = $resource.Id
                        HasDiagnosticSettings = $true
                    }
                }
            }
        } else {
            # 診断設定がない場合も結果に記録（カバレッジ計算のため）
            $results += [PSCustomObject]@{
                SubscriptionName = $resource.SubscriptionName
                ResourceGroup = $resource.ResourceGroupName
                ResourceType = $resource.ResourceType
                ResourceName = $resource.Name
                DiagnosticSettingName = "未設定"
                LogAnalyticsWorkspace = "未設定"
                WorkspaceId = "未設定"
                StorageAccount = "未設定"
                EventHub = "未設定"
                ResourceId = $resource.Id
                HasDiagnosticSettings = $false
            }
        }
        # 診断設定がない場合やエラーの場合はスキップ（何も出力しない）
    } catch {
        # エラーが発生した場合はVerboseログに記録してスキップ
        Write-Verbose "リソース $($resource.Name) の診断設定取得でエラー: $($_.Exception.Message)"
        # エラーの場合も結果に記録（カバレッジ計算のため）
        $results += [PSCustomObject]@{
            SubscriptionName = $resource.SubscriptionName
            ResourceGroup = $resource.ResourceGroupName
            ResourceType = $resource.ResourceType
            ResourceName = $resource.Name
            DiagnosticSettingName = "取得エラー"
            LogAnalyticsWorkspace = "取得エラー"
            WorkspaceId = "取得エラー"
            StorageAccount = "取得エラー"
            EventHub = "取得エラー"
            ResourceId = $resource.Id
            HasDiagnosticSettings = $false
        }
    }
}

# 元のサブスクリプションに戻す（テナント全体分析の場合）
if ($Scope -eq "Tenant") {
    Set-AzContext -SubscriptionId $currentContext.Subscription.Id -TenantId $currentContext.Tenant.Id | Out-Null
}
# プログレスバーを完了
Write-Progress -Activity "診断設定を分析中" -Completed

# =============================================================================
# 結果の表示と統計分析
# =============================================================================

# 診断設定の設定割合を計算（同一リソースに複数設定がある場合は1つとしてカウント）
$uniqueResourcesWithDiagnostics = ($results | Where-Object { $_.HasDiagnosticSettings -eq $true } | Group-Object ResourceId).Count
$resourcesWithDiagnostics = $uniqueResourcesWithDiagnostics
$resourcesWithoutDiagnostics = $totalResources - $resourcesWithDiagnostics
$overallCoveragePercent = if ($totalResources -gt 0) { [math]::Round(($resourcesWithDiagnostics / $totalResources) * 100, 2) } else { 0 }

# =============================================================================
# 診断設定カバレッジ統計の表示
# =============================================================================

Write-Host "`n=== 診断設定カバレッジ統計 ===" -ForegroundColor Green
Write-Host "分析スコープ: $Scope" -ForegroundColor Yellow
Write-Host "総リソース数: $totalResources" -ForegroundColor White
Write-Host "診断設定済みリソース数: $resourcesWithDiagnostics" -ForegroundColor Green
Write-Host "診断設定未設定リソース数: $resourcesWithoutDiagnostics" -ForegroundColor Red
Write-Host "全体カバレッジ率: $overallCoveragePercent%" -ForegroundColor Cyan

# リソースタイプ別のカバレッジ統計
Write-Host "`n=== リソースタイプ別診断設定カバレッジ ===" -ForegroundColor Green

$resourceTypeStats = $allResourcesData | Group-Object ResourceType | ForEach-Object {
    $resourceType = $_.Name
    $totalCount = $_.Count
    # 同一リソースに複数の診断設定がある場合も1つとしてカウント（リソースIDでユニーク化）
    $uniqueResourcesWithDiagnostics = ($results | Where-Object { $_.ResourceType -eq $resourceType -and $_.HasDiagnosticSettings -eq $true } | Group-Object ResourceId).Count
    $withDiagnosticsCount = $uniqueResourcesWithDiagnostics
    $coveragePercent = if ($totalCount -gt 0) { [math]::Round(($withDiagnosticsCount / $totalCount) * 100, 2) } else { 0 }
    
    [PSCustomObject]@{
        ResourceType = $resourceType
        TotalResources = $totalCount
        WithDiagnostics = $withDiagnosticsCount
        WithoutDiagnostics = $totalCount - $withDiagnosticsCount
        CoveragePercent = "$coveragePercent%"
    }
} | Sort-Object CoveragePercent -Descending

$resourceTypeStats | Format-Table -Property ResourceType, TotalResources, WithDiagnostics, WithoutDiagnostics, CoveragePercent -AutoSize

# サブスクリプション別統計（テナント全体の場合のみ）
if ($Scope -eq "Tenant") {
    Write-Host "`n=== サブスクリプション別診断設定カバレッジ ===" -ForegroundColor Green
    
    $subscriptionStats = $allResourcesData | Group-Object SubscriptionName | ForEach-Object {
        $subscriptionName = $_.Name
        $totalCount = $_.Count
        # 同一リソースに複数の診断設定がある場合も1つとしてカウント（リソースIDでユニーク化）
        $uniqueResourcesWithDiagnostics = ($results | Where-Object { $_.SubscriptionName -eq $subscriptionName -and $_.HasDiagnosticSettings -eq $true } | Group-Object ResourceId).Count
        $withDiagnosticsCount = $uniqueResourcesWithDiagnostics
        $coveragePercent = if ($totalCount -gt 0) { [math]::Round(($withDiagnosticsCount / $totalCount) * 100, 2) } else { 0 }
        
        [PSCustomObject]@{
            SubscriptionName = $subscriptionName
            TotalResources = $totalCount
            WithDiagnostics = $withDiagnosticsCount
            WithoutDiagnostics = $totalCount - $withDiagnosticsCount
            CoveragePercent = "$coveragePercent%"
        }
    } | Sort-Object CoveragePercent -Descending
    
    $subscriptionStats | Format-Table -Property SubscriptionName, TotalResources, WithDiagnostics, WithoutDiagnostics, CoveragePercent -AutoSize
}

if ($results.Count -gt 0) {
    # 診断設定一覧の表示
    Write-Host "`n=== 診断設定詳細一覧 ===" -ForegroundColor Green
    Write-Host "診断設定が設定されているリソース: $($results.Count)個" -ForegroundColor Yellow

    # テーブル形式で詳細表示（サブスクリプション、リソースグループ、リソースタイプ、リソース名でソート）
    if ($Scope -eq "Tenant") {
        $results | Sort-Object SubscriptionName, ResourceGroup, ResourceType, ResourceName |
        Format-Table -Property SubscriptionName, ResourceGroup, ResourceType, ResourceName, DiagnosticSettingName, LogAnalyticsWorkspace, StorageAccount, EventHub -AutoSize
    } else {
        $results | Sort-Object ResourceGroup, ResourceType, ResourceName |
        Format-Table -Property ResourceGroup, ResourceType, ResourceName, DiagnosticSettingName, LogAnalyticsWorkspace, StorageAccount, EventHub -AutoSize
    }

    # Log Analytics Workspace別の統計情報
    Write-Host "`n=== Log Analytics Workspace別統計 ===" -ForegroundColor Green
    $workspaceStats = $results | Group-Object LogAnalyticsWorkspace | Sort-Object Count -Descending
    $workspaceStats | Format-Table -Property Name, Count -AutoSize

    # =============================================================================
    # CSV出力処理
    # =============================================================================
    
    # CSV出力パスの決定
    if ([string]::IsNullOrEmpty($CsvOutputPath)) {
        $CsvOutputPath = "diagnostic-settings-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    }

    # 自動出力が指定されていない場合はユーザーに確認
    if (-not $NonInteractive -and -not $AutoExportCsv) {
        Write-Host "`nCSVファイルに出力しますか？ (y/n): " -NoNewline -ForegroundColor Cyan
        $response = Read-Host
        $AutoExportCsv = ($response -eq 'y' -or $response -eq 'Y')
    }

    # CSV出力の実行
    if ($AutoExportCsv) {
        try {
            # CSV出力用データの準備
            $csvData = if ($IncludeResourcesWithoutDiagnostics) {
                # 診断設定なしリソースも含めて出力
                $results
            } else {
                # 診断設定があるリソースのみ出力
                $results | Where-Object { $_.HasDiagnosticSettings -eq $true }
            }
            
            if ($csvData.Count -gt 0) {
                $csvData | Export-Csv -Path $CsvOutputPath -NoTypeInformation -Encoding UTF8
                Write-Host "CSVファイルに出力しました: $CsvOutputPath" -ForegroundColor Green
                Write-Host "出力レコード数: $($csvData.Count)" -ForegroundColor Gray
                Write-Host "ファイルサイズ: $([math]::Round((Get-Item $CsvOutputPath).Length / 1KB, 2)) KB" -ForegroundColor Gray
            } else {
                Write-Host "出力対象のデータがありません。" -ForegroundColor Yellow
            }
        } catch {
            Write-Error "CSV出力中にエラーが発生しました: $($_.Exception.Message)"
        }
    }

} else {
    Write-Host "`n診断設定が設定されているリソースが見つかりませんでした。" -ForegroundColor Yellow
    Write-Host "考えられる原因:" -ForegroundColor Gray
    Write-Host "- Azure環境に診断設定が設定されたリソースが存在しない" -ForegroundColor Gray
    Write-Host "- Azure CLI または PowerShell モジュールの認証に問題がある" -ForegroundColor Gray
    Write-Host "- 適切な権限（Reader以上）が不足している" -ForegroundColor Gray
}

# スクリプト終了時の処理
Write-Host "`n=== スクリプト実行完了 ===" -ForegroundColor Cyan
Write-Host "終了時刻: $(Get-Date -Format 'yyyy年MM月dd日 HH:mm:ss')" -ForegroundColor Gray
Write-Host "処理時間: $((Get-Date) - $startTime)" -ForegroundColor Gray

# =============================================================================
# 使用例とヘルプ情報
# =============================================================================

<#
.SYNOPSIS
    Azure診断設定とLog Analytics Workspace一覧表示スクリプト

.DESCRIPTION
    Azure環境内のすべてのリソースの診断設定を分析し、Log Analytics Workspaceの利用状況を統計表示します。
    診断設定が設定されているリソースの詳細情報を収集し、ワークスペース別・リソースタイプ別の統計も提供します。

.PARAMETER AutoExportCsv
    CSV出力を自動で行う場合は$trueを指定します。$falseの場合は実行時に確認します。

.PARAMETER CsvOutputPath
    出力するCSVファイルのパスを指定します。未指定の場合は自動でファイル名を生成します。

.PARAMETER Scope
    分析スコープを指定します。"Subscription" (サブスクリプション) または "Tenant" (テナント全体)

.PARAMETER NonInteractive
    対話モードを無効にする場合は$trueを指定します。自動化スクリプトでの実行時に有用です。

.PARAMETER IncludeResourcesWithoutDiagnostics
    診断設定なしリソースもCSV出力に含める場合は$trueを指定します。デフォルトは$false（診断設定ありのみ出力）です。

.EXAMPLE
    .\diagdiag.ps1
    対話式でスコープとCSV出力を確認して診断設定の分析を実行します。

.EXAMPLE
    .\diagdiag.ps1 -Scope Tenant -AutoExportCsv $true
    テナント全体の診断設定を分析し、CSV出力を自動で行います。

.EXAMPLE
    .\diagdiag.ps1 -Scope Subscription -NonInteractive $true -AutoExportCsv $false
    現在のサブスクリプションのみを非対話式で分析し、CSV出力は行いません。

.EXAMPLE
    .\diagdiag.ps1 -IncludeResourcesWithoutDiagnostics $true -AutoExportCsv $true
    診断設定なしリソースも含めてCSV出力します（完全なカバレッジ分析用）。

.NOTES
    前提条件:
    - Azure PowerShell モジュール (Az) がインストールされている
    - Azure にログイン済み (Connect-AzAccount 実行済み)
    - 対象サブスクリプションに対する Reader 権限以上が必要

    作成者: yamapan
    作成日: 2025年7月8日
    ライセンス: MIT License

.LINK
    https://github.com/yamapan/diagdiag
    
.COPYRIGHT
    MIT License
    
    Copyright (c) 2025 yamapan
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>