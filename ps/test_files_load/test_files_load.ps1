# === 設定 ===
$DriveLetter = "V"
$BaseFolder  = "$DriveLetter`:\LoadTest"
$FileSizeMB  = 50       # 1ファイルあたりのサイズ
$FileCount   = 500      # 同時に扱うファイル数

# === フォルダ自動作成（既存があれば連番フォルダにする） ===
$counter = 1
$TestFolder = $BaseFolder
while (Test-Path $TestFolder) {
    $TestFolder = "${BaseFolder}_$counter"
    $counter++
}
New-Item -ItemType Directory -Path $TestFolder | Out-Null
Write-Host "Created test folder: $TestFolder" -ForegroundColor Green

# === 無限負荷ループ開始 ===
Write-Host "=== Starting infinite load test on $TestFolder ===" -ForegroundColor Yellow
Write-Host "Press Ctrl + C to stop." -ForegroundColor Yellow

try {
    while ($true) {
        $writeStart = Get-Date

        # 1. 書き込みフェーズ
        for ($i = 1; $i -le $FileCount; $i++) {
            $filePath = Join-Path $TestFolder ("TestFile_{0}.dat" -f $i)
            $data = New-Object byte[] ($FileSizeMB * 1MB)
            (New-Object System.Random).NextBytes($data)
            [System.IO.File]::WriteAllBytes($filePath, $data)

            Write-Host ("[WRITE] File {0}/{1} => {2}" -f $i, $FileCount, $filePath) -ForegroundColor Cyan
        }
        $writeEnd = Get-Date
        $writeSec = ($writeEnd - $writeStart).TotalSeconds
        $writeSpeed = [math]::Round(($FileCount * $FileSizeMB) / $writeSec, 2)

        # 2. 読み取りフェーズ
        $readStart = Get-Date
        Get-ChildItem -Path $TestFolder -File | ForEach-Object {
            $null = [System.IO.File]::ReadAllBytes($_.FullName)
            Write-Host ("[READ ] Reading {0}" -f $_.Name) -ForegroundColor Green
        }
        $readEnd = Get-Date
        $readSec = ($readEnd - $readStart).TotalSeconds
        $readSpeed = [math]::Round(($FileCount * $FileSizeMB) / $readSec, 2)

        # 3. サマリー表示
        Write-Host ("[{0}] Loop Finished - Write: {1} MB/s, Read: {2} MB/s" -f `
            (Get-Date -Format "HH:mm:ss"), $writeSpeed, $readSpeed) -ForegroundColor Yellow
        Write-Host "---------------------------------------------------------------"
    }
}
catch {
    Write-Warning "Load test stopped by user."
}
