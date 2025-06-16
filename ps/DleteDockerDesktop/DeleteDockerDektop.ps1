# Docker 関連ディレクトリの完全削除スクリプト（Windows）

# 対象ディレクトリ一覧
$paths = @(
    "$env:APPDATA\Docker",
    "$env:LOCALAPPDATA\Docker",
    "$env:USERPROFILE\.docker",
    "$env:USERPROFILE\AppData\Roaming\Docker Desktop",
    "$env:USERPROFILE\AppData\Local\Docker Desktop",
    "$env:PROGRAMDATA\Docker",
    "$env:TEMP\DockerDesktop"
)

# WSL 側の仮想マシン削除（docker-desktop / docker-desktop-data）
Write-Host "🗑️ Stopping and unregistering WSL Docker distributions..." -ForegroundColor Yellow
wsl --unregister docker-desktop-data 2>$null
wsl --unregister docker-desktop 2>$null

# ローカルディレクトリ削除処理
foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "🧹 Deleting: $path" -ForegroundColor Cyan
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $path
    }
    else {
        Write-Host "✔️ Not found (already deleted): $path" -ForegroundColor DarkGray
    }
}

Write-Host "`n✅ Docker cleanup completed. You can now reinstall Docker Desktop." -ForegroundColor Green
