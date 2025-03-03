# 自動ディスクマウントスクリプト

## 概要

このスクリプトは、Linux システム上で未使用のディスクを自動検出し、パーティション作成、フォーマット、およびマウントを行います。さらに、/etc/fstab にエントリを追加することでマウントの永続化を行います。

## 動作概要

+ 未使用のディスクを検出
+ GPT パーティションテーブルを作成
+ ext4 ファイルシステムをフォーマット
+ 指定されたマウントポイントにマウント
+ fstab に登録して再起動後もマウントを維持

## 使用方法

1. スクリプトのダウンロード
後述のソースを適当なスクリプト(auto_mount.sh)にします。

2. 実行権限の付与

ダウンロードしたスクリプトに実行権限を付与します。

chmod +x auto_mount.sh

3. スクリプトの実行

スクリプトを実行するには、以下のコマンドを使用してください。

sudo ./auto_mount.sh

## 注意点

スクリプトは ルートユーザー (sudo su) で実行する必要があります。

未使用のディスクが見つからない場合、スクリプトはエラーメッセージを表示して終了します。

ext4 フォーマットでフォーマットされるため、別のファイルシステムを使用したい場合はスクリプトを適宜変更してください。

fstab への変更を行うため、間違った設定をするとシステムが起動しなくなる可能性があります。

## 免責事項

本スクリプトの使用によって生じたデータ損失やシステムの問題について、作者は一切の責任を負いません。自己責任でご使用ください。

## Script

```shell
#!/bin/bash

# ルートユーザーで実行
sudo su

# 変数設定
MOUNT_POINT="/mnt/datastore"
DEVICE=""

# 未使用のディスクを探す
echo "未使用のディスクを検索中..."
for disk in $(lsblk -nd --output NAME); do
    if ! grep -q "/dev/$disk" /etc/fstab && ! mount | grep -q "/dev/$disk"; then
        DEVICE="/dev/$disk"
        echo "使用可能なディスクを検出: $DEVICE"
        break
    fi
done

# ディスクが見つからない場合は終了
if [ -z "$DEVICE" ]; then
    echo "未使用のディスクが見つかりません。"
    exit 1
fi

# パーティション作成
echo "パーティションを作成: $DEVICE"
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart primary ext4 0% 100%

# パーティションを特定
PARTITION="${DEVICE}1"
echo "作成されたパーティション: $PARTITION"

# ファイルシステムを作成
echo "ファイルシステムを作成: $PARTITION"
mkfs.ext4 "$PARTITION"

# マウントポイントの作成
echo "マウントポイントを作成: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

# マウント設定
echo "マウント設定を適用"
mount "$PARTITION" "$MOUNT_POINT"

# fstabに追加して永続化
UUID=$(blkid -s UUID -o value "$PARTITION")
echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab

echo "ディスクの初期化とマウントが完了しました。"
```