# 🐳 Docker Desktop 完全削除ツール

本スクリプトは、**Docker Desktop を完全にアンインストールし、関連する全てのファイルとWSL仮想マシンを削除するツール**です。  
Docker Desktop の再インストールやクリーンアップが必要な場合に使用します。

---

## 📦 特徴

- Docker Desktop 関連の全ディレクトリを自動削除
- WSL 2 バックエンドの仮想マシン（docker-desktop、docker-desktop-data）を削除
- PowerShell のみで動作（管理者権限不要）
- 削除対象が存在しない場合は安全にスキップ
- 実行状況をカラー表示で確認可能

---

## 🚀 使用方法

```powershell
.\DeleteDockerDektop.ps1
```

> 🔸 スクリプト実行前に `Unblock-File` を推奨：
>
> ```powershell
> Unblock-File .\DeleteDockerDektop.ps1
> ```

---

## 🗂️ 削除対象

### Windows ディレクトリ

| パス | 説明 |
|------|------|
| `%APPDATA%\Docker` | Docker 設定ファイル |
| `%LOCALAPPDATA%\Docker` | Docker ローカルデータ |
| `%USERPROFILE%\.docker` | Docker CLI 設定 |
| `%USERPROFILE%\AppData\Roaming\Docker Desktop` | Docker Desktop 設定 |
| `%USERPROFILE%\AppData\Local\Docker Desktop` | Docker Desktop ローカルデータ |
| `%PROGRAMDATA%\Docker` | Docker システムデータ |
| `%TEMP%\DockerDesktop` | Docker Desktop 一時ファイル |

### WSL 2 仮想マシン

- `docker-desktop`
- `docker-desktop-data`

---

## 🧠 スクリプトの処理概要

1. WSL 2 上の Docker 仮想マシンを停止・削除
2. Windows 上の Docker 関連ディレクトリを順次削除
3. 各処理の実行状況を色分けして表示
4. 削除完了メッセージを表示

---

## 📌 注意事項

- **Docker Desktop を事前に終了してください**（タスクトレイからも終了）
- 実行前に重要なDockerコンテナやボリュームのバックアップを取ってください
- WSL 2 で動作している他の Linux ディストリビューションには影響しません
- 管理者権限は不要ですが、Docker Desktop が動作中の場合は正常に削除されない可能性があります

---

## 🛠 技術的ポイント

| 項目 | PowerShell実装 |
|------|----------------|
| WSL管理 | `wsl --unregister` コマンドで仮想マシン削除 |
| ディレクトリ削除 | `Remove-Item -Recurse -Force` で再帰削除 |
| エラーハンドリング | `-ErrorAction SilentlyContinue` で継続実行 |
| 存在確認 | `Test-Path` でディレクトリ存在チェック |
| カラー出力 | `Write-Host -ForegroundColor` で視覚的な進捗表示 |

---

## 📚 実行例

```powershell
PS C:\Scripts> .\DeleteDockerDektop.ps1

🗑️ Stopping and unregistering WSL Docker distributions...
🧹 Deleting: C:\Users\User\AppData\Roaming\Docker
🧹 Deleting: C:\Users\User\AppData\Local\Docker
✔️ Not found (already deleted): C:\Users\User\.docker
🧹 Deleting: C:\Users\User\AppData\Roaming\Docker Desktop
✔️ Not found (already deleted): C:\Users\User\AppData\Local\Docker Desktop
🧹 Deleting: C:\ProgramData\Docker
✔️ Not found (already deleted): C:\Temp\DockerDesktop

✅ Docker cleanup completed. You can now reinstall Docker Desktop.
```

---

## 🙋 FAQ

### Q. Docker Desktop だけでなく Docker CLI も削除されますか？

A. はい、`.docker` ディレクトリも削除対象に含まれているため、Docker CLI の設定も削除されます。

### Q. WSL 2 の他の Linux ディストリビューションに影響しますか？

A. いいえ、`docker-desktop` と `docker-desktop-data` のみが削除対象です。

### Q. 実行後に Docker を再インストールできますか？

A. はい、完全にクリーンアップされるため、Docker Desktop の新規インストールが可能です。

---

##  再インストール手順

### ステップ1：Docker Desktop のダウンロード・インストール

1. [Docker 公式サイト](https://www.docker.com/products/docker-desktop/) から最新版をダウンロード
2. インストーラーを実行（管理者権限で実行推奨）

```powershell
# 管理者権限でDocker Desktopを起動
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -Verb RunAs
```

### ステップ2：インストール確認

```powershell
# WSL 2 ディストリビューション確認
wsl -l -v
```

**正常にインストールされた場合の出力例：**

```text
  NAME              STATE           VERSION
* Ubuntu-20.04      Running         2
  docker-desktop    Running         2
  docker-desktop-data Stopped       2
```

### ステップ3：Docker 動作確認

```powershell
# Docker バージョン確認
docker --version

# Docker の動作テスト
docker run hello-world
```

### 📌 インストール時の注意点

- **既存インストールの警告**：インストーラーが「既に最新バージョンがインストールされている」と表示する場合は、本スクリプトで完全削除されていない可能性があります
- **WSL 2 の更新**：インストール前に `wsl --update` を実行してWSL 2を最新版に更新することを推奨
- **再起動が必要**：初回インストール時はシステム再起動が必要な場合があります

### 🔧 トラブルシューティング

#### インストーラーが「既にインストール済み」と表示される場合

1. Windows の「アプリと機能」から Docker Desktop を手動アンインストール
2. **重要**：アンインストール時に「Docker Desktop settings を削除する」にチェックを入れる
3. 本スクリプトを再実行
4. システム再起動後、Docker Desktop を再インストール

---

##�🔒 ライセンス

MIT License
