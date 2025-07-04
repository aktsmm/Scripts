# Azure ツールセットアップスクリプト

このスクリプトは、Windows PowerShell環境でAzure CLIとAzure PowerShellモジュールを自動的にインストールするためのツールです。

## 機能

- **Azure CLI のインストール**: Microsoft公式のAzure CLIをインストール
- **Azure PowerShell のインストール**: PowerShell Gallery からAzモジュールをインストール
- **既存インストールの確認**: インストール済みツールの検出と更新確認
- **詳細なプログレスバー**: リアルタイムでの進行状況表示（%表示、現在の操作）
- **ダウンロード進行状況**: ファイルサイズとダウンロード速度の可視化
- **プロセス監視**: 長時間実行タスクの進行状況追跡
- **エラーハンドリング**: 詳細なエラー処理とログ出力
- **インストール後の検証**: インストール成功の確認と結果サマリー
- **管理者権限チェック**: 適切な権限でのスクリプト実行を保証
- **PowerShell バージョン互換性**: PowerShell 5.1と7.x両対応

## 前提条件

- Windows 10/11 または Windows Server 2016以降
- PowerShell 5.1 以降 (PowerShell 7.x 推奨)
- 管理者権限でのスクリプト実行
- インターネット接続

### PowerShell バージョンに関する注意事項

- **PowerShell 5.1**: Windows PowerShell - 完全サポート
- **PowerShell 7.x**: PowerShell Core - 推奨（最新機能とパフォーマンス向上）
- **互換性**: スクリプトは両バージョンで動作するよう設計されています
- **システム情報取得**: PowerShell 7では `Get-CimInstance` を使用（`Get-WmiObject` の代替）

> **推奨**: Azure開発にはPowerShell 7.x以降の使用を強く推奨します。より高速で、クロスプラットフォーム対応、Azure関連機能の最新サポートがあります。

## 実行状況の可視化

このスクリプトは詳細な進行状況を表示します：

### プログレスバーの表示例

```text
[0%] Azure ツールセットアップ - 開始
[5%] Azure ツールセットアップ - 管理者権限を確認中
[10%] Azure ツールセットアップ - システム情報を取得中
[20%] Azure CLI インストール - MSI インストーラーを準備中
[40%] Azure CLI ダウンロード - 15.2 MB / 24.8 MB
[60%] Azure CLI インストール - MSI インストーラーを実行中 - msiexec.exe
[90%] Azure CLI インストール - インストール確認中 - 試行 1/5
[100%] Azure CLI インストール - 完了
```

### インストール結果サマリー

```text
==================================================
  インストール結果サマリー
==================================================
✓ Azure CLI: インストール成功 (v2.65.0)
✓ Azure PowerShell: インストール成功 (v12.4.0)
==================================================
```

## 使用方法

### 基本的な使用方法

```powershell
# 管理者権限でPowerShellを開いて実行
.\SetupAzureTools.ps1
```

### パラメータ指定での実行

```powershell
# Azure CLIのみインストール
.\SetupAzureTools.ps1 -InstallAzurePowerShell $false

# Azure PowerShellのみインストール
.\SetupAzureTools.ps1 -InstallAzureCLI $false

# 既存インストールを強制更新
.\SetupAzureTools.ps1 -Force

# カスタムログパスを指定
.\SetupAzureTools.ps1 -LogPath "C:\Logs"
```

## パラメータ

| パラメータ | 型 | デフォルト値 | 説明 |
|------------|----|--------------| -----|
| `InstallAzureCLI` | bool | `$true` | Azure CLIをインストールするかどうか |
| `InstallAzurePowerShell` | bool | `$true` | Azure PowerShellをインストールするかどうか |
| `Force` | bool | `$false` | 既存インストールを強制更新するかどうか |
| `LogPath` | string | カレントディレクトリ | ログファイルの出力先パス |

## インストール方法

### Azure CLI の場合

1. **Chocolatey** が利用可能な場合: `choco install azure-cli` (最新版)
2. **MSIインストーラー** を使用: Microsoft公式サイトから最新版をダウンロードしてサイレントインストール

> **注意**: このスクリプトは常に**最新バージョン**をインストールします。特定のバージョンを指定することはできません。

### Azure PowerShell の場合

1. **PowerShell Gallery** から最新の Az モジュールをインストール
2. 必要に応じて NuGet プロバイダーを自動インストール
3. PowerShell Gallery を信頼済みリポジトリに設定

> **注意**: Azure PowerShell も常に**最新バージョン**をインストールします。既存のインストールがある場合は最新版に更新されます。

## 特定のバージョンをインストールしたい場合

