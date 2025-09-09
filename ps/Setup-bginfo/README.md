# BGInfo 完全自動セットアップスクリプト

このスクリプトは、Microsoft Sysinternals の BGInfo を自動的にダウンロード・設定し、Windowsの壁紙にシステム情報を表示するためのツールです。

## BGInfoとは

BGInfo（Background Information）は、Microsoft Sysinternals が提供する無料のユーティリティです。デスクトップの壁紙にコンピューターの基本情報（CPU、メモリ、IPアドレス、OS情報など）をリアルタイムで表示できます。

### 表示される情報
- ブート時刻（Boot Time）
- CPU情報
- 総メモリ容量
- 使用可能メモリ
- ユーザー名
- マシン名
- OSバージョン

## 機能

- **自動ダウンロード**: BGInfoが未インストールの場合、Sysinternalsから自動取得
- **最適化設定**: 右上表示・適切なサイズの設定ファイルを自動作成
- **自動起動設定**: ログオン時に自動実行されるようレジストリに登録
- **エラー対応**: 設定ファイルでエラーが発生した場合のフォールバック機能
- **詳細なログ**: セットアップ過程での詳細な進行状況とエラー情報の表示
- **トラブルシューティング**: 問題発生時の診断コマンドを提供

## 前提条件

### システム要件
- **OS**: Windows 10/11 または Windows Server 2016以降
- **PowerShell**: PowerShell 5.1 以降
- **権限**: 管理者権限での実行が必要
- **ネットワーク**: インターネット接続（初回ダウンロード時）

### 実行前の準備
1. PowerShellを**管理者として実行**で起動してください
2. 実行ポリシーの確認：
   ```powershell
   Get-ExecutionPolicy
   ```
   制限されている場合は、以下のコマンドで一時的に変更：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
   ```

## 使用方法

### 基本的な実行
```powershell
# スクリプトの場所に移動
cd "C:\path\to\Setup-bginfo"

# スクリプトを実行
.\Setup-bginfo.ps1
```

### ワンライナーでの実行
```powershell
PowerShell -ExecutionPolicy Bypass -File ".\Setup-bginfo.ps1"
```

### リモートからの実行（GitHubから直接）
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aktsmm/Scripts/main/ps/Setup-bginfo/Setup-bginfo.ps1" -UseBasicParsing).Content
```

## セットアップ後の確認

スクリプト実行後、以下を確認してください：

1. **壁紙の確認**: デスクトップの右上にシステム情報が表示されているか
2. **プロセス確認**: 
   ```powershell
   Get-Process -Name "Bginfo*" -ErrorAction SilentlyContinue
   ```
3. **自動起動確認**:
   ```powershell
   Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "BgInfo"
   ```

## カスタマイズ

### 表示位置の変更
表示位置を変更したい場合は、以下のワンライナーを使用：

**右上表示（デフォルト）**:
```powershell
$dir='C:\ProgramData\BGInfo'; '[BGInfo]'+"`nPosition=2`nTextWidth2=280`nTextHeight2=200" | Out-File "$dir\Default.bgi" -Encoding ASCII -Force; & "$dir\Bginfo.exe" "$dir\Default.bgi" /accepteula /silent /timer:0
```

**その他の位置**:
- 左上: `Position=0`
- 右下: `Position=1` 
- 左下: `Position=3`

### 手動設定の変更
GUI設定画面を開く場合：
```powershell
& "C:\ProgramData\BGInfo\Bginfo.exe" "C:\ProgramData\BGInfo\Default.bgi"
```

## トラブルシューティング

### 情報が表示されない場合

1. **手動実行テスト**:
   ```powershell
   $p = Start-Process 'C:\ProgramData\BGInfo\Bginfo.exe' -ArgumentList '/accepteula /silent /timer:0' -PassThru -Wait; Write-Host 'ExitCode:' $p.ExitCode
   ```

2. **プロセス確認**:
   ```powershell
   Get-Process -Name 'Bginfo*' -ErrorAction SilentlyContinue
   ```

3. **権限の問題**: 管理者権限でPowerShellを再起動

4. **ウイルス対策ソフト**: BGInfo.exeがブロックされていないか確認

### 壁紙が元に戻らない場合

1. デスクトップを右クリック → 個人用設定
2. 背景 → お好みの画像を選択

## アンインストール

BGInfoを完全に削除する場合：

```powershell
# 完全削除ワンライナー
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'BgInfo' -Force -ErrorAction SilentlyContinue; Get-Process -Name 'Bginfo*' -ErrorAction SilentlyContinue | Stop-Process -Force; Remove-Item -Path 'C:\ProgramData\BGInfo' -Recurse -Force -ErrorAction SilentlyContinue; Write-Host '壁紙を手動で元に戻してください'
```

手動アンインストール手順：
1. 自動起動の削除
2. BGInfoプロセスの停止
3. ファイルの削除
4. 壁紙の手動復元

## ファイル構成

```
C:\ProgramData\BGInfo\
├── Bginfo.exe          # BGInfo実行ファイル
├── Bginfo64.exe        # 64bit版実行ファイル（ダウンロード時）
├── Default.bgi         # 設定ファイル（右上表示用）
└── Eula.txt           # 使用許諾書
```

## セキュリティについて

- **ダウンロード元**: Microsoft公式のSysinternalsサイトから直接取得
- **署名検証**: Microsoft署名済みの実行ファイルを使用
- **権限**: 管理者権限が必要（システム全体への設定のため）
- **ネットワーク**: HTTPSによる安全な通信

## ライセンス

このスクリプトは **MIT License** の下で提供されています。

### MIT License

```
Copyright (c) 2024 aktsmm

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
```

**注意**: BGInfo自体はMicrosoft Sysinternalsの製品であり、[Microsoft Software License Terms](https://docs.microsoft.com/en-us/sysinternals/license-terms)に従います。

## サポート・コントリビューション

- **Issues**: 問題や改善提案は[GitHubのIssues](https://github.com/aktsmm/Scripts/issues)へ
- **Pull Requests**: 改善案やバグ修正のプルリクエストを歓迎します
- **質問**: 使用方法に関する質問もIssuesでお気軽にどうぞ

## 更新履歴

- **初版**: BGInfo自動セットアップ機能
- **エラー対応**: フォールバック機能とトラブルシューティング追加
- **最適化**: 右上表示とサイズ調整機能

---

**初心者の方へ**: このスクリプトは、複雑な手動設定なしにBGInfoを簡単にセットアップできるよう設計されています。何か問題が発生した場合は、まずトラブルシューティングセクションをご確認ください。