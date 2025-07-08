# AzAnalyzeDiag - Azure 診断設定分析スクリプト

Azure 環境内のすべてのリソースの診断設定、リソースログ(診断設定)の設定状況を分析し、Log Analytics Workspace の利用状況を統計表示する PowerShell スクリプトです。

## 📋 対象リソース・準拠情報

### Microsoft Learn 公式ドキュメント準拠

- **準拠先**: [Azure Monitor リファレンス - ログ インデックス](https://learn.microsoft.com/ja-jp/azure/azure-monitor/reference/logs-index)
- **対象リソース数**: **159 種類** のリソースログサポート対象リソースタイプ
- **効率化**: ログカテゴリ「N/A」のリソース（メトリクスのみサポート）を事前除外して高速分析

### 🎯 分析対象リソースタイプ一覧

<details>
<summary><strong>対象リソース一覧（約159種類・リソースログ限定）</strong> - クリックして展開</summary>

#### 🔐 認証・セキュリティ

- **Microsoft.AAD**: Domain Services
- **Microsoft.KeyVault**: Key Vault、Managed HSM
- **Microsoft.Security**: Anti-malware Settings、Defender for Storage Settings
- **Microsoft.SecurityInsights**: Sentinel Settings
- **Microsoft.Attestation**: Attestation Providers

#### 💾 コンピュート・コンテナ

- **Microsoft.Compute**: Virtual Machines、Virtual Machine Scale Sets
- **Microsoft.ContainerInstance**: Container Groups
- **Microsoft.ContainerRegistry**: Container Registries
- **Microsoft.ContainerService**: AKS Managed Clusters、Fleets
- **Microsoft.App**: Container Apps Managed Environments
- **Microsoft.Batch**: Batch Accounts

#### 🌐 ネットワーク

- **Microsoft.Network**: Application Gateways、Azure Firewalls、Bastion Hosts、Express Route Circuits、Front Doors、Load Balancers、Network Security Groups、Public IP Addresses、Traffic Manager Profiles、Virtual Network Gateways、VPN Gateways、P2S VPN Gateways、Virtual Networks、Network Interfaces、Private Endpoints、Private Link Services

#### 💿 ストレージ・データベース

- **Microsoft.Storage**: ⚡**階層別詳細分析** - Storage Account 全体 + Blob Services、File Services、Queue Services、Table Services（親・子リソース両方を個別に診断設定分析）
- **Microsoft.Sql**: SQL Managed Instances、SQL Databases、SQL Servers
- **Microsoft.DocumentDB**: Cosmos DB、Cassandra Clusters、Mongo Clusters
- **Microsoft.DBforMySQL**: Flexible Servers、MySQL Servers
- **Microsoft.DBforPostgreSQL**: Flexible Servers、PostgreSQL Servers、Server Groups v2
- **Microsoft.DBforMariaDB**: MariaDB Servers

#### 🔍 分析・AI・ML

- **Microsoft.AnalysisServices**: Analysis Services Servers
- **Microsoft.CognitiveServices**: Cognitive Services Accounts
- **Microsoft.MachineLearningServices**: ML Registries、ML Workspaces、Online Endpoints
- **Microsoft.DataFactory**: Data Factories
- **Microsoft.DataLakeAnalytics**: Data Lake Analytics Accounts
- **Microsoft.DataLakeStore**: Data Lake Store Accounts
- **Microsoft.StreamAnalytics**: Stream Analytics Jobs
- **Microsoft.Synapse**: Synapse Workspaces、Big Data Pools、Kusto Pools、SQL Pools
- **Microsoft.Purview**: Purview Accounts

#### 🔌 統合・メッセージング

- **Microsoft.EventHub**: Event Hub Namespaces
- **Microsoft.EventGrid**: Topics、Domains、Partner Topics、System Topics
- **Microsoft.ServiceBus**: Service Bus Namespaces
- **Microsoft.Logic**: Logic Apps、Integration Accounts
- **Microsoft.Relay**: Relay Namespaces
- **Microsoft.SignalRService**: SignalR、WebPubSub、Replicas

#### 🌍 Web・アプリケーション

- **Microsoft.Web**: App Services、Deployment Slots、App Service Plans、Static Web Apps、Hosting Environments
- **Microsoft.ApiManagement**: API Management Services、Workspaces
- **Microsoft.Cdn**: CDN Profiles、Endpoints、WAF Policies

#### 📊 監視・管理

- **Microsoft.Insights**: Application Insights、Autoscale Settings、Data Collection Rules
- **Microsoft.OperationalInsights**: Log Analytics Workspaces
- **Microsoft.Monitor**: Monitor Accounts
- **Microsoft.Automation**: Automation Accounts
- **Microsoft.RecoveryServices**: Recovery Services Vaults
- **Microsoft.DataProtection**: Backup Vaults

#### 🖥️ 仮想デスクトップ・開発

- **Microsoft.DesktopVirtualization**: App Attach Packages、Application Groups、Host Pools、Repository Folders、Scaling Plans、Workspaces
- **Microsoft.DevCenter**: Dev Centers
- **Microsoft.AppPlatform**: Spring Apps
- **Microsoft.AppConfiguration**: Configuration Stores

#### 📱 特殊・その他サービス

- **Microsoft.Media**: Media Services、Video Analyzers
- **Microsoft.Communication**: Communication Services
- **Microsoft.Devices**: IoT Hubs、Provisioning Services
- **Microsoft.Search**: Search Services
- **Microsoft.Cache**: Redis、Redis Enterprise Databases
- **Microsoft.PowerBI**: PowerBI Tenants、Workspaces
- **Microsoft.PowerBIDedicated**: PowerBI Dedicated Capacities
- **Microsoft.TimeSeriesInsights**: Time Series Insights Environments、Event Sources
- **Microsoft.Edge**: Edge Diagnostics（新規追加）
- **Microsoft.HealthDataAIServices**: Health Data AI Services（新規追加）
- **Microsoft.singularity**: Singularity Accounts（新規追加）
- **Microsoft.StandbyPool**: Standby Container Group Pools、Standby VM Pools（新規追加）
- **Microsoft.PlayFab**: PlayFab Titles
- **Microsoft.BotService**: Bot Services
- **Microsoft.Avs**: Azure VMware Solution Private Clouds
- **Microsoft.HealthcareApis**: Healthcare APIs、DICOM Services、FHIR Services、IoT Connectors

#### 🧪 新興・実験的サービス

- **Microsoft.AgFoodPlatform**: FarmBeats
- **Microsoft.AzurePlaywrightService**: Playwright Accounts
- **Microsoft.AzureSphere**: Azure Sphere Catalogs
- **Microsoft.AzureDataTransfer**: Data Transfer Connections/Flows
- **Microsoft.Chaos**: Chaos Experiments
- **Microsoft.CodeSigning**: Code Signing Accounts
- **Microsoft.Community**: Community Trainings
- **Microsoft.DataReplication**: Data Replication Vaults
- **Microsoft.DataShare**: Data Share Accounts
- **Microsoft.ManagedNetworkFabric**: Network Devices
- **Microsoft.OpenLogisticsPlatform**: Workspaces
- **Microsoft.Orbital**: Geocatalogs
- **Microsoft.ServiceNetworking**: Traffic Controllers
- **Microsoft.Singularity**: Singularity Accounts
- **Microsoft.StandbyPool**: Standby Container Group Pools、Standby VM Pools
- **Microsoft.WorkloadMonitor**: Workload Monitors

#### 🏛️ レガシー・特殊

- **Microsoft.ClassicNetwork**: Classic Network Security Groups
- **Microsoft.ProviderHub**: Provider Monitor Settings、Provider Registrations
- **Microsoft.AutonomousDevelopmentPlatform**: Accounts、Workspaces

</details>

## 機能

### 🔍 主要機能

- **診断設定の全体分析**: 対象リソースの診断設定状況を包括的に分析
- **カバレッジ統計**: 診断設定済み/未設定リソースの割合を表示
- **Log Analytics Workspace 統計**: ワークスペース別の利用状況を表示
- **リソースタイプ別統計**: タイプ別の診断設定状況を表示（Storage Account は階層別詳細分析）
- **CSV 出力機能**: 分析結果を CSV ファイルにエクスポート
- **タイムアウト付き対話機能**: 5 秒タイムアウトで自動進行（デフォルト値使用）
- **再ログイン機能**: テナント/サブスクリプション切り替えのための再認証

### 📊 分析対象

- **サブスクリプション単位**: 現在のサブスクリプションのみ（推奨・高速）
- **テナント全体**: テナント内のすべてのサブスクリプションを横断分析
- **スマートフィルタリング**: Microsoft Learn 準拠の 158 種類のリソースタイプのみを対象
- **効率化**: 診断ログ非対応リソースを事前除外し、分析時間を大幅短縮
- **重複排除**: 同一リソースに複数診断設定がある場合の適切なカウント

## 前提条件

### 必要なツール

```powershell
# Azure PowerShell モジュール
Install-Module -Name Az -Force -AllowClobber

# Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli からインストール
```

### 認証と権限

```powershell
# Azure PowerShell でログイン
Connect-AzAccount

# Azure CLI でログイン
az login
```

**必要な権限**: 対象サブスクリプション/テナントに対する **Reader** 権限以上

## ⚠️ 重要な注意事項

- **テスト状況**: すべてのリソースタイプでの動作確認は完了していません
- **フィードバック歓迎**: 問題や改善点があれば Issue でお知らせください

## 使用方法

### 🖼️ 使用イメージ

<details>
<summary><strong>実行画面のサンプル</strong> - クリックして表示</summary>

#### 診断設定分析実行画面

<img width="400" alt="診断設定分析実行画面" src="https://github.com/user-attachments/assets/82ee95b6-38df-4e05-88f5-5c9a04652a1a" />

#### 分析結果表示画面

<img width="400" alt="分析結果表示画面" src="https://github.com/user-attachments/assets/d2f923a8-d2e1-4443-8a6b-7f0bf86902c5" />

</details>

### ✨ 新機能: タイムアウト付き対話入力

- **自動進行**: 選択入力で 5 秒タイムアウト後、デフォルト値で自動進行
- **効率的な実行**: 長時間の待機なしで分析を継続
- **ユーザビリティ向上**: 手動操作とスクリプト実行の両立

### 🔄 再ログイン・切り替え機能

- **テナント切り替え**: 実行中に別のテナントへの再ログイン
- **サブスクリプション切り替え**: ログイン後の利用可能サブスクリプション選択
- **柔軟な認証**: 特定テナント ID または通常ログインを選択可能

### 🖼️ 実行画面イメージ

<img src="https://github.com/user-attachments/assets/82ee95b6-38df-4e05-88f5-5c9a04652a1a" alt="AzAnalyzeDiag実行画面1 - Azure接続情報と対話選択" width="400">

_Azure 接続情報の確認と再ログイン選択画面_

<img src="https://github.com/user-attachments/assets/d2f923a8-d2e1-4443-8a6b-7f0bf86902c5" alt="AzAnalyzeDiag実行画面2 - 診断設定分析結果表示" width="400">

_診断設定分析結果とカバレッジ統計の表示画面_

### 基本的な実行方法

```powershell
# 対話式実行（推奨）- タイムアウト付き
.\AzAnalyzeDiag.ps1

# 現在のサブスクリプションのみ分析
.\AzAnalyzeDiag.ps1 -Scope Subscription

# テナント全体を分析
.\AzAnalyzeDiag.ps1 -Scope Tenant
```

### パラメーター詳細

| パラメーター                         | 型     | デフォルト       | 説明                                                      |
| ------------------------------------ | ------ | ---------------- | --------------------------------------------------------- |
| `AutoExportCsv`                      | bool   | `$false`         | CSV 出力を自動実行                                        |
| `CsvOutputPath`                      | string | 自動生成         | CSV 出力ファイルパス                                      |
| `Scope`                              | string | `"Subscription"` | 分析スコープ（`Subscription` / `Tenant`）                 |
| `NonInteractive`                     | bool   | `$false`         | 対話モード無効化                                          |
| `IncludeResourcesWithoutDiagnostics` | bool   | `$false`         | 診断設定なしリソースも CSV 出力（完全なカバレッジ分析用） |

## 実行例

### 例 1: 基本的な対話式実行（新機能）

```powershell
.\AzAnalyzeDiag.ps1
```

**実行フロー**:

1. Azure 接続情報の確認・表示
2. **再ログイン選択** (5 秒タイムアウト、デフォルト：続行)
3. **分析スコープ選択** (5 秒タイムアウト、デフォルト：Subscription)
4. 診断設定分析の実行
5. CSV 出力確認

### 例 2: テナント全体の自動分析

```powershell
.\AzAnalyzeDiag.ps1 -Scope Tenant -AutoExportCsv $true -NonInteractive $true
```

**結果**:

- テナント内全サブスクリプションを自動分析
- CSV 自動出力
- 対話なしで完全自動実行

### 例 3: 完全なカバレッジ分析

```powershell
.\AzAnalyzeDiag.ps1 -IncludeResourcesWithoutDiagnostics $true -AutoExportCsv $true
```

**結果**:

- 診断設定なしリソースも含めて分析
- 完全なカバレッジ状況を CSV 出力

### 例 4: 再ログイン機能の活用

```powershell
# スクリプト実行中にテナント/サブスクリプション切り替え
.\AzAnalyzeDiag.ps1
# 実行中に以下の選択が可能：
# 1. 現在の設定で続行 (デフォルト、5秒タイムアウト)
# 2. 別のテナント・サブスクリプションで再ログイン
#   → 特定テナントIDでログイン または 通常ログイン選択
#   → 利用可能サブスクリプション一覧表示・選択
```

### 例 5: カスタム CSV パス指定

```powershell
.\AzAnalyzeDiag.ps1 -CsvOutputPath "C:\Reports\azure-diag-$(Get-Date -Format 'yyyyMMdd').csv" -AutoExportCsv $true
```

## 🎛️ 対話機能詳細

### タイムアウト付き入力の動作

```
分析スコープを選択してください:
1. 現在のサブスクリプションのみ (推奨)
2. テナント全体のすべてのサブスクリプション
選択してください (1 または 2) (5秒でタイムアウト、デフォルト: 1):

# 5秒後自動的にデフォルト値(1)で進行
タイムアウトしました。デフォルト値 '1' を使用します。
```

### 再ログイン機能の詳細フロー

1. **現在の接続確認**: テナント情報・サブスクリプション情報の表示
2. **継続・再ログイン選択**: 現在の設定で続行 or 再ログイン
3. **ログイン方式選択**: 特定テナント ID 指定 or 通常ログイン
4. **サブスクリプション選択**: 利用可能サブスクリプション一覧から選択
5. **分析実行**: 選択された環境での診断設定分析

### 自動化対応

- **非対話モード**: `-NonInteractive $true` で全ての対話をスキップ
- **バッチ実行**: パラメーターによる完全自動実行
- **スケジュール実行**: Task Scheduler や cron での定期実行対応

## 出力内容

### � コンソール出力 vs CSV 出力の違い

**重要な違い**：コンソール出力と CSV 出力では含まれるデータの範囲と詳細度が異なります。

| 項目                     | コンソール出力                             | CSV 出力（デフォルト）                 | CSV 出力（完全版）                                        |
| ------------------------ | ------------------------------------------ | -------------------------------------- | --------------------------------------------------------- |
| **表示対象**             | 全リソース（診断設定あり/なし両方）        | 診断設定ありリソースのみ               | 全リソース（`-IncludeResourcesWithoutDiagnostics $true`） |
| **列の省略**             | 画面幅制限により右端列が省略される場合あり | 全列が完全に記録される                 | 全列が完全に記録される                                    |
| **Storage Account 詳細** | 省略される可能性あり                       | 完全に記録される                       | 完全に記録される                                          |
| **Event Hub 詳細**       | 省略される可能性あり                       | 完全に記録される                       | 完全に記録される                                          |
| **WorkspaceId**          | 表示されない                               | 完全なリソース ID が記録される         | 完全なリソース ID が記録される                            |
| **フィルタリング**       | なし                                       | デフォルトで診断設定ありのみ           | パラメータで制御可能                                      |
| **データ活用**           | 一時的な確認用                             | Excel 分析・レポート作成・自動化に最適 | 完全なカバレッジ分析に最適                                |

**推奨用途**：

- **コンソール出力**：クイックチェック・概要確認
- **CSV 出力（デフォルト）**：設定済みリソースの詳細分析
- **CSV 出力（完全版）**：カバレッジ分析・コンプライアンスチェック

### �📈 コンソール出力

#### 1. Azure 接続情報（新機能）

```
=== Azure接続情報の確認 ===
現在のテナント情報:
  テナントID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  テナント名: contoso.onmicrosoft.com
現在のサブスクリプション:
  サブスクリプションID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
  サブスクリプション名: Production Subscription
  アカウント: user@contoso.com
```

#### 2. 診断設定カバレッジ統計

```
=== 診断設定カバレッジ統計 ===
分析スコープ: Subscription
総リソース数: 156
診断設定済みリソース数: 89
診断設定未設定リソース数: 67
全体カバレッジ率: 57.05%
```

#### 3. リソースタイプ別カバレッジ

```
ResourceType                           TotalResources WithDiagnostics WithoutDiagnostics CoveragePercent
------------                           -------------- --------------- ------------------ ---------------
Microsoft.Storage/storageAccounts                     25              20                  5            80%
Microsoft.Storage/storageAccounts/blobServices        25              25                  0           100%
Microsoft.Storage/storageAccounts/fileServices        20              18                  2            90%
Microsoft.Storage/storageAccounts/queueServices       15              10                  5            67%
Microsoft.Storage/storageAccounts/tableServices       12               8                  4            67%
Microsoft.KeyVault/vaults                             12              12                  0           100%
Microsoft.Sql/servers/databases                        8               6                  2            75%
```

#### 4. 診断設定詳細一覧

```
ResourceGroup    ResourceType                                    ResourceName                     DiagnosticSettingName LogAnalyticsWorkspace
-------------    ------------                                    ------------                     --------------------- ---------------------
rg-production    Microsoft.Storage/storageAccounts/blobServices  mystorageaccount01/default       diag-blob-001         law-central-logs
rg-production    Microsoft.Storage/storageAccounts/fileServices  mystorageaccount01/default       diag-file-001         law-central-logs
rg-production    Microsoft.Storage/storageAccounts/queueServices mystorageaccount01/default       diag-queue-001        law-central-logs
rg-development   Microsoft.KeyVault/vaults                       kv-dev-secrets                   vault-diagnostics     law-security-logs
```

#### 5. Log Analytics Workspace 別統計

```
Name                Count
----                -----
law-central-logs       45
law-security-logs      28
未設定                  15
```

### 📄 CSV 出力

**🎯 CSV 出力の優位性**：

- **完全なデータ**：コンソール出力で省略される右端列も含め、すべてのデータが記録されます
- **詳細な Workspace 情報**：`WorkspaceId`列により完全なリソース ID が取得できます
- **柔軟なフィルタリング**：`-IncludeResourcesWithoutDiagnostics`パラメータで出力範囲を制御
- **データ分析対応**：Excel、Power BI、Python などでの詳細分析が可能

**📋 CSV 出力の使い分け**：

```powershell
# 🔍 診断設定済みリソースの詳細分析（デフォルト）
.\AzAnalyzeDiag.ps1 -AutoExportCsv $true

# 📊 完全なカバレッジ分析（診断設定なしリソースも含む）
.\AzAnalyzeDiag.ps1 -IncludeResourcesWithoutDiagnostics $true -AutoExportCsv $true
```

**📄 CSV 列の詳細説明**：

| 列名                    | 説明                         | コンソール表示        |
| ----------------------- | ---------------------------- | --------------------- |
| `SubscriptionName`      | サブスクリプション名         | ✅ 表示               |
| `ResourceGroup`         | リソースグループ名           | ✅ 表示               |
| `ResourceType`          | リソースタイプ               | ✅ 表示               |
| `ResourceName`          | リソース名                   | ✅ 表示               |
| `DiagnosticSettingName` | 診断設定名                   | ✅ 表示               |
| `LogAnalyticsWorkspace` | Log Analytics Workspace 名   | ⚠️ 省略される場合あり |
| `WorkspaceId`           | Workspace のリソース ID      | ❌ 表示されない       |
| `StorageAccount`        | ストレージアカウント設定     | ⚠️ 省略される場合あり |
| `EventHub`              | Event Hub 設定               | ⚠️ 省略される場合あり |
| `ResourceId`            | リソースの完全 ID            | ❌ 表示されない       |
| `HasDiagnosticSettings` | 診断設定の有無（True/False） | ❌ 表示されない       |

## パフォーマンス最適化

### 🚀 効率化機能

- **リソースタイプフィルタリング**: 診断ログ非対応リソースを事前除外
- **並列処理**: リソース数に応じた並列ジョブ数の自動調整
- **Azure CLI キャッシュ**: レスポンスキャッシュによる重複クエリ回避
- **プログレス表示**: リアルタイムの進捗状況表示

### リソース数別推定実行時間

| リソース数 | 推定実行時間 | 並列ジョブ数 |
| ---------- | ------------ | ------------ |
| 〜50       | 2-5 分       | 3            |
| 51-100     | 5-10 分      | 5            |
| 101+       | 10-20 分     | 10           |

## トラブルシューティング

### ❌ よくあるエラーと解決方法

#### 1. 認証エラー

```
エラー: Azureにログインしていません
```

**解決方法**:

```powershell
Connect-AzAccount
az login
```

#### 2. 権限不足エラー

```
エラー: 適切な権限（Reader以上）が不足している
```

**解決方法**:

- サブスクリプションまたはリソースグループに対する Reader 権限以上を付与
- 管理者に権限昇格を依頼

#### 3. Azure CLI エラー

```
エラー: Azure CLI または PowerShell モジュールの認証に問題がある
```

**解決方法**:

```powershell
# Azure CLI の再認証
az logout
az login

# PowerShell の再認証
Disconnect-AzAccount
Connect-AzAccount
```

#### 4. 大量リソース環境での実行

**問題**: テナント全体で数千リソースがある場合の実行時間
**解決方法**:

- サブスクリプション単位での分割実行
- 非対話モード（`-NonInteractive $true`）での自動化

### 🔧 デバッグ情報の取得

```powershell
# 詳細ログ出力
.\AzAnalyzeDiag.ps1 -Verbose

# 現在のAzureコンテキスト確認
Get-AzContext
```

## 応用例

### 📋 定期監査での活用

```powershell
# 週次レポート生成スクリプト例
$reportDate = Get-Date -Format "yyyyMMdd"
$reportPath = "C:\Reports\Weekly\azure-diag-report-$reportDate.csv"

.\AzAnalyzeDiag.ps1 -Scope Tenant -AutoExportCsv $true -CsvOutputPath $reportPath -NonInteractive $true

# レポートをメール送信（例）
Send-MailMessage -To "audit-team@company.com" -Subject "Azure診断設定週次レポート" -Body "週次の診断設定分析レポートです。" -Attachments $reportPath
```

### 🎯 コンプライアンス チェック

```powershell
# 重要リソースの診断設定チェック
.\AzAnalyzeDiag.ps1 -Scope Subscription -IncludeResourcesWithoutDiagnostics $true -AutoExportCsv $true

# CSVから未設定リソースのみ抽出
$allResults = Import-Csv "diagnostic-settings-*.csv"
$unsetResources = $allResults | Where-Object { $_.HasDiagnosticSettings -eq "False" }
$unsetResources | Export-Csv "compliance-gaps.csv" -NoTypeInformation
```

### 📊 CSV 出力を活用した詳細分析

```powershell
# 1. Storage Account サービス別の診断設定分析
$results = Import-Csv "diagnostic-settings-*.csv"

# Storage Account サービス種別ごとの統計
$storageServiceStats = $results | Where-Object { $_.ResourceType -like "Microsoft.Storage/storageAccounts/*" } |
                      Group-Object ResourceType | ForEach-Object {
    $serviceType = $_.Name.Split('/')[-1]  # blobServices, fileServices, etc.
    $totalCount = $_.Count
    $withDiag = ($_.Group | Where-Object { $_.HasDiagnosticSettings -eq "True" }).Count
    [PSCustomObject]@{
        ServiceType = $serviceType
        TotalResources = $totalCount
        WithDiagnostics = $withDiag
        Coverage = [math]::Round(($withDiag / $totalCount) * 100, 2)
    }
} | Sort-Object Coverage -Descending

# Storage Account インスタンス別の詳細分析
$storageInstanceStats = $results | Where-Object { $_.ResourceType -like "Microsoft.Storage/storageAccounts/*" } |
                       Group-Object { $_.ResourceName.Split('/')[0] } | ForEach-Object {
    $accountName = $_.Name
    $services = $_.Group | Group-Object ResourceType
    [PSCustomObject]@{
        StorageAccount = $accountName
        BlobDiagnostics = ($services | Where-Object Name -like "*blobServices").Count -gt 0
        FileDiagnostics = ($services | Where-Object Name -like "*fileServices").Count -gt 0
        QueueDiagnostics = ($services | Where-Object Name -like "*queueServices").Count -gt 0
        TableDiagnostics = ($services | Where-Object Name -like "*tableServices").Count -gt 0
    }
}

# 2. Log Analytics Workspace別のリソース分布
$workspaceStats = $results | Where-Object { $_.LogAnalyticsWorkspace -ne "未設定" } |
                 Group-Object LogAnalyticsWorkspace, ResourceType |
                 Select-Object Name, Count | Sort-Object Count -Descending

# 3. 診断設定の転送先組み合わせ分析
$destinationAnalysis = $results | Select-Object ResourceName, LogAnalyticsWorkspace, StorageAccount, EventHub |
                      Group-Object LogAnalyticsWorkspace, StorageAccount, EventHub |
                      Select-Object Name, Count

# 4. サブスクリプション横断でのカバレッジ比較（テナント分析時）
$subStats = $results | Group-Object SubscriptionName | ForEach-Object {
    $total = $_.Count
    $withDiag = ($_.Group | Where-Object { $_.HasDiagnosticSettings -eq "True" }).Count
    [PSCustomObject]@{
        Subscription = $_.Name
        Total = $total
        WithDiagnostics = $withDiag
        Coverage = [math]::Round(($withDiag / $total) * 100, 2)
    }
} | Sort-Object Coverage -Descending
```

**💡 CSV 活用のメリット**：

- **完全なデータ**：コンソール出力で省略される情報も含めて分析可能
- **Excel 連携**：ピボットテーブルでの多次元分析
- **自動化対応**：スクリプトによる定期レポート生成
- **カスタム分析**：WorkspaceId や ResourceId を使った詳細調査

## ライセンス

MIT License - このスクリプトは自由に使用・改変できます。

**免責事項**:

- このスクリプトは現状のまま（"AS IS"）提供されます
- すべての Azure リソースタイプでの動作保証はありません
- 使用前にテスト環境での検証を強く推奨します
- 作成者は使用による損害について一切の責任を負いません

## 更新履歴

- **v1.3** (2025 年 01 月 04 日): リソースログ専用版

  - 🎯 **リソースログ限定**: ログカテゴリ「N/A」のリソースタイプを除外（158 種類に厳選）
  - ❌ **除外対象**: メトリクスのみサポートのリソース（Microsoft.Storage/storageAccounts、Microsoft.Sql/servers 等）
  - ✅ **対象明確化**: リソースログ（診断ログ）をサポートするリソースタイプのみに特化
  - 📊 **精度向上**: より正確な診断設定カバレッジ分析を実現
  - 📝 **ドキュメント更新**: README にリソースログ限定版であることを明記

- **v1.2** (2025 年 01 月 04 日): Microsoft Learn 最新適合性確認版

  - 🔄 **リソースタイプ最新化**: Microsoft Learn 公式ドキュメント再確認（161 種類対応）
  - ✨ **新規リソースタイプ追加**: Microsoft.Edge/diagnostics、Microsoft.HealthDataAIServices、Microsoft.singularity、Microsoft.StandbyPool 等
  - 📊 **適合性保証**: 2025 年 01 月 04 日時点の最新 logs-index リファレンス準拠
  - 📝 **ドキュメント更新**: README にリソースタイプ数と新機能追記

- **v1.1** (2025 年 7 月 8 日): 機能拡張版

  - ✨ **タイムアウト付き対話入力機能**: 5 秒タイムアウトで自動進行
  - 🔄 **再ログイン・切り替え機能**: テナント/サブスクリプション変更
  - 📊 **重複診断設定の適切なカウント**: 同一リソースの複数設定対応
  - 🏷️ **ライセンス情報追加**: MIT License 明記
  - 📝 **テナント名取得強化**: 複数方法でのテナント情報取得
  - 🚀 **ユーザビリティ向上**: より直感的な操作体験

- **v1.0** (2025 年 7 月 8 日): 初回リリース
  - 基本的な診断設定分析機能
  - カバレッジ統計表示
  - CSV 出力機能
  - テナント/サブスクリプション横断分析
  - パフォーマンス最適化
  - Microsoft Learn 公式ドキュメント準拠のリソースタイプフィルタリング

## 作成者・ライセンス情報

- **作成者**: yamapan
- **作成日**: 2025 年 7 月 8 日
- **ライセンス**: MIT License
- **準拠**: [Microsoft Learn 公式ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-monitor/reference/logs-index)

## 関連リンク

- [Azure Monitor 診断設定](https://docs.microsoft.com/ja-jp/azure/azure-monitor/platform/diagnostic-settings)
- [Log Analytics Workspace](https://docs.microsoft.com/ja-jp/azure/azure-monitor/platform/design-logs-deployment)
- [Azure PowerShell Documentation](https://docs.microsoft.com/ja-jp/powershell/azure/)
- [Azure CLI Documentation](https://docs.microsoft.com/ja-jp/cli/azure/)

## サポート

問題や改善提案がある場合は、GitHub の Issue または Pull Request でお知らせください。
