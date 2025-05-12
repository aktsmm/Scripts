# Test Data Generator_Zero

## 概要

Test Data Generator は、テスト用のファイルとディレクトリ構造を柔軟に生成するためのスクリプトです。
特定のファイルサイズ、ファイル数、ディレクトリ階層を持つデータセットを簡単に作成できます。
ゼロ埋めです。

## 使用例

このスクリプトは以下のような用途に最適です：

- ストレージシステムのパフォーマンステスト
- バックアップソリューションの検証
- ファイル転送ツールのベンチマーク
- ファイルシステムの負荷テスト
- 大規模データ環境のシミュレーション

## 機能

- カスタマイズ可能なディレクトリ階層構造（3階層まで）
- 指定した合計ファイル数に基づくファイル生成
- 目標となる合計データサイズの設定
- ディレクトリ間でのファイルの均等な分配
- 詳細な進捗レポートと結果検証

## 設定可能なパラメータ

スクリプト内の以下の変数を調整することで、生成するデータセットをカスタマイズできます：

| パラメータ | 説明 | デフォルト値 |
|------------|------|-------------|
| `TOTAL_FILES` | 生成する合計ファイル数 | 101 |
| `DEPTH_LEVEL1` | 第1階層のディレクトリ数 | 3 |
| `DEPTH_LEVEL2` | 第2階層のディレクトリ数（各第1階層ディレクトリ内） | 3 |
| `DEPTH_LEVEL3` | 第3階層のディレクトリ数（各第2階層ディレクトリ内） | 3 |
| `TOTAL_SIZE_GB` | 生成するデータの合計サイズ（GB） | 180 |
| `ROOT_DIR` | ルートディレクトリ名 | "dataroot" |

## 使い方

後述のソースコードをスクリプト(test_data_generator.sh) にします

1. スクリプトを実行可能にします：
   ```bash
   chmod +x test_data_generator.sh
   ```

2. 必要に応じてスクリプト内のパラメータを編集します。

3. スクリプトを実行します：
   ```bash
   ./test_data_generator.sh
   ```

4. スクリプトの実行中、進捗状況が表示されます。

5. 完了すると、生成されたファイル数と合計サイズの検証結果が表示されます。

## 注意事項

- 大量のデータを生成するため、十分なディスク容量があることを確認してください。
- デフォルト設定では約180GBのデータが生成されます。
- 生成されるファイルはすべてゼロで埋められたダミーファイルです。
- 非常に大きなデータセットを生成する場合は、実行時間が長くなる可能性があります。

## 例：小規模テスト用の設定

小規模なテストを行う場合は、以下のように変数を調整できます：

```bash
TOTAL_FILES=10           # 合計ファイル数
DEPTH_LEVEL1=2           # 第1階層のディレクトリ数
DEPTH_LEVEL2=2           # 第2階層のディレクトリ数
DEPTH_LEVEL3=2           # 第3階層のディレクトリ数
TOTAL_SIZE_GB=1          # 目標の合計サイズ（GB）
```

## 例：大規模テスト用の設定

大規模なテストを行う場合は、以下のように変数を調整できます：

```bash
TOTAL_FILES=1000         # 合計ファイル数
DEPTH_LEVEL1=5           # 第1階層のディレクトリ数
DEPTH_LEVEL2=5           # 第2階層のディレクトリ数
DEPTH_LEVEL3=5           # 第3階層のディレクトリ数
TOTAL_SIZE_GB=500        # 目標の合計サイズ（GB）
```

## トラブルシューティング

- **ディスク容量エラー**: 十分なディスク容量があることを確認してください。
- **パーミッションエラー**: スクリプトとターゲットディレクトリの実行・書き込み権限を確認してください。
- **実行速度が遅い**: ファイルサイズや数を減らして小規模なテストから始めてください。

