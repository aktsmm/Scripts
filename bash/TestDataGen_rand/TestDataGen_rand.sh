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
    dd if=/dev/urandom of="$dir/$file_name" bs=$BLOCK_SIZE count=$COUNT status=progress
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
