# ===== BGInfo 完全自動セットアップ：エラー対応・フォールバック付き =====
$ErrorActionPreference = 'Stop'

Write-Host "=== BGInfo 完全自動セットアップを開始します ===" -ForegroundColor Green

# 配置先（全ユーザー共通）
$DstDir = "C:\ProgramData\BGInfo"
$DstExe = Join-Path $DstDir "Bginfo.exe"
$DstBgi = Join-Path $DstDir "Default.bgi"

# 1) 既存のBGInfoプロセスを終了
Write-Host "既存のBGInfoプロセスを終了中..."
Get-Process -Name "Bginfo*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# 2) BGInfo が未配置なら Sysinternals から取得
if (-not (Test-Path $DstExe)) {
    Write-Host "BGInfo をダウンロード中..."
    $tmp = Join-Path $env:TEMP ("BGInfo_" + [guid]::NewGuid() + ".zip")
    $url = "https://download.sysinternals.com/files/BGInfo.zip"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmp
        New-Item -Path $DstDir -ItemType Directory -Force | Out-Null
        Expand-Archive -Path $tmp -DestinationPath $DstDir -Force
        
        # 64bit 実行ファイルを既定名にコピー
        if (Test-Path (Join-Path $DstDir "Bginfo64.exe")) {
            Copy-Item (Join-Path $DstDir "Bginfo64.exe") $DstExe -Force
            Write-Host "BGInfo64.exe を配置しました"
        } elseif (Test-Path (Join-Path $DstDir "Bginfo.exe")) {
            # 既にBginfo.exeが存在する場合はそのまま使用
            Write-Host "BGInfo.exe を確認しました"
        } else {
            throw "BGInfo実行ファイルが見つかりません"
        }
        
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "BGInfoのダウンロード・配置完了" -ForegroundColor Green
    } catch {
        Write-Host "エラー: BGInfoのダウンロードに失敗しました - $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "BGInfo.exe は既に配置済みです"
}

# 3) 最適化された設定ファイルを作成
Write-Host "設定ファイルを作成中..."
$bgiContentOptimized = @'
[BGInfo]
RTF={\rtf1\ansi\deff0 {\fonttbl {\f0 Times New Roman;}}{\colortbl ;\red255\green255\blue255;\red0\green0\blue0;}\f0 \fs20 \cf2 \cb1 Boot Time: <Boot Time>\line CPU: <CPU>\line Total RAM: <Memory>\line Available RAM: <Memory Available>\line User Name: <User Name>\line Machine Name: <Machine Name>\line OS Version: <OS Version>\line}
Position=2
TextWidth2=280
TextHeight2=200
LimitTextWidth=0
BalloonTip=1
'@

try {
    $bgiContentOptimized | Out-File -FilePath $DstBgi -Encoding ASCII -Force
    Write-Host "最適化設定ファイル作成完了"
} catch {
    Write-Host "警告: 設定ファイル作成に失敗しました" -ForegroundColor Yellow
}

# 4) 設定ファイル付きで実行テスト
Write-Host "設定ファイル付きでテスト実行中..."
$settingsSuccess = $false

