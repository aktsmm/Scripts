# Azure VM ゲストエージェントの状態を自動で切り替えるスクリプト
# サービス名: WindowsAzureGuestAgent
# 管理者権限で実行してください
# $lang で表示言語を切り替え: "ja"（日本語）/ "en"（英語）
#
# 作成者: yamapan
# ライセンス: MIT License

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 言語設定: OSのUI言語が日本語なら"ja"、それ以外は"en"に自動判定
$osLang = [System.Globalization.CultureInfo]::InstalledUICulture.TwoLetterISOLanguageName
if ($osLang -eq "ja") {
    $lang = "ja"
} else {
    $lang = "en"
}

# メッセージ定義
$messages = @{
    ja = @{
        running = "サービスは起動中です。停止します..."
        stopped = "サービスは停止中です。起動します..."
        stoppedDone = "サービスを停止しました。"
        startedDone = "サービスを起動しました。"
        unknown = "サービスの状態: {0}。手動で確認してください。"
        notfound = "サービスが見つかりません。管理者権限で実行しているか、サービス名が正しいか確認してください。"
        pressKey = "何かキーを押すとウィンドウを閉じます..."
    }
    en = @{
        running = "Service is running. Stopping..."
        stopped = "Service is stopped. Starting..."
        stoppedDone = "Service has been stopped."
        startedDone = "Service has been started."
        unknown = "Service status: {0}. Please check manually."
        notfound = "Service not found. Please check if you are running as administrator and the service name is correct."
        pressKey = "Press any key to close this window..."
    }
}

$serviceName = "WindowsAzureGuestAgent"

try {
    # サービスの現在の状態を取得
    $service = Get-Service -Name $serviceName -ErrorAction Stop

    if ($service.Status -eq "Running") {
        # サービスが起動中なら停止
        Write-Host $messages[$lang].running -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force
        Write-Host $messages[$lang].stoppedDone -ForegroundColor Green
    } elseif ($service.Status -eq "Stopped") {
        # サービスが停止中なら起動
        Write-Host $messages[$lang].stopped -ForegroundColor Yellow
        Start-Service -Name $serviceName
        Write-Host $messages[$lang].startedDone -ForegroundColor Green
    } else {
        Write-Host ($messages[$lang].unknown -f $service.Status) -ForegroundColor Red
    }
} catch {
    Write-Host $messages[$lang].notfound -ForegroundColor Red
}

# ウィンドウを表示したままにするため、キー入力待ち
Write-Host $messages[$lang].pressKey -ForegroundColor Cyan
[void][System.Console]::ReadKey($true)
