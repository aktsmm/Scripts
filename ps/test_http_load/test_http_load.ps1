# === 設定 ===
$TargetURL = "http://48.210.196.231"
$ParallelJobs = 100
$RequestsPerJob = 10000
$TimeoutSec = 3  # 推奨: 5秒以上

Write-Host "Starting REAL-TIME RPS test on $TargetURL with $ParallelJobs parallel jobs..." -ForegroundColor Yellow
Write-Host "Press Ctrl + C to stop." -ForegroundColor Yellow

# === 出力同期用ミューテックス ===
$Mutex = [System.Threading.Mutex]::new($false)

# === 並列実行 ===
1..$ParallelJobs | ForEach-Object -Parallel {
    # 現在のジョブIDを取得（1から始まる連番）
    $JobID = $_

    # === HTTPクライアント初期化（HTTP/1.1固定） ===
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.MaxConnectionsPerServer = 100

    $http = [System.Net.Http.HttpClient]::new($handler)
    $http.DefaultRequestVersion     = [System.Net.HttpVersion]::Version11
    $http.DefaultVersionPolicy      = [System.Net.Http.HttpVersionPolicy]::RequestVersionExact
    $http.DefaultRequestHeaders.ConnectionClose = $false
    $http.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShellLoadTest")
    $http.Timeout = [TimeSpan]::FromSeconds($using:TimeoutSec)

    $statusCount = @{}
    $startTime = Get-Date
    $lastDisplay = $startTime
    $count = 0

    for ($i = 1; $i -le $using:RequestsPerJob; $i++) {
        try {
            $response = $http.GetAsync($using:TargetURL).GetAwaiter().GetResult()
            $codeStr = [string][int]$response.StatusCode
            if ($statusCount.ContainsKey($codeStr)) {
                $statusCount[$codeStr]++
            } else {
                $statusCount[$codeStr] = 1
            }
        } catch {
            if ($statusCount.ContainsKey("ERR")) {
                $statusCount["ERR"]++
            } else {
                $statusCount["ERR"] = 1
            }
        }

        $count++

        # 3秒ごとにRPS表示
        $now = Get-Date
        if (($now - $lastDisplay).TotalSeconds -ge 3) {
            $elapsedSec = ($now - $startTime).TotalSeconds
            $rps = [math]::Round($count / $elapsedSec, 2)
            # ステータスコードであることを明示
            $statusSummary = ($statusCount.GetEnumerator() | ForEach-Object { 
                if ($_.Key -eq "ERR") { "Errors:$($_.Value)" } else { "Status $($_.Key):$($_.Value)" }
            }) -join ", "
            Write-Host ("[Job {0}] {1} sec | RPS: {2} | {3}/{4} req | {5}" `
                -f $JobID, [math]::Round($elapsedSec,1), $rps, $count, $using:RequestsPerJob, $statusSummary) -ForegroundColor Cyan
            $lastDisplay = $now
        }
    }

    $finalSummary = ($statusCount.GetEnumerator() | ForEach-Object { 
        if ($_.Key -eq "ERR") { "Errors:$($_.Value)" } else { "Status $($_.Key):$($_.Value)" }
    }) -join ", "
    Write-Host ("[Job {0}] Finished | Total: {1} req | {2}" `
        -f $JobID, $count, $finalSummary) -ForegroundColor Yellow

} -ThrottleLimit $ParallelJobs
