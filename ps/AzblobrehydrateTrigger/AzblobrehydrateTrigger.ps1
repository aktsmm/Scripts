param (
    [string]$StorageAccount,
    [string]$Container,
    [string[]]$Prefixes,
    [string]$ResourceGroup = $(throw "❗ ResourceGroup を指定してください"),
    [int]$TimeoutMinutes = 240,
    [switch]$Urgent  # ← 新規追加
)


# ログディレクトリ作成
$logRoot = "$PSScriptRoot\rehydration_logs"
New-Item -Path $logRoot -ItemType Directory -Force | Out-Null
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context

foreach ($prefix in $Prefixes) {
    $logPath = Join-Path $logRoot "$($prefix.TrimEnd('/')).log"
    $startTime = Get-Date
    Write-Host "`n▶ $prefix のリハイドレートを開始（$startTime）"
    Add-Content -Path $logPath -Value "▶ Rehydrate started at: $startTime"

    $allBlobs = Get-AzStorageBlob -Container $Container -Context $ctx -Prefix $prefix
    $archiveBlobs = @()

    foreach ($blob in $allBlobs) {
        $blob.ICloudBlob.FetchAttributes()
        $tier = $blob.ICloudBlob.Properties.StandardBlobTier
        Write-Host "🔍 $($blob.Name) のTier: $tier"
        if ($tier -eq "Archive") {
            $archiveBlobs += $blob
        }
    }

    if ($archiveBlobs.Count -eq 0) {
        Write-Host "⚠ Archive BLOB は見つかりません（Prefix: $prefix）"
        continue
    }

    Write-Host "✅ Archive BLOB: $($archiveBlobs.Count) 件を Hot 層にコピー（プレフィックス: rehydrated/）"

    $index = 0
    $rehydratedNames = @()
    foreach ($blob in $archiveBlobs) {
        $index++
        $srcBlobName = $blob.Name
        $destBlobName = "rehydrate/$srcBlobName"
        $rehydratedNames += $destBlobName

        Write-Progress -Activity "コピー中 ($prefix)" `
            -Status "$index / $($archiveBlobs.Count): $srcBlobName" `
            -PercentComplete (($index / $archiveBlobs.Count) * 100)

        try {
            # RehydratePriority 判定
            $rehydratePriority = if ($Urgent) { "High" } else { "Standard" }

            Start-AzStorageBlobCopy -SrcContainer $Container `
                -SrcBlob $srcBlobName `
                -DestContainer $Container `
                -DestBlob $destBlobName `
                -StandardBlobTier Hot `
                -RehydratePriority $rehydratePriority `
                -Context $ctx

            Write-Host "✅ コピー要求: $srcBlobName → $destBlobName"
            Add-Content -Path $logPath -Value "[$(Get-Date -Format 'u')] ✅ Copy requested: $srcBlobName → $destBlobName"
        }
        catch {
            Write-Host "❌ 失敗: $srcBlobName → $destBlobName - $_" -ForegroundColor Red
            Add-Content -Path $logPath -Value "[$(Get-Date -Format 'u')] ❌ ERROR: $srcBlobName → $destBlobName -- $_"
        }
    }

    Write-Progress -Activity "コピー完了" -Completed
    Write-Host "`n⏳ リハイドレート完了までの監視を開始します..."

    # 状態監視ロジック
    $pending = @{}
    foreach ($name in $rehydratedNames) {
        $pending[$name] = $true
    }

    $elapsed = 0
    $intervalSec = 60
    $timeoutSec = $TimeoutMinutes * 60

    while ($pending.Count -gt 0 -and $elapsed -lt $timeoutSec) {
        Write-Host "`n⌛ 監視中: 残り $($pending.Count) 件, 経過: $([math]::Round($elapsed/60,1)) 分"

        foreach ($name in @($pending.Keys)) {
            try {
                $blobStatus = Get-AzStorageBlob -Container $Container -Blob $name -Context $ctx
                $blobStatus.ICloudBlob.FetchAttributes()
                $archiveStatus = $blobStatus.ICloudBlob.Properties.ArchiveStatus

                if ([string]::IsNullOrEmpty($archiveStatus)) {
                    $completeTime = Get-Date
                    $duration = $completeTime - $startTime
                    Write-Host "✅ 完了: $name（$([math]::Round($duration.TotalMinutes,2)) 分）"
                    Add-Content -Path $logPath -Value "[$($completeTime.ToString('u'))] ✅ $name 完了（$([math]::Round($duration.TotalMinutes,2)) 分）"
                    $pending.Remove($name)
                }
                else {
                    Write-Host "⌛ $name はまだリハイドレート中: $archiveStatus"
                }
            }
            catch {
                Write-Host "⚠ 取得エラー: $name - $_" -ForegroundColor Yellow
                Add-Content -Path $logPath -Value "[$(Get-Date -Format 'u')] ⚠ ERROR checking $name -- $_"
            }
        }

        if ($pending.Count -eq 0) { break }

        Start-Sleep -Seconds $intervalSec
        $elapsed += $intervalSec
    }

    Write-Progress -Activity "リハイドレート監視完了" -Completed
    $finalTime = Get-Date
    $totalTime = $finalTime - $startTime
    Write-Host "`n📊 $prefix の全処理完了: $([math]::Round($totalTime.TotalMinutes,2)) 分"
    Add-Content -Path $logPath -Value "`nSummary: $($rehydratedNames.Count) blobs monitored, Total time: $([math]::Round($totalTime.TotalMinutes,2)) minutes, Priority: $rehydratePriority, Completed at: $($finalTime.ToString('u'))"

}
Write-Host "▶ すべてのリハイドレート処理が完了しました。"
# 監視完了     