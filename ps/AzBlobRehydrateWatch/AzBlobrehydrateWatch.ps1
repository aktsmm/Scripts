param (
    [string]$StorageAccount,
    [string]$Container,
    [string]$Prefix,
    [string]$ResourceGroup = $(throw "❗ ResourceGroup を指定してください"),
    [int]$IntervalSeconds = 5
)

$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context
$logDir = "$PSScriptRoot\rehydrate_monitor_logs"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$progressLog = Join-Path $logDir "progress.log"
$summaryLog = Join-Path $logDir "summary.log"

"▶ 監視開始: $(Get-Date)" | Tee-Object -FilePath $progressLog -Append

# 初期取得（Created最小の検出用）
$blobs = Get-AzStorageBlob -Container $Container -Context $ctx -Prefix $Prefix
$blobStates = @{}

foreach ($blob in $blobs) {
    $blob.ICloudBlob.FetchAttributes()
    $created = $blob.ICloudBlob.Properties.Created.UtcDateTime
    $blobStates[$blob.Name] = [PSCustomObject]@{
        Name    = $blob.Name
        Created = $created
        IsHot   = $false
    }
}
$oldestCreated = ($blobStates.Values | Sort-Object Created)[0].Created

# 監視ループ
while ($true) {
    $hotCount = 0
    foreach ($blob in $blobStates.Values) {
        $current = Get-AzStorageBlob -Container $Container -Context $ctx -Blob $blob.Name
        $current.ICloudBlob.FetchAttributes()
        $tier = $current.ICloudBlob.Properties.StandardBlobTier
        $status = $current.ICloudBlob.Properties.ArchiveStatus

        $blob.IsHot = ($tier -eq "Hot" -and [string]::IsNullOrEmpty($status))
        if ($blob.IsHot) { $hotCount++ }
    }

    $now = Get-Date
    $statusLine = "⏳ $($now.ToString("HH:mm:ss")) - HOT: $hotCount / $($blobStates.Count)"
    Write-Host $statusLine
    $statusLine | Add-Content -Path $progressLog

    if ($hotCount -eq $blobStates.Count) {
        $completedAt = Get-Date
        $duration = $completedAt.ToUniversalTime() - $oldestCreated
        $summary = @"
✅ すべての BLOB が HOT に移行完了
▶ 完了時刻: $completedAt
▶ 最古の作成時刻: $oldestCreated
▶ 所要時間: $([math]::Round($duration.TotalMinutes, 2)) 分
"@
        Write-Host $summary
        $summary | Tee-Object -FilePath $summaryLog
        break
    }

    Start-Sleep -Seconds $IntervalSeconds
}
