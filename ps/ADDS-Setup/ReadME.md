# Active Directory ドメインコントローラー自動セットアップスクリプト

このスクリプトは、新しいActive Directoryドメインサービス（AD DS）のフォレストを自動的に構成し、対象のWindows Serverをドメインコントローラーに昇格させます。

## 機能概要
- Active Directory ドメインサービス (AD DS) の役割をインストールします。
- 新規のADフォレストを作成し、DNSサーバーを自動的にセットアップします。
- 設定完了後にサーバーを自動で再起動し、変更を適用します。
- ドメイン名およびパスワードのデフォルト値が設定されており、引数が未指定の場合でも動作します。

## デフォルトのパラメータ
| パラメータ | デフォルト値 |
|------------|------------------|
| DomainName | kinoko.yama      |
| SafeModeAdminPassword | P@ssw0rd!        |

## 事前準備
- 管理者権限でのPowerShellの実行環境
- Windows Server (推奨はWindows Server 2019以降)

## 使用方法

### デフォルトの値で実行する場合
```powershell
powershell -ExecutionPolicy Bypass -File .\Setup-ADDSForest.ps1
```

### 引数を明示的に指定する場合
```powershell
powershell -ExecutionPolicy Bypass -File .\Setup-ADDSForest.ps1 `
  -DomainName example.local -SafeModeAdminPassword YourSecurePassword123
```

## 処理の流れ
1. AD DS役割をインストールします。
2. 新規フォレストとして、指定されたドメイン名でドメインコントローラーを構成します。
3. 構成完了後、再起動を行い昇格プロセスを完了させます。

## ログ出力について
スクリプト実行中は進捗および状態がコンソールに出力されます。

## 注意事項
- スクリプト実行後、強制的に再起動されます。実行前に重要なデータを保存しておいてください。
- 本番環境での利用時は、パスワードの設定に注意してください。

## ライセンス
自由に利用、変更、配布が可能です。