このスクリプトは最新バージョンのインストールを前提としていますが、特定のバージョンが必要な場合は以下の方法で手動インストールできます：

### Azure CLI 特定バージョンのインストール

> **重要**: 特定のバージョンを指定する前に、[Azure CLI公式GitHubリリースページ](https://github.com/Azure/azure-cli/releases)で利用可能なバージョンと変更内容を確認してください。

#### 1. WinGet を使用した特定バージョンのインストール

```powershell
# 特定のバージョンを指定してインストール（例：2.67.0）
winget install --exact --id Microsoft.AzureCLI --version 2.67.0
```

#### 2. PowerShell + MSI インストーラーでの特定バージョンインストール

> **注意**: このコマンドは**最新バージョン**をインストールします。特定バージョン（例：2.45.0）を指定したい場合は、[公式GitHubのリリースページ](https://github.com/Azure/azure-cli/releases)から該当するMSIのダウンロードURLを確認してください。

```powershell
# 特定のバージョンのMSIインストーラーをダウンロード・インストール（例：v2.45.0）
# GitHubリリースページ: https://github.com/Azure/azure-cli/releases/tag/azure-cli-2.45.0
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://azcliprod.blob.core.windows.net/msi/azure-cli-2.45.0.msi" -OutFile ".\AzureCLI.msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Remove-Item ".\AzureCLI.msi"
```

##### 例: v2.45.0のMSIをインストールする場合

```powershell
# GitHubリリースページで確認: https://github.com/Azure/azure-cli/releases/tag/azure-cli-2.45.0
Invoke-WebRequest -Uri "https://azcliprod.blob.core.windows.net/msi/azure-cli-2.45.0.msi" -OutFile ".\AzureCLI.msi"
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Remove-Item ".\AzureCLI.msi"
```

#### 3. ZIP パッケージでの特定バージョンインストール

```powershell
# 特定のバージョンのZIPパッケージをダウンロード（例：2.57.0）
$version = "2.57.0"
$url = "https://azcliprod.blob.core.windows.net/zip/azure-cli-$version-x64.zip"
Invoke-WebRequest -Uri $url -OutFile "azure-cli-$version.zip"
# 手動で展開して環境変数PATHに追加
```

### Azure PowerShell 特定バージョンのインストール

#### 1. 特定バージョンのAzモジュールをインストール

```powershell
# 特定のバージョンを指定してインストール（例：12.0.0）
Install-Module -Name Az -RequiredVersion 12.0.0 -Repository PSGallery -Force

# または特定のサブモジュールのみを特定バージョンでインストール
Install-Module -Name Az.Accounts -RequiredVersion 2.19.0 -Force
Install-Module -Name Az.Resources -RequiredVersion 6.12.0 -Force
```

#### 2. 既存のモジュールを特定バージョンに更新

```powershell
# 特定のバージョンに更新
Update-Module -Name Az -RequiredVersion 12.0.0 -Force
```

#### 3. インストール済みバージョンの確認

```powershell
# インストール済みのすべてのバージョンを確認
Get-Module Az -ListAvailable | Select-Object Name, Version

# 特定のモジュールのバージョン確認
Get-Module Az.Accounts -ListAvailable | Select-Object Name, Version
```

### 特定バージョン管理のベストプラクティス

#### 利用可能なバージョンの確認

```powershell
# Azure CLIの利用可能なバージョン確認
# https://github.com/Azure/azure-cli/releases で最新情報を確認

# Azure PowerShellの利用可能なバージョン確認
Find-Module Az -AllVersions | Select-Object Name, Version | Sort-Object Version -Descending

# PowerShell Galleryで特定のモジュールのバージョン確認
Find-Module Az.Accounts -AllVersions | Select-Object Name, Version
```

#### 複数バージョンの共存

```powershell
# 複数バージョンのAzure PowerShellを並行してインストール
Install-Module -Name Az -RequiredVersion 11.0.0 -Force -AllowClobber
Install-Module -Name Az -RequiredVersion 12.0.0 -Force -AllowClobber

# 特定のバージョンを明示的にインポート
Import-Module Az -RequiredVersion 11.0.0
```

#### 環境別のバージョン管理

```powershell
# 開発環境：最新版
Install-Module -Name Az -Force

# 本番環境：固定バージョン
Install-Module -Name Az -RequiredVersion 11.6.0 -Force

# テスト環境：プレビュー版（必要に応じて）
Install-Module -Name AzPreview -Force
```

> **重要**: 特定のバージョンをインストールする場合は、セキュリティ更新とバグ修正を考慮して定期的にバージョンを見直してください。Azure CLIとAzure PowerShellの[リリースノート](https://github.com/Azure/azure-cli/releases)と[PowerShellリリースノート](https://github.com/Azure/azure-powershell/releases)を確認することを推奨します。

## ログ出力

スクリプト実行時に詳細なログが出力されます：

- **ファイル名**: `AzureToolsSetup_yyyyMMdd_HHmmss.log`
- **出力先**: 指定されたLogPathまたはカレントディレクトリ
- **ログレベル**: INFO, WARNING, ERROR, SUCCESS

## インストール後の確認

### Azure CLI の確認

```powershell
# バージョン確認
az --version

# サインイン
az login

# アカウント確認
az account show
```

### Azure PowerShell の確認

```powershell
# モジュール確認
Get-Module Az -ListAvailable

# サインイン
Connect-AzAccount

# アカウント確認
Get-AzContext
```

## トラブルシューティング

### よくある問題と解決方法

1. **管理者権限エラー**
   - PowerShellを「管理者として実行」で開いてください

2. **実行ポリシーエラー**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **PowerShell バージョン関連のエラー**
   - PowerShell 5.1で `Get-CimInstance` が見つからない場合は正常です
   - PowerShell 7で `Get-WmiObject` が見つからない場合は正常です
   - スクリプトは自動的に適切なコマンドを選択します

4. **ネットワークエラー**
   - プロキシ設定を確認してください
   - ファイアウォール設定を確認してください
   - 企業ネットワークの場合は IT部門にお問い合わせください

5. **PowerShell Gallery アクセスエラー**

   ```powershell
   # TLS 1.2 を有効化
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```

6. **Azure PowerShell インストールが遅い**
   - Azure PowerShell (Az モジュール) は大きなモジュールです
   - 初回インストール時は10-15分程度かかる場合があります
   - プログレスバーが動いている間はお待ちください

7. **MSI インストーラーエラー**
   - 他のインストールプロセスが実行中でないか確認してください
   - Windows Installer サービスが実行されているか確認してください

### ログの確認

エラーが発生した場合は、生成されたログファイルを確認してください：

```powershell
# ログファイルの内容を表示
Get-Content "AzureToolsSetup_*.log" | Select-String "ERROR"
```

## パフォーマンスと実行時間

### 予想実行時間

- **Azure CLI のみ**: 2-5分
- **Azure PowerShell のみ**: 5-15分（初回インストール）
- **両方同時**: 7-20分

### パフォーマンス最適化

- **PowerShell 7.x**: PowerShell 5.1より高速
- **SSD推奨**: ファイル展開が高速化
- **高速インターネット**: ダウンロード時間を短縮
- **バックグラウンドジョブ**: Azure PowerShellインストールの並行処理

## セキュリティ考慮事項

- スクリプトは管理者権限で実行されるため、信頼できるソースからのみ実行してください
- インストール後は適切なAzure認証方法（Managed Identity、Service Principal等）を使用してください
- 機密情報はKey Vaultなどの安全な場所に保存してください

## 更新とメンテナンス

- Azure CLIは定期的に更新されるため、`az upgrade` コマンドで最新版に更新できます
- Azure PowerShellは `Update-Module Az` で更新できます
- このスクリプト自体も定期的に最新版を確認してください

### 推奨更新頻度

- **Azure CLI**: 月1回程度
- **Azure PowerShell**: 月1回程度
- **セキュリティ更新**: 随時適用

### PowerShell環境の確認コマンド

```powershell
# PowerShellバージョン確認
$PSVersionTable

# Azure CLIバージョン確認 (最新版が表示されます)
az --version

# Azure PowerShellバージョン確認 (最新版が表示されます)
Get-Module Az -ListAvailable | Select-Object Name, Version

# インストール済みAzureモジュール一覧
Get-Module Az.* -ListAvailable | Sort-Object Name

# 現在利用可能な最新バージョンの確認 (参考)
# Azure CLI: https://github.com/Azure/azure-cli/releases
# Azure PowerShell: https://github.com/Azure/azure-powershell/releases
```

### 一般的なバージョン管理のベストプラクティス

- **開発環境**: 最新バージョンの使用を推奨（新機能とセキュリティ更新）
- **本番環境**: 特定バージョンの固定が必要な場合は、別途手動インストールを検討
- **CI/CD環境**: このスクリプトは常に最新版をインストールするため、ビルドの一貫性に注意

## サポート

- Azure CLI: [公式ドキュメント](https://docs.microsoft.com/ja-jp/cli/azure/)
- Azure PowerShell: [公式ドキュメント](https://docs.microsoft.com/ja-jp/powershell/azure/)

## ライセンス

このスクリプトはMITライセンスの下で提供されています。
