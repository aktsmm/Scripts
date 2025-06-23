import pyautogui
from PIL import Image
import time
import os
from datetime import datetime

print("5秒以内にキャプチャ範囲の左上角にマウスを移動してください...")
time.sleep(5)
x1, y1 = pyautogui.position()
print(f"左上: ({x1}, {y1})")

print("次に5秒以内に右下角にマウスを移動してください...")
time.sleep(5)
x2, y2 = pyautogui.position()
print(f"右下: ({x2}, {y2})")

region = (x1, y1, x2 - x1, y2 - y1)
print(f"キャプチャ範囲: {region}")

confirm = input("この範囲でよければEnter。やり直す場合は'N'を入力: ")
if confirm.lower() == 'n':
    print("スクリプトを再実行して範囲を再指定してください。")
    exit()

n_pages = int(input("キャプチャするページ数を入力してください（例: 10）: "))

# 保存形式の選択
print("\n=== 保存形式の選択 ===")
print("1. PDFのみ保存（デフォルト）")
print("2. PNG + PDF両方保存")
save_choice = input("選択してください（1または2、未入力で1）: ").strip()
save_png = save_choice == "2"
create_pdf = True  # 常にPDFは作成

# 待機時間の設定
print("\n=== ページ切り替え待機時間の設定 ===")
print("1. 高速（0.1秒）- デフォルト")
print("2. 標準（0.3秒）")
print("3. 安全（0.5秒）")
print("4. カスタム（手動入力）")
wait_choice = input("選択してください（1-4、未入力で1）: ").strip()

if wait_choice == "2":
    wait_time = 0.3
elif wait_choice == "3":
    wait_time = 0.5
elif wait_choice == "4":
    try:
        wait_time = float(input("待機時間を秒で入力してください（例: 0.2）: "))
    except ValueError:
        wait_time = 0.1
        print("無効な値です。デフォルト（0.1秒）を使用します。")
else:
    wait_time = 0.1

print(f"設定された待機時間: {wait_time}秒")

# プレフィックス名の入力
prefix = input("画像ファイルのプレフィックス名を入力してください（未入力の場合は日付_a_001形式）: ").strip()
if not prefix:
    current_date = datetime.now().strftime("%Y%m%d")
    prefix = f"{current_date}_a"

# プレフィックス名と同じフォルダを作成
if not os.path.exists(prefix):
    os.makedirs(prefix)
    print(f"フォルダ '{prefix}' を作成しました。")

# 総ページ数に応じて桁数を自動計算
digits = len(str(n_pages))
print(f"総ページ数: {n_pages}, 使用桁数: {digits}")

print("5秒以内にウィンドウをクリックしてアクティブにしてください...")
time.sleep(5)

# スクリーンショット保存用のリスト
screenshots = []

for i in range(n_pages):
    screenshot = pyautogui.screenshot(region=region)
    
    # PNGファイルとして保存する場合
    if save_png:
        img_filename = os.path.join(prefix, f"{prefix}_{i+1:0{digits}d}.png")
        screenshot.save(img_filename)
        print(f"Page {i+1} PNG保存完了: {img_filename}")
      # PDF用に画像を保存
    screenshots.append(screenshot)
    
    if not save_png:
        print(f"Page {i+1} キャプチャ完了")
    
    pyautogui.press('right')
    time.sleep(wait_time)

# PDFを作成
if create_pdf and screenshots:
    pdf_filename = os.path.join(prefix, f"{prefix}.pdf")
    # 最初の画像を基準にPDFを作成
    screenshots[0].save(
        pdf_filename, 
        "PDF", 
        save_all=True, 
        append_images=screenshots[1:],
        resolution=100.0
    )
    print(f"PDF作成完了: {pdf_filename}")

if save_png and create_pdf:
    print("全ページのスクリーンショット撮影とPDF作成が完了しました！")
    print(f"PNG画像とPDFは '{prefix}' フォルダに保存されています。")
elif create_pdf:
    print("全ページのスクリーンショット撮影とPDF作成が完了しました！")
    print(f"PDFは '{prefix}' フォルダに保存されています。")
else:
    print("全ページのスクリーンショット撮影が完了しました！")
    print(f"画像は '{prefix}' フォルダに保存されています。")
