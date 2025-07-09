# =============================================
# RunMaxCPUStress.ps1
# Author: yamapan
# License: MIT License
# 日本語・英語両対応 (Japanese & English supported)
#
# 本スクリプトはWindows上でCPUに最大負荷をかけるためのPowerShellツールです。
# This script is a PowerShell tool for generating maximum CPU load on Windows.
# =============================================

param(
    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 0,  # 0 = 対話型で質問
    
    [Parameter(Mandatory=$false)]
    [int]$ThreadCount = 0,  # 0 = 自動最適化
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoOptimize = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails = $false
)

# 言語設定の自動検出
$isJapanese = (Get-Culture).Name -match "ja"

# 多言語メッセージ定義
$Messages = @{
    SystemInfoGathering = if ($isJapanese) { "=== システム情報取得中 ===" } else { "=== Gathering System Information ===" }
    OptimalThreads = if ($isJapanese) { "✓ 最適スレッド数: {0} (自動算出)" } else { "✓ Optimal Thread Count: {0} (Auto-calculated)" }
    AutoOptimizationEnabled = if ($isJapanese) { "✓ 自動最適化モード有効" } else { "✓ Auto-optimization Mode Enabled" }
    PowerProfileOptimizing = if ($isJapanese) { "電源プロファイルを高性能に設定中..." } else { "Setting power profile to high performance..." }
    PowerProfileOptimized = if ($isJapanese) { "✓ 電源プロファイル最適化完了" } else { "✓ Power profile optimization completed" }
    PowerProfileFailed = if ($isJapanese) { "⚠ 電源プロファイル設定に失敗: {0}" } else { "⚠ Power profile setting failed: {0}" }
    TestStarting = if ($isJapanese) { "=== 最適化CPU負荷テスト開始 ===" } else { "=== Starting Optimized CPU Stress Test ===" }
    TestCompleted = if ($isJapanese) { "=== CPU負荷テスト完了 ===" } else { "=== CPU Stress Test Completed ===" }
    Duration = if ($isJapanese) { "実行時間: {0} 秒" } else { "Duration: {0} seconds" }
    ThreadCount = if ($isJapanese) { "使用スレッド数: {0} (論理プロセッサ数: {1})" } else { "Thread Count: {0} (Logical Processors: {1})" }
    CPUCores = if ($isJapanese) { "CPUコア数: {0}" } else { "CPU Cores: {0}" }
    Memory = if ($isJapanese) { "メモリ: {0} GB" } else { "Memory: {0} GB" }
    StartTime = if ($isJapanese) { "開始時刻: {0}" } else { "Start Time: {0}" }
    EndTime = if ($isJapanese) { "終了時刻: {0}" } else { "End Time: {0}" }
    TestInProgress = if ($isJapanese) { "最適化CPU負荷テスト実行中" } else { "Optimized CPU Stress Test Running" }
    CPUUsage = if ($isJapanese) { "CPU使用率: {0}%" } else { "CPU Usage: {0}%" }
    CPUMeasuring = if ($isJapanese) { "CPU使用率: 測定中..." } else { "CPU Usage: Measuring..." }
    Progress = if ($isJapanese) { "進捗: {0}% - 残り時間: {1}秒" } else { "Progress: {0}% - Time Remaining: {1} seconds" }
    WaitingCompletion = if ($isJapanese) { "テスト完了待機中..." } else { "Waiting for test completion..." }
    ThreadResults = if ($isJapanese) { "=== スレッド別実行結果 ===" } else { "=== Thread Execution Results ===" }
    ThreadResult = if ($isJapanese) { "スレッド {0}: {1} 回実行" } else { "Thread {0}: {1} iterations" }
    CleanupCompleted = if ($isJapanese) { "クリーンアップ完了" } else { "Cleanup completed" }
    Warning = if ($isJapanese) { "警告: このスクリプトはCPUを最大負荷で使用します" } else { "Warning: This script will use CPU at maximum load" }
    SystemMayFreeze = if ($isJapanese) { "システムが応答しなくなる可能性があります" } else { "System may become unresponsive" }
    ConfirmExecution = if ($isJapanese) { "実行しますか？ (y/N)" } else { "Do you want to execute? (y/N)" }
    ExecutionCancelled = if ($isJapanese) { "実行をキャンセルしました" } else { "Execution cancelled" }
    ErrorOccurred = if ($isJapanese) { "エラーが発生しました: {0}" } else { "Error occurred: {0}" }
    InvalidDuration = if ($isJapanese) { "実行時間は1秒以上を指定してください" } else { "Duration must be 1 second or more" }
    InvalidThreadCount = if ($isJapanese) { "スレッド数は1以上を指定してください" } else { "Thread count must be 1 or more" }
    
    # 対話型質問
    DurationQuestion = if ($isJapanese) { "CPU負荷テストの実行時間を秒単位で入力してください" } else { "Enter CPU stress test duration in seconds" }
    DurationPrompt = if ($isJapanese) { "実行時間 (秒) [デフォルト: 60]" } else { "Duration (seconds) [Default: 60]" }
    InvalidInput = if ($isJapanese) { "無効な入力です。数値を入力してください。" } else { "Invalid input. Please enter a number." }
    
    # システム情報詳細
    CPUInfo = if ($isJapanese) { "CPU: {0} 論理プロセッサ, {1} コア" } else { "CPU: {0} logical processors, {1} cores" }
    MemoryInfo = if ($isJapanese) { "メモリ: {0} GB" } else { "Memory: {0} GB" }
    ArchitectureInfo = if ($isJapanese) { "アーキテクチャ: {0}" } else { "Architecture: {0}" }
}