if (Test-Path $DstBgi) {
    try {
        $testProcess = Start-Process -FilePath $DstExe -ArgumentList "`"$DstBgi`" /accepteula /silent /timer:0" -PassThru -Wait -WindowStyle Hidden
        Write-Host "設定ファイル付き実行 ExitCode: $($testProcess.ExitCode)"
        
        if ($testProcess.ExitCode -eq 0) {
            $settingsSuccess = $true
            Write-Host "✓ 設定ファイル付き実行成功" -ForegroundColor Green
            $finalCommand = "`"$DstExe`" `"$DstBgi`" /accepteula /silent /timer:0"
        } else {
            Write-Host "! 設定ファイルでエラー発生（ExitCode: $($testProcess.ExitCode)）" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "! 設定ファイル付き実行で例外発生: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 5) フォールバック: デフォルト設定で実行
if (-not $settingsSuccess) {
    Write-Host "デフォルト設定で実行中..."
    try {
        $defaultProcess = Start-Process -FilePath $DstExe -ArgumentList "/accepteula /silent /timer:0" -PassThru -Wait -WindowStyle Hidden
        Write-Host "デフォルト設定実行 ExitCode: $($defaultProcess.ExitCode)"
        
        if ($defaultProcess.ExitCode -eq 0) {
            Write-Host "✓ デフォルト設定での実行成功" -ForegroundColor Green
            $finalCommand = "`"$DstExe`" /accepteula /silent /timer:0"
        } else {
            Write-Host "✗ デフォルト設定でもエラーが発生しました（ExitCode: $($defaultProcess.ExitCode)）" -ForegroundColor Red
            Write-Host "BGInfoの実行に問題があります。手動で確認してください。"
            exit 1
        }
    } catch {
        Write-Host "✗ デフォルト設定実行で例外発生: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# 6) 自動起動をレジストリに登録
Write-Host "自動起動を登録中..."
$runKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

try {
    New-ItemProperty -Path $runKey -Name "BgInfo" -Value $finalCommand -PropertyType String -Force | Out-Null
    Write-Host "✓ 自動起動登録完了: $finalCommand" -ForegroundColor Green
} catch {
    Write-Host "警告: 自動起動の登録に失敗しました - $($_.Exception.Message)" -ForegroundColor Yellow
}

# 7) 最終確認
Start-Sleep -Seconds 3
Write-Host ""
Write-Host "=== セットアップ完了 ===" -ForegroundColor Green

# プロセス確認
$finalProcess = Get-Process -Name "Bginfo*" -ErrorAction SilentlyContinue
if ($finalProcess) {
    Write-Host "✓ BGInfoプロセスが実行中です"
} else {
    Write-Host "✓ BGInfo実行完了（壁紙に情報が表示されているはずです）"
}

# 設定状況表示
Write-Host ""
Write-Host "=== 設定状況 ===" -ForegroundColor Cyan
Write-Host "BGInfo.exe: $(if(Test-Path $DstExe){'✓ 配置済み'}else{'✗ 未配置'})"
Write-Host "設定ファイル: $(if($settingsSuccess){'✓ 使用中（右上表示）'}else{'✗ 使用せず（デフォルト位置）'})"
$regCheck = try { (Get-ItemProperty $runKey -Name 'BgInfo' -ErrorAction Stop).BgInfo; "✓ 登録済み" } catch { "✗ 未登録" }
Write-Host "自動起動: $regCheck"

# 使用方法ガイド
Write-Host ""
Write-Host "=== 使用方法 ===" -ForegroundColor Cyan
Write-Host "■ 手動実行（現在の設定）:"
Write-Host "  $finalCommand"
Write-Host ""
Write-Host "■ 設定変更（GUIを開く）:"
if ($settingsSuccess) {
    Write-Host "  `"$DstExe`" `"$DstBgi`""
} else {
    Write-Host "  `"$DstExe`""
}
Write-Host ""
Write-Host "■ 表示位置変更用ワンライナー:"
Write-Host "  右上: \$dir='C:\ProgramData\BGInfo'; '[BGInfo]'+\"`nPosition=2\`nTextWidth2=280\`nTextHeight2=200\" | Out-File \"\$dir\Default.bgi\" -Encoding ASCII -Force; & \"\$dir\Bginfo.exe\" \"\$dir\Default.bgi\" /accepteula /silent /timer:0"
Write-Host "  左上: Position=0, 右下: Position=1, 左下: Position=3"
Write-Host ""

# アンインストール手順
Write-Host "=== アンインストール手順 ===" -ForegroundColor Yellow
Write-Host "■ 完全削除ワンライナー:"
Write-Host "  Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'BgInfo' -Force -ErrorAction SilentlyContinue; Get-Process -Name 'Bginfo*' -ErrorAction SilentlyContinue | Stop-Process -Force; Remove-Item -Path '$DstDir' -Recurse -Force -ErrorAction SilentlyContinue; Write-Host '壁紙を手動で元に戻してください'"
Write-Host ""
Write-Host "■ 手動での壁紙復元:"
Write-Host "  1. デスクトップ右クリック → 個人用設定"
Write-Host "  2. 背景 → お好みの画像を選択"
Write-Host ""

# トラブルシューティング
Write-Host "=== トラブルシューティング ===" -ForegroundColor Magenta
Write-Host "■ 表示されない場合の確認コマンド:"
Write-Host "  \$p = Start-Process '$DstExe' -ArgumentList '/accepteula /silent /timer:0' -PassThru -Wait; Write-Host 'ExitCode:' \$p.ExitCode"
Write-Host ""
Write-Host "■ プロセス確認:"
Write-Host "  Get-Process -Name 'Bginfo*' -ErrorAction SilentlyContinue"
Write-Host ""
Write-Host "■ レジストリ確認:"
Write-Host "  Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'BgInfo'"
Write-Host ""

Write-Host "🎉 BGInfo セットアップが完了しました！" -ForegroundColor Green
Write-Host "次回ログオン時から自動的に表示されます。" -ForegroundColor Green

if ($settingsSuccess) {
    Write-Host "✓ 右上に表示される設定になっています" -ForegroundColor Green
} else {
    Write-Host "! デフォルト位置（通常は右下）に表示されます" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "壁紙を確認してBGInfoが表示されているかご確認ください。" -ForegroundColor White -BackgroundColor Blue
