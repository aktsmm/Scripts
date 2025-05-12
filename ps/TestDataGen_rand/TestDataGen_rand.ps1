param(
    [int]$TotalFiles = $null,
    [int]$DepthLevel1 = $null,
    [int]$DepthLevel2 = $null,
    [int]$DepthLevel3 = $null,
    [int]$TotalSizeGB = $null,
    [string]$RootDir = $null
)

# デフォルト値
$defaultValues = @{
    TotalFiles  = 101
    DepthLevel1 = 3
    DepthLevel2 = 3
    DepthLevel3 = 3
    TotalSizeGB = 180
    RootDir     = "dataroot"
}

# 各パラメータに対して、未指定なら確認してからデフォルト適用
foreach ($param in $defaultValues.Keys) {
    if (-not (Get-Variable -Name $param).Value) {
        $useDefault = Read-Host "パラメータ '$param' が指定されていません。デフォルト値 '$($defaultValues[$param])' を使用しますか？(Y/N)"
        if ($useDefault -match '^[Yy]$') {
            Set-Variable -Name $param -Value $defaultValues[$param]
        }
        else {
            $inputValue = Read-Host "では、$param の値を入力してください"
            if ($param -match 'TotalFiles|DepthLevel|TotalSizeGB') {
                Set-Variable -Name $param -Value ([int]$inputValue)
            }
            else {
                Set-Variable -Name $param -Value $inputValue
            }
        }
    }
}

# 確認
Write-Host "`n▶ 実行設定の概要"
Write-Host "  TotalFiles    : $TotalFiles"
Write-Host "  DepthLevel1   : $DepthLevel1"
Write-Host "  DepthLevel2   : $DepthLevel2"
Write-Host "  DepthLevel3   : $DepthLevel3"
Write-Host "  TotalSizeGB   : $TotalSizeGB"
Write-Host "  RootDir       : $RootDir"


# 1ファイルあたりのサイズ（バイト）
$FileSizeBytes = [math]::Floor(($TotalSizeGB * 1024 * 1024 * 1024) / $TotalFiles)

Write-Host "`n▶ ディレクトリ構造を作成中..."
New-Item -Path $RootDir -ItemType Directory -Force | Out-Null

# 多階層ディレクトリの作成
for ($i = 1; $i -le $DepthLevel1; $i++) {
    for ($j = 1; $j -le $DepthLevel2; $j++) {
        for ($k = 1; $k -le $DepthLevel3; $k++) {
            $path = Join-Path -Path $RootDir -ChildPath "level1_$i\level2_$j\level3_$k"
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
}

# 対象ディレクトリ一覧取得（3階層目）
$TargetDirs = Get-ChildItem -Path $RootDir -Recurse -Directory | Where-Object { $_.FullName -match "level3_" }

$numDirs = $TargetDirs.Count
$filesPerDir = [math]::Floor($TotalFiles / $numDirs)
$remainingFiles = $TotalFiles % $numDirs

Write-Host "`n▶ 各ディレクトリに $filesPerDir ファイル、最初の $remainingFiles ディレクトリに +1"

# ランダムファイル生成関数
function New-RandomFile {
    param (
        [string]$FilePath,
        [int]$SizeBytes
    )
    $Buffer = New-Object byte[] $SizeBytes
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($Buffer)
    [System.IO.File]::WriteAllBytes($FilePath, $Buffer)
}

# ファイル作成ループ
$fileCount = 1
for ($dirIndex = 0; $dirIndex -lt $numDirs; $dirIndex++) {
    $dir = $TargetDirs[$dirIndex].FullName
    $fileCountInThisDir = $filesPerDir + ([int]($dirIndex -lt $remainingFiles))

    Write-Host "📁 $dir に $fileCountInThisDir ファイル作成中..."

    for ($i = 0; $i -lt $fileCountInThisDir; $i++) {
        $fileName = "file_{0:D3}" -f $fileCount
        $filePath = Join-Path $dir $fileName
        # プログレスバー表示
        $percentComplete = [math]::Round(($fileCount / $TotalFiles) * 100, 1)
        Write-Progress -Activity "ファイル作成中..." `
            -Status "$fileCount / $TotalFiles ファイル完了 ($percentComplete%)" `
            -PercentComplete $percentComplete

        # ファイル作成
        New-RandomFile -FilePath $filePath -SizeBytes $FileSizeBytes
        $fileCount++
        if ($fileCount -gt $TotalFiles) { break }
    }
}

# 検証用出力
$actualFiles = Get-ChildItem -Path $RootDir -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
$actualSizeBytes = (Get-ChildItem -Path $RootDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
$actualSizeGB = [math]::Round($actualSizeBytes / 1GB, 2)

Write-Host "`n✅ 完了！"
Write-Host "✔ 実際のファイル数: $actualFiles / 目標: $TotalFiles"
Write-Host "✔ 実際の合計サイズ: $actualSizeGB GB / 目標: $TotalSizeGB GB"
# 💡補足：技術的ポイント
# 項目              Bashスクリプト               PowerShell実装
# ランダムデータ    /dev/urandom を使う          RandomNumberGenerator.Fill()
# ディレクトリ作成  mkdir -p                    New-Item -ItemType Directory
# ファイル分配処理  seq & %で制御               forループとmod演算で制御
# 進捗表示          echo                        Write-Host
