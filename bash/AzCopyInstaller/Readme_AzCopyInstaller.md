# AzCopy Installer for Linux

## 📌 概要
このスクリプトは **RHEL (Red Hat Enterprise Linux) に AzCopy v10 をインストールする** ためのものです。  
**最新バージョンの AzCopy をダウンロードし、適切なディレクトリに配置し、環境変数を更新する** までを自動化します。

---

## 📂 ファイル構成
- `install_azcopy.sh`  
  → AzCopy をダウンロードし、インストールするスクリプト

---

## 🔧 

```bash:install_azcopy.sh
#!/bin/bash
# AzCopy を RHEL にインストールするスクリプト
# エラー発生時に終了するように設定
set -e
echo "AzCopy インストールスクリプトを開始します..."
# 一時ディレクトリを作成
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
echo "最新バージョンの AzCopy をダウンロードしています..."
# 最新の AzCopy をダウンロード
curl -L https://aka.ms/downloadazcopy-v10-linux -o azcopy.tar.gz
echo "ダウンロードしたアーカイブを展開しています..."
# アーカイブを展開
tar -xzvf azcopy.tar.gz
# 展開されたディレクトリに移動 (バージョン番号が含まれるため、ワイルドカードを使用)
cd azcopy_linux*
# 実行可能バイナリを /usr/local/bin に移動
echo "AzCopy を /usr/local/bin にインストールしています..."
sudo cp azcopy /usr/local/bin/
# 実行権限を確認
sudo chmod +x /usr/local/bin/azcopy

# PATH設定を確認・追加
echo "PATH設定を確認しています..."
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo "PATHに/usr/local/binを追加します..."
    # システム全体に設定するため、profile.dにファイル作成
    echo 'export PATH=$PATH:/usr/local/bin' | sudo tee /etc/profile.d/azcopy_path.sh
    # 現在のセッションにも適用
    export PATH=$PATH:/usr/local/bin
    sudo chmod +x /etc/profile.d/azcopy_path.sh
    echo "PATHを更新しました"
else
    echo "/usr/local/binは既にPATHに含まれています"
fi

# シンボリックリンクも作成（念のため）
if [ ! -f /usr/bin/azcopy ]; then
    echo "シンボリックリンクを作成します..."
    sudo ln -sf /usr/local/bin/azcopy /usr/bin/azcopy
fi

# 一時ディレクトリをクリーンアップ
echo "一時ファイルをクリーンアップしています..."
cd
rm -rf "$TEMP_DIR"

# インストールの確認
echo "AzCopy のインストールを確認しています..."
echo "PATHの設定: $PATH"

# コマンドのフルパスでも確認
if [ -f /usr/local/bin/azcopy ]; then
    echo "AzCopy のバイナリは存在します"
    echo "フルパスでのバージョン確認:"
    /usr/local/bin/azcopy --version || echo "フルパス実行エラー: $?"
    
    echo "コマンドでのバージョン確認:"
    azcopy --version || echo "コマンド実行エラー: $?"
    
    echo "AzCopy のインストールが完了しました。"
else
    echo "エラー: AzCopy のインストールに失敗しました。"
    exit 1
fi


source /etc/profile.d/azcopy_path.sh

echo "インストールプロセスが正常に完了しました。"
```