    # IE Enhanced Security Configuration を無効化する
    # Windows Server 2019  で動作確認済み
    # 管理者用およびユーザー用のレジストリキー
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

    # 管理者用 IE ESC を無効化
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

    # ユーザー用 IE ESC を無効化
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

    # エクスプローラーを再起動して設定を反映
    Stop-Process -Name Explorer -Force