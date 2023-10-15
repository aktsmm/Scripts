# PyAutoGUIと時間関数をインポートする
import pyautogui
from time import sleep, strftime
import  math

# カーソルを動かす関数を定義
def move_mouse_gohey():
    r = 60
    (mx, my) = pyautogui.size()
    pyautogui.moveTo(round(mx/2), round(my/2 -r-r))
    rad2deg = 360 / math.pi
    move_num = 40
    for t in range (move_num):
        round_t = 3
        step = 1/(move_num/round_t)
        x = r*math.cos(step*t*2*math.pi)
        y = r*math.sin(step*t*2*math.pi)
        pyautogui.move(x,y)
    pyautogui.press('shift')

# カーソルを監視し、一定時間動かない場合は動かす関数を呼び出す関数を定義

def move_mouse():
    # 監視するカーソルの動きの閾値
    wait_min = 1 # [min]
    count_sleep = 0 
    print(format(strftime('%H:%M:%S')), "Count:", count_sleep, "Seconds")
    # カーソルの現在位置を取得し、初期位置とする
    pos_orig = pyautogui.position()

    wait_min = int(wait_min)

    # 監視時間、チェック間隔を設定
    max_min = 10 # 10分間
    check_min = 5 # 5秒ごとに監視

    for idx in range(max_min):
        sleep(check_min)
        # カーソルの現在位置を取得し、移動距離を計算
        pos_current = pyautogui.position()
        dx = pos_orig.x - pos_current.x
        dy = pos_orig.y - pos_current.y
        dist = pow(dx*dx + dy*dy, 0.5)
        pos_orig = pos_current
        # 移動距離が閾値以下の場合はカウントアップ、それ以外はカウントリセット
        if dist < 20:
            count_sleep += 1
        else:
            count_sleep = 0

        print(format(strftime('%H:%M:%S')), "Count:", count_sleep*5, "Seconds")
        # カウントが閾値を超えた場合はカーソルを動かす関数を呼び出し、カウントをリセット
        if count_sleep > wait_min - 1:
            print("move")
            move_mouse_gohey()
            count_sleep = 0
            print(format(strftime('%H:%M:%S')), "Count", count_sleep*5, "Seconds")



# Mainループ
while True:
    move_mouse()