function Get-SystemInfo {
    $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    
    return @{
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        Cores = $cpu.NumberOfCores
        MaxClockSpeed = $cpu.MaxClockSpeed
        TotalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
        OSArchitecture = $os.OSArchitecture
        PowerProfile = (powercfg /query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX)[4].Split()[-1]
    }
}

function Get-InteractiveDuration {
    Write-Host ""
    Write-Host $Messages.DurationQuestion -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $input = Read-Host $Messages.DurationPrompt
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            return 60  # デフォルト値
        }
        
        $duration = 0
        if ([int]::TryParse($input, [ref]$duration) -and $duration -gt 0) {
            return $duration
        }
        
        Write-Host $Messages.InvalidInput -ForegroundColor Red
    } while ($true)
}

function Set-PowerOptimization {
    param([bool]$Enable)
    
    if ($Enable) {
        Write-Host $Messages.PowerProfileOptimizing -ForegroundColor Yellow
        try {
            # 高性能電源プランに設定
            powercfg /setactive SCHEME_MIN | Out-Null
            
            # CPU最大パフォーマンスを100%に設定
            powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
            
            # CPU最小パフォーマンスを100%に設定（負荷テスト用）
            powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
            
            powercfg /setactive SCHEME_CURRENT | Out-Null
            
            Write-Host $Messages.PowerProfileOptimized -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host ($Messages.PowerProfileFailed -f $_.Exception.Message) -ForegroundColor Yellow
            return $false
        }
    }
}

function Get-OptimalThreadCount {
    param($SystemInfo)
    
    $logicalProcs = $SystemInfo.LogicalProcessors
    $cores = $SystemInfo.Cores
    $memoryGB = $SystemInfo.TotalMemoryGB
    
    # メモリ使用量を考慮したスレッド数計算
    $memoryBasedThreads = [math]::Min($logicalProcs, [math]::Floor($memoryGB / 0.1))
    
    # ハイパースレッディング検出
    $hasHyperThreading = $logicalProcs -gt $cores
    
    if ($hasHyperThreading) {
        # ハイパースレッディング有効時は論理プロセッサ数 + 50%で最適化
        $optimalThreads = [math]::Min($logicalProcs + [math]::Floor($logicalProcs * 0.5), $memoryBasedThreads)
    } else {
        # ハイパースレッディング無効時は論理プロセッサ数と同じ
        $optimalThreads = [math]::Min($logicalProcs, $memoryBasedThreads)
    }
    
    return [math]::Max(1, $optimalThreads)
}

