
# 🔧 Test Data Generator (PowerShell)

本スクリプトは、**指定サイズ（GB）とファイル数に応じてランダムなバイナリファイルを階層構造で生成するツール**です。  
検証用大容量データ、Blob Storageテスト、I/Oスループット測定などに活用できます。

---

## 📦 特徴

- PowerShell スクリプトのみで動作
- ディレクトリ3階層までの構造を自動生成
- 小数点を含む合計サイズ（GB）の指定が可能
- `RandomNumberGenerator` を使用したセキュアなランダムバイト生成
- 進捗バー表示と完了後の検証付き
- 100MBチャンクで分割書き込み（大容量対応）

---

## 🚀 使用方法

```powershell
.\TestDataGen_rand.ps1 `
  -TotalFiles 100 `
  -DepthLevel1 3 `
  -DepthLevel2 3 `
  -DepthLevel3 3 `
  -TotalSizeGB 180 `
  -RootDir "TestData_180GB"
```

> 🔸 `.\TestDataGen_rand.ps1` を実行する前に `Unblock-File` を推奨：
> ```powershell
> Unblock-File .\TestDataGen_rand.ps1
> ```

---

## 📥 パラメータ

| パラメータ        | 必須 | 説明                                                                 |
|------------------|------|----------------------------------------------------------------------|
| `TotalFiles`     | ✅   | 作成するファイルの総数                                               |
| `DepthLevel1`    | ❌   | 1階層目のディレクトリ数（デフォルト：3）                              |
| `DepthLevel2`    | ❌   | 2階層目のディレクトリ数（デフォルト：3）                              |
| `DepthLevel3`    | ❌   | 3階層目のディレクトリ数（デフォルト：3）                              |
| `TotalSizeGB`    | ✅   | 全ファイル合計サイズ（GB、小数も可。例：`0.1`、`180`）                |
| `RootDir`        | ✅   | ファイルを出力するルートディレクトリ名                                |

---

## 🧠 スクリプトの処理概要

1. 入力パラメータを確認・設定（未指定時は対話で入力）
2. 指定された階層のディレクトリを自動作成
3. 各ディレクトリに均等にファイルを分配
4. 1ファイルあたりのサイズを計算し、100MB単位でチャンク生成・書き込み
5. 実行後、作成ファイル数とサイズを検証して表示

---

## 📌 注意事項

- `TotalSizeGB / TotalFiles` の値が大きすぎるとメモリ不足になります（実用上 1TB 以内推奨）
- ファイルはバイナリ形式（ランダム）です。テキストではありません
- 実行前に出力先に十分な空き容量があることを確認してください
- スクリプト内の `chunkSize` は固定（100MB）ですが変更可能です

---

## 🛠 技術的ポイント

| 項目              | PowerShell実装                                   |
|-------------------|--------------------------------------------------|
| ランダムデータ    | `RandomNumberGenerator.Fill()`                  |
| ディレクトリ作成  | `New-Item -ItemType Directory`                  |
| ファイル分配処理  | ディレクトリ数を割ってファイルを均等配分        |
| 進捗表示          | `Write-Progress` によるリアルタイム更新表示     |
| 大容量書き込み    | 100MBのチャンク単位で書き込み、メモリ節約       |

---

## 📚 例：10MBのファイルを10個生成（単層）

```powershell
.\TestDataGen_rand.ps1 `
  -TotalFiles 10 `
  -DepthLevel1 1 `
  -DepthLevel2 1 `
  -DepthLevel3 1 `
  -TotalSizeGB 0.1 `
  -RootDir "TestData_10MB"
```

---

## 🙋 FAQ

### Q. 1ファイルが大きすぎてエラーになります
A. `TotalSizeGB / TotalFiles` のサイズが `[int]` を超えるとバッファ割り当てで失敗します。サイズを小さくするかファイル数を増やしてください。

### Q. ディレクトリ階層を変更したい
A. `-DepthLevel1` ～ `-DepthLevel3` の値を変更すれば階層構造が変わります。

---

## 🔒 ライセンス

MIT License
