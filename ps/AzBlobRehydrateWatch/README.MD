# Azure Blob Rehydrate Monitor Script

この PowerShell スクリプトは、Azure Storage アカウント内で **アーカイブ層からホット層へのリハイドレートの進行状況をリアルタイムで監視**します。  
完了までの時間や状態をログとして保存します。

## 🔧 機能概要

- 指定されたストレージアカウント、コンテナ、プレフィックス配下の BLOB を対象にリストアップ
- 各 BLOB の `Created` 時刻を記録し、アーカイブ状態から `Hot` に変わるまでを監視
- 状態更新を一定間隔でチェックし、すべてが `Hot` になった時点で終了
- ログ出力（進捗ログ `progress.log`、要約ログ `summary.log`）

---

## 📝 使用方法

### パラメータ

| パラメータ名        | 型       | 必須 | 説明                                                                 |
|---------------------|----------|------|----------------------------------------------------------------------|
| `StorageAccount`    | string   | ✅   | 対象の Azure Storage アカウント名                                    |
| `Container`         | string   | ✅   | BLOB コンテナ名                                                      |
| `Prefix`            | string   | ✅   | プレフィックス（対象BLOBのパスまたは共通接頭辞）                    |
| `ResourceGroup`     | string   | ✅   | ストレージアカウントのリソースグループ名                            |
| `IntervalSeconds`   | int      | ⛔   | チェック間隔（秒）※デフォルト: 5秒                                 |

---

### 実行例

```powershell
.\Rehydrate-Monitor.ps1 `
    -StorageAccount "yourstorageacct" `
    -Container "yourcontainer" `
    -Prefix "archive-folder/" `
    -ResourceGroup "your-rg-name"
```

---

## 📁 出力ファイル

- `rehydrate_monitor_logs/progress.log`  
  → 監視中の時刻と HOT 状態の BLOB 数を記録

- `rehydrate_monitor_logs/summary.log`  
  → リハイドレート完了時のサマリー（所要時間など）

---

## 🔒 必要な権限

- 実行環境は、対象ストレージアカウントへの **読み取り権限**（`Storage Blob Data Reader`）が必要です。
- `Az.Accounts`, `Az.Storage` モジュールが事前にインポートされている必要があります。

---

## 📌 注意点

- Archive 層の BLOB を HOT に移行するには、事前にリハイドレートを開始しておく必要があります。
- 本スクリプトは、**リハイドレート進行の監視のみを目的としています**。

---

## 🖊️ 作者
やまぱん ([@aktsmm](https://qiita.com/aktsmm))  

---

## 📝 ライセンス

MIT License
