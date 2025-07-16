# ファイル負荷テストスクリプト

## 概要

この PowerShell スクリプトは、指定したドライブに対してファイル I/O 負荷テストを実行するツールです。ストレージデバイスの性能測定やシステムの負荷テストに使用できます。

## 機能

- **連続的な負荷テスト**: 無限ループでファイルの書き込み・読み取りを実行
- **自動フォルダ管理**: テストフォルダが既存の場合、自動的に連番フォルダを作成
- **リアルタイム性能表示**: 書き込み・読み取り速度を MB/s 単位で表示
- **安全な中断**: Ctrl+C でテストを安全に停止可能

## 設定パラメータ

| パラメータ     | デフォルト値  | 説明                           |
| -------------- | ------------- | ------------------------------ |
| `$DriveLetter` | "V"           | テスト対象ドライブ文字         |
| `$BaseFolder`  | "V:\LoadTest" | ベースフォルダパス             |
| `$FileSizeMB`  | 5             | 1 ファイルあたりのサイズ（MB） |
| `$FileCount`   | 50            | 同時に扱うファイル数           |

## 使用方法

### 基本的な実行

```powershell
# スクリプトを実行
.\test_files_load.ps1
```

### カスタム設定での実行

スクリプト内のパラメータを編集してから実行：

```powershell
# 例：10MBファイルを100個作成する場合
$FileSizeMB = 10
$FileCount = 100
```

### 実行例

```console
Created test folder: V:\LoadTest
=== Starting infinite load test on V:\LoadTest ===
Press Ctrl + C to stop.
[WRITE] File 1/50 => V:\LoadTest\TestFile_1.dat
[WRITE] File 2/50 => V:\LoadTest\TestFile_2.dat
...
[READ ] Reading TestFile_1.dat
[read ] Reading TestFile_2.dat
...
[14:30:25] Loop Finished - Write: 125.5 MB/s, Read: 180.2 MB/s
---------------------------------------------------------------
```

## 出力情報

### リアルタイム表示

- **WRITE**: ファイル書き込み進捗（青色）
- **READ**: ファイル読み取り進捗（緑色）
- **サマリー**: 各ループの性能結果（黄色）

### 性能メトリクス

- **Write Speed**: 書き込み速度（MB/s）
- **Read Speed**: 読み取り速度（MB/s）
- **Loop Time**: 各ループの実行時間

## 注意事項

### システム要件

- Windows PowerShell 5.1 以降
- 十分な空き容量があるストレージ
- 管理者権限（推奨）

### 安全性

- **データ消失リスク**: テストフォルダ内の既存ファイルが上書きされる可能性
- **ディスク使用量**: `$FileSizeMB × $FileCount`分の容量が必要
- **システム負荷**: 高負荷テストによりシステムが重くなる可能性

### 推奨事項

1. **テスト前の確認**

   ```powershell
   # 利用可能容量の確認
   Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "V:"}
   ```

2. **段階的テスト**

   - 小さなファイルサイズから開始
   - システムの反応を確認しながら負荷を増加

3. **監視**
   - タスクマネージャーで CPU・メモリ使用率を監視
   - ディスクの温度監視（物理デバイスの場合）

## トラブルシューティング

### よくある問題

#### アクセス拒否エラー

```powershell
# 管理者権限で実行
Start-Process PowerShell -Verb RunAs
```

#### ディスク容量不足

```powershell
# ファイルサイズまたは数を削減
$FileSizeMB = 1
$FileCount = 10
```

#### 高負荷による応答停止

- Ctrl+C でスクリプトを停止
- タスクマネージャーから PowerShell プロセスを終了

## カスタマイズ例

### より軽い負荷テスト

```powershell
$FileSizeMB = 1      # 1MBファイル
$FileCount = 10      # 10ファイル
```

### より重い負荷テスト

```powershell
$FileSizeMB = 50     # 50MBファイル
$FileCount = 100     # 100ファイル
```

### 異なるドライブでのテスト

```powershell
$DriveLetter = "D"   # Dドライブでテスト
```

## ライセンス

このスクリプトは自由に使用・改変できます。使用によって生じた損害について作者は責任を負いません。

## 更新履歴

- 初版: ファイル I/O 負荷テスト機能の実装
- 自動フォルダ管理機能の追加
- 性能メトリクス表示機能の追加
