import pyautogui
import time

print("5秒以内に左上角にマウスを移動してください...")
time.sleep(5)
x1, y1 = pyautogui.position()
print(f"左上: ({x1}, {y1})")

print("次に右下角にマウスを移動してください...")
time.sleep(5)
x2, y2 = pyautogui.position()
print(f"右下: ({x2}, {y2})")

width = x2 - x1
height = y2 - y1
print(f"範囲: x={x1}, y={y1}, width={width}, height={height}")
