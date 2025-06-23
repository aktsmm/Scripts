import pyautogui
import pytesseract
from PIL import Image
import time

# Tesseractのパス
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

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

n_pages = int(input("OCRするページ数を入力してください（例: 10）: "))
output_file = input("出力ファイル名を入力してください（例: output.txt）: ") or "output.txt"

# 最初にウィンドウをクリックしてアクティブ化
print("5秒以内にウィンドウをクリックしてアクティブにしてください...")
time.sleep(5)

for i in range(n_pages):
    screenshot = pyautogui.screenshot(region=region)
    screenshot.save("temp.png")
    text = pytesseract.image_to_string(Image.open("temp.png"), lang='jpn')
    with open(output_file, "a", encoding="utf-8") as f:
        f.write(f"--- page {i+1} ---\n")
        f.write(text + "\n\n")

    print(f"Page {i+1} OCR完了")
    pyautogui.press('right')
    #time.sleep(1)

print("全ページ処理が完了しました！")