```shell:TestDataGenerator
#!/bin/bash

# 設定可能な変数
TOTAL_FILES=101           # 合計ファイル数
DEPTH_LEVEL1=3            # 第1階層のディレクトリ数
DEPTH_LEVEL2=3            # 第2階層のディレクトリ数
DEPTH_LEVEL3=3            # 第3階層のディレクトリ数
TOTAL_SIZE_GB=180         # 目標の合計サイズ（GB）
ROOT_DIR="dataroot"       # ルートディレクトリ名

# ファイルサイズを計算（バイト単位）
FILE_SIZE_BYTES=$(( (TOTAL_SIZE_GB * 1024 * 1024 * 1024) / TOTAL_FILES ))

# dd コマンド用のブロックサイズとカウントを計算
BLOCK_SIZE=1M  # 1MB単位で書き込む
COUNT=$(( FILE_SIZE_BYTES / 1024 / 1024 ))  # MB単位のサイズ計算

# ディレクトリ構造を作成
mkdir -p $ROOT_DIR

echo "ディレクトリ構造の作成を開始します..."
echo "- 第1階層: $DEPTH_LEVEL1 ディレクトリ"
echo "- 第2階層: $DEPTH_LEVEL2 ディレクトリ/親ディレクトリ"
echo "- 第3階層: $DEPTH_LEVEL3 ディレクトリ/親ディレクトリ"
echo "合計ファイル数: $TOTAL_FILES"
echo "1ファイルあたりのサイズ: $(numfmt --to=iec-i --suffix=B --format="%.2f" $FILE_SIZE_BYTES)"
echo "合計サイズ: ${TOTAL_SIZE_GB}GB"

for i in $(seq 1 $DEPTH_LEVEL1); do
  for j in $(seq 1 $DEPTH_LEVEL2); do
    for k in $(seq 1 $DEPTH_LEVEL3); do
      mkdir -p "$ROOT_DIR/level1_${i}/level2_${j}/level3_${k}"
    done
  done
done

# 全ディレクトリを取得
dirs=($(find $ROOT_DIR -type d -mindepth 3 -maxdepth 3 | sort))
num_dirs=${#dirs[@]}
echo "作成されたディレクトリ数: $num_dirs"

# ファイルをディレクトリに分配
files_per_dir=$((TOTAL_FILES / num_dirs))
remaining_files=$((TOTAL_FILES % num_dirs))

echo "各ディレクトリに $files_per_dir ファイルを作成し、最初の $remaining_files ディレクトリには1ファイル追加"

file_count=1
for ((dir_index=0; dir_index<num_dirs; dir_index++)); do
  dir="${dirs[$dir_index]}"
  
  # このディレクトリに作成するファイル数を計算
  files_to_create=$files_per_dir
  if [ $dir_index -lt $remaining_files ]; then
    files_to_create=$((files_to_create + 1))
  fi
  
  echo "ディレクトリ $dir に $files_to_create ファイルを作成します"
  
  # ファイルを作成
  for ((i=0; i<files_to_create; i++)); do
    file_name="file_$(printf "%03d" $file_count)"
    echo "ファイル作成中: $dir/$file_name ($(numfmt --to=iec-i --suffix=B --format="%.2f" $FILE_SIZE_BYTES))"
    dd if=/dev/zero of="$dir/$file_name" bs=$BLOCK_SIZE count=$COUNT status=progress
    file_count=$((file_count + 1))
    
    # 指定したファイル数に達したら終了
    if [ $file_count -gt $TOTAL_FILES ]; then
      echo "指定したファイル数 $TOTAL_FILES に達したため、処理を終了します"
      break 2
    fi
  done
done

echo "ディレクトリ構造とファイル作成が完了しました。"

# 検証用
actual_files=$(find $ROOT_DIR -type f | wc -l)
actual_size=$(du -sh $ROOT_DIR | awk '{print $1}')
echo "検証結果:"
echo "- 実際のファイル数: $actual_files / 目標: $TOTAL_FILES"
echo "- 実際の合計サイズ: $actual_size / 目標: ${TOTAL_SIZE_GB}GB"
```