function Start-OptimizedCPUStress {
    param(
        [int]$Duration,
        [int]$Threads,
        [hashtable]$SystemInfo,
        [bool]$ShowVerboseOutput
    )
    
    Write-Host $Messages.TestStarting -ForegroundColor Green
    Write-Host ($Messages.Duration -f $Duration) -ForegroundColor Yellow
    Write-Host ($Messages.ThreadCount -f $Threads, $SystemInfo.LogicalProcessors) -ForegroundColor Yellow
    Write-Host ($Messages.CPUCores -f $SystemInfo.Cores) -ForegroundColor Cyan
    Write-Host ($Messages.Memory -f $SystemInfo.TotalMemoryGB) -ForegroundColor Cyan
    Write-Host ($Messages.StartTime -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
    Write-Host ""
    
    # プロセス優先度を高に設定
    $currentProcess = Get-Process -Id $PID
    $currentProcess.PriorityClass = "High"
    
    $endTime = (Get-Date).AddSeconds($Duration)
    $jobs = @()
    
    # 最適化された負荷生成アルゴリズム
    $workloadScript = {
        param($EndTime, $ThreadId, $ShowVerboseOutput)
        
        # スレッドごとに異なる計算パターンで負荷分散
        $patterns = @(
            { param($i) [Math]::Sqrt($i) * [Math]::Sin($i) },
            { param($i) [Math]::Pow($i % 100, 2) * [Math]::Cos($i) },
            { param($i) [Math]::Log($i + 1) * [Math]::Tan($i % 45) },
            { param($i) [Math]::Exp($i % 10) * [Math]::Sqrt($i) }
        )
        
        $pattern = $patterns[$ThreadId % $patterns.Length]
        $iterations = 0
        
        while ((Get-Date) -lt $EndTime) {
            $result = 0
            
            # 動的ループサイズ調整
            $loopSize = if ($iterations % 1000 -eq 0) { 50000 } else { 25000 }
            
            for ($j = 1; $j -lt $loopSize; $j++) {
                $result += & $pattern $j
            }
            
            $iterations++
            
            # 定期的なGC実行でメモリ最適化
            if ($iterations % 10000 -eq 0) {
                [System.GC]::Collect()
            }
        }
        
        if ($ShowVerboseOutput) {
            return @{ ThreadId = $ThreadId; Iterations = $iterations }
        }
    }
    
    # 各スレッドでジョブを作成
    for ($i = 0; $i -lt $Threads; $i++) {
        $job = Start-Job -ScriptBlock $workloadScript -ArgumentList $endTime, $i, $ShowVerboseOutput
        $jobs += $job
    }
    
    # 動的進捗表示とパフォーマンス監視
    $startTime = Get-Date
    $lastCpuCheck = $startTime
    
    while ((Get-Date) -lt $endTime) {
        $elapsed = (Get-Date) - $startTime
        $remaining = $endTime - (Get-Date)
        $progress = [math]::Round(($elapsed.TotalSeconds / $Duration) * 100, 1)
        
        # CPU使用率監視（5秒間隔）
        if (((Get-Date) - $lastCpuCheck).TotalSeconds -ge 5) {
            try {
                $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
                $status = $Messages.CPUUsage -f [math]::Round($cpuUsage, 1)
                $lastCpuCheck = Get-Date
            }
            catch {
                $status = $Messages.CPUMeasuring
            }
        }
        else {
            $status = $Messages.Progress -f $progress, [math]::Round($remaining.TotalSeconds)
        }
        
        Write-Progress -Activity $Messages.TestInProgress -Status $status -PercentComplete $progress
        
        Start-Sleep -Milliseconds 250
    }
    
    Write-Progress -Activity $Messages.TestInProgress -Completed
    
    # 結果収集
    Write-Host $Messages.WaitingCompletion -ForegroundColor Yellow
    $results = $jobs | Wait-Job | Receive-Job
    
    if ($ShowVerboseOutput -and $results) {
        Write-Host ("`n" + $Messages.ThreadResults) -ForegroundColor Cyan
        $results | ForEach-Object {
            Write-Host ($Messages.ThreadResult -f $_.ThreadId, $_.Iterations) -ForegroundColor White
        }
    }
    
    # クリーンアップ
    $jobs | Remove-Job -Force
    
    Write-Host ""
    Write-Host $Messages.TestCompleted -ForegroundColor Green
    Write-Host ($Messages.EndTime -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
}

# メイン実行
try {
    Write-Host $Messages.SystemInfoGathering -ForegroundColor Cyan
    $systemInfo = Get-SystemInfo
    
    if ($ShowDetails) {
        Write-Host ($Messages.CPUInfo -f $systemInfo.LogicalProcessors, $systemInfo.Cores) -ForegroundColor White
        Write-Host ($Messages.MemoryInfo -f $systemInfo.TotalMemoryGB) -ForegroundColor White
        Write-Host ($Messages.ArchitectureInfo -f $systemInfo.OSArchitecture) -ForegroundColor White
    }
    
    # 対話型で実行時間を取得
    if ($DurationSeconds -eq 0) {
        $DurationSeconds = Get-InteractiveDuration
    }
    
    # スレッド数の自動最適化
    if ($ThreadCount -eq 0) {
        $ThreadCount = Get-OptimalThreadCount -SystemInfo $systemInfo
        Write-Host ($Messages.OptimalThreads -f $ThreadCount) -ForegroundColor Green
    }
    
    # パラメータ検証
    if ($DurationSeconds -le 0) {
        throw $Messages.InvalidDuration
    }
    
    if ($ThreadCount -le 0) {
        throw $Messages.InvalidThreadCount
    }
    
    # 自動最適化実行
    if ($AutoOptimize) {
        Write-Host $Messages.AutoOptimizationEnabled -ForegroundColor Green
        Set-PowerOptimization -Enable $true | Out-Null
    }
    
    # 警告とユーザー確認
    Write-Host ""
    Write-Host $Messages.Warning -ForegroundColor Red
    Write-Host $Messages.SystemMayFreeze -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host $Messages.ConfirmExecution
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        Start-OptimizedCPUStress -Duration $DurationSeconds -Threads $ThreadCount -SystemInfo $systemInfo -ShowVerboseOutput $ShowDetails
    } else {
        Write-Host $Messages.ExecutionCancelled -ForegroundColor Yellow
    }
}
catch {
    Write-Error ($Messages.ErrorOccurred -f $_.Exception.Message)
}
finally {
    # クリーンアップ
    Get-Job | Where-Object { $_.State -eq 'Running' } | Stop-Job -PassThru | Remove-Job -Force
    
    # プロセス優先度を元に戻す
    try {
        $currentProcess = Get-Process -Id $PID
        $currentProcess.PriorityClass = "Normal"
    }
    catch { }
    
    Write-Host $Messages.CleanupCompleted -ForegroundColor Green
}