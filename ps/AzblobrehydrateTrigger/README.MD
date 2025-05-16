# Azure Blob Rehydrate & Monitor Script (with Copy and Priority)

この PowerShell スクリプトは、Azure BLOB Storage 上の **Archive層BLOBをHot層にコピーしつつ、リハイドレート状態を監視**するツールです。優先度の切り替えも可能。

## 🧠 主な機能

- 指定した複数の Prefix に含まれる Archive BLOB を検出
- Hot層にコピー（`rehydrate/` 配下に作成）
- `Standard` または `High` の Rehydrate 優先度指定に対応（`-Urgent` スイッチ）
- 状態が完全に Hot になるまで監視
- プレフィックスごとにログファイルを作成（タイムスタンプ付き）

---

## 📝 パラメータ

| パラメータ名       | 型        | 必須 | 説明                                                                 |
|--------------------|-----------|------|----------------------------------------------------------------------|
| `StorageAccount`   | string    | ✅   | 対象のストレージアカウント名                                        |
| `Container`        | string    | ✅   | 対象のBLOBコンテナ名                                                 |
| `Prefixes`         | string[]  | ✅   | 対象のプレフィックス配列（複数可）                                   |
| `ResourceGroup`    | string    | ✅   | ストレージアカウントが属するリソースグループ名                      |
| `TimeoutMinutes`   | int       | ⛔   | リハイドレート監視のタイムアウト（分）※デフォルト: 240分           |
| `Urgent`           | switch    | ⛔   | `High` 優先度でリハイドレートを実行（指定しない場合は Standard）   |

---

## ▶️ 実行例

```powershell
.\Rehydrate-CopyAndMonitor.ps1 `
    -StorageAccount "mystorageacct" `
    -Container "mycontainer" `
    -Prefixes "archive1/", "archive2/" `
    -ResourceGroup "my-resource-group" `
    -Urgent `
    -TimeoutMinutes 180
```

---

## 📁 出力ログ

各プレフィックスごとに、以下のようなログファイルが `rehydration_logs/` ディレクトリに生成されます：

- `archive1.log` などのファイル名で保存
- コピー開始・成功・エラー、リハイドレート完了などを時系列に記録

---

## 📌 注意点

- コピー先のパスは `rehydrate/{元のBLOB名}` になります
- Archive層 → Hot層へのコピーには時間がかかることがあります（最大15時間程度）
- 監視は60秒ごとに実行され、リハイドレート完了までループ処理されます
- スクリプトは BLOB レベルでの `ArchiveStatus` を確認し、完了まで待機します

---

## 🔐 必要な権限

- スクリプトを実行するには、対象ストレージアカウントに対する **読み取り + 書き込み権限** が必要です（例：`Storage Blob Data Contributor`）
- `Az.Accounts`, `Az.Storage` モジュールが必要です

---

## ✍ 作者

やまぱん ([@aktsmm](https://qiita.com/aktsmm))  

---

## 🪪 ライセンス

MIT License
