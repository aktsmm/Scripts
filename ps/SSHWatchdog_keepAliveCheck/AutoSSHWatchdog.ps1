#region Helper Functions
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO" # INFO, WARN, ERROR, DEBUG
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp - $Message"

    switch ($Level.ToUpper()) {
        "INFO" { Write-Host $logEntry }
        "WARN" { Write-Warning $logEntry }
        "ERROR" { Write-Error $logEntry }
        "DEBUG" { Write-Host $logEntry -ForegroundColor Gray } # Example for debug messages
        default { Write-Host $logEntry }
    }
}
#endregion Helper Functions

#region Script Parameters and Configuration
# --- SSH Connection Information ---
$sshUser = Read-Host "Enter SSH username"
$sshHost = Read-Host "Enter SSH hostname or IP address"
$sshPort = Read-Host "Enter SSH port number (default is 22)"
if ([string]::IsNullOrWhiteSpace($sshPort)) {
    $sshPort = "22"
}
$sshKeyPath = Read-Host "Enter path to SSH private key (leave empty and press Enter for password authentication)"

# --- Script Behavior Parameters ---
[int]$successfulConnectionThresholdSeconds = 30 # Seconds a session must be active to be considered "successfully established"
[int]$maxRetries = 3                            # Maximum number of connection attempts for a single disconnection event
[int]$retryDelaySeconds = 5                     # Delay in seconds between reconnection attempts
[int]$initialConnectWaitSeconds = 3             # Seconds to wait to see if SSH connects or fails fast after process launch
[int]$sessionMonitoringIntervalSeconds = 5      # Interval to check session status and threshold
[int]$serverAliveIntervalSeconds = 5            # Seconds for SSH ServerAliveInterval
#endregion Script Parameters and Configuration

#region SSH Command Preparation
$sshArguments = @()
if (-not [string]::IsNullOrWhiteSpace($sshKeyPath)) {
    $sshArguments += "-i", "`"$sshKeyPath`""
}
$sshArguments += "-o", "ServerAliveInterval=$($serverAliveIntervalSeconds)" # Keep-alive packets
$sshArguments += "-p", $sshPort, "${sshUser}@${sshHost}"

# Optional: Add a command to run on the remote server after connection.
# Example: $remoteCommandToRun = "echo 'Session active. Keep-alive:'; while true; do date +%Y-%m-%d_%H:%M:%S; sleep 60; done"
# if ($remoteCommandToRun) { $sshArguments += $remoteCommandToRun }
#endregion SSH Command Preparation

#region Main Script Logic
Write-Log -Message "Preparing to connect to SSH: $sshUser@$sshHost (Port: $sshPort)"
Write-Log -Message "A connection will be considered 'established' if it remains active for at least $successfulConnectionThresholdSeconds seconds."

$attemptNumber = 0 # Current attempt number for the current series of disconnections
$sessionEstablishedAndNormallyTerminated = $false # Overall script success flag
$previousSessionWasEstablishedAndThenDropped = $false # True if a session >= threshold was lost non-normally

while ($attemptNumber -le $maxRetries -and -not $sessionEstablishedAndNormallyTerminated) {
    $currentTryDisplay = $attemptNumber + 1
    $totalAttemptsForSeries = $maxRetries + 1

    if ($attemptNumber -gt 0) {
        # This is a reconnection attempt
        Write-Log -Message "`nAttempting to reconnect in $($retryDelaySeconds) seconds... (Attempt $currentTryDisplay of $totalAttemptsForSeries for this disconnection event)"
        if ($previousSessionWasEstablishedAndThenDropped) {
            Write-Log -Message "Information: This reconnection attempt follows a previously established session (active for >= $($successfulConnectionThresholdSeconds)s) that was lost."
        }
        Start-Sleep -Seconds $retryDelaySeconds
    }
    else {
        # Initial attempt for this series
        Write-Log -Message "`nAttempting connection... (Attempt $currentTryDisplay of $totalAttemptsForSeries for this series)"
    }

    $sshProcess = $null
    $currentSessionStartTime = $null
    $currentSessionMetThreshold = $false # Tracks if the *current* session met the duration threshold

    try {
        Write-Log -Message "Launching SSH process..."
        $sshProcess = Start-Process -FilePath "ssh.exe" -ArgumentList $sshArguments -PassThru -ErrorAction SilentlyContinue

        if (-not $sshProcess) {
            Write-Log -Message "Failed to start ssh.exe process. Ensure ssh.exe is in your PATH or provide the full path." -Level WARN
        }
        else {
            Write-Log -Message "SSH process started (PID: $($sshProcess.Id)). Waiting $($initialConnectWaitSeconds)s for initial status..."
            Start-Sleep -Seconds $initialConnectWaitSeconds

            if ($sshProcess.HasExited) {
                Write-Log -Message "SSH process (PID: $($sshProcess.Id)) terminated prematurely. Exit code: $($sshProcess.ExitCode)." -Level WARN
            }
            else {
                $currentSessionStartTime = Get-Date
                Write-Log -Message "SSH connection appears active (PID: $($sshProcess.Id)). Monitoring session..."

                # Monitor the active SSH session
                while (-not $sshProcess.HasExited) {
                    Start-Sleep -Seconds $sessionMonitoringIntervalSeconds
                    if (-not $currentSessionMetThreshold) {
                        $sessionDurationSoFar = (Get-Date) - $currentSessionStartTime
                        if ($sessionDurationSoFar.TotalSeconds -ge $successfulConnectionThresholdSeconds) {
                            $currentSessionMetThreshold = $true
                            Write-Log -Message "Current session (PID: $($sshProcess.Id)) has now been active for at least $successfulConnectionThresholdSeconds seconds and is considered established for this attempt."
                            Write-Log -Message "Monitoring Start..." # User's original message
                            if ($previousSessionWasEstablishedAndThenDropped) {
                                Write-Log -Message "Maintenance might be in progress. (This reconnected session has been stable for $successfulConnectionThresholdSeconds seconds after a previously established session was lost)." -Level WARN
                                $previousSessionWasEstablishedAndThenDropped = $false # Reset flag after warning
                            }
                        }
                    }
                } # End of while (-not $sshProcess.HasExited)

                # SSH process has exited
                $sessionDuration = (Get-Date) - $currentSessionStartTime
                Write-Log -Message "SSH session (PID: $($sshProcess.Id)) ended. Exit code: $($sshProcess.ExitCode). Session duration: $($sessionDuration.ToString('g'))"

                if ($sshProcess.ExitCode -eq 0) {
                    # Normal termination
                    Write-Log -Message "SSH session terminated normally."
                    if ($currentSessionMetThreshold) {
                        Write-Log -Message "Session met the required active duration of $successfulConnectionThresholdSeconds seconds and terminated normally."
                        $sessionEstablishedAndNormallyTerminated = $true # Overall script success
                    }
                    else {
                        Write-Log -Message "Session terminated normally BUT was shorter than $successfulConnectionThresholdSeconds seconds. This attempt is considered failed." -Level WARN
                    }
                    $previousSessionWasEstablishedAndThenDropped = $false # Reset on normal termination
                }
                else {
                    # Abnormal termination (ExitCode != 0)
                    Write-Log -Message "SSH session was lost or terminated with an error (Exit code: $($sshProcess.ExitCode))." -Level WARN
                    if ($currentSessionMetThreshold) {
                        Write-Log -Message "This session WAS considered established (active for >= $successfulConnectionThresholdSeconds seconds) before being lost."
                        $previousSessionWasEstablishedAndThenDropped = $true
                        Write-Log -Message "Resetting attempt counter to start a new series of retries for this disconnection."
                        $attemptNumber = -1 # Will be incremented to 0 at the end of this loop iteration
                    }
                    else {
                        Write-Log -Message "This session was lost BEFORE being active for $successfulConnectionThresholdSeconds seconds (not considered established)."
                        $previousSessionWasEstablishedAndThenDropped = $false
                    }
                }
            }
        }
    }
    catch {
        Write-Log -Message "An unexpected error occurred during SSH attempt $($currentTryDisplay): ${($_.Exception.Message)}" -Level WARN
        if ($null -ne $sshProcess -and -not $sshProcess.HasExited) {
            try {
                Write-Log -Message "Attempting to stop potentially orphaned SSH process (PID: $($sshProcess.Id)) due to error." -Level WARN
                Stop-Process -Id $sshProcess.Id -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Log -Message "Could not stop orphaned SSH process: $($_.Exception.Message)" -Level WARN
            }
        }
    }

    if ($sessionEstablishedAndNormallyTerminated) {
        break # Exit the main retry loop
    }

    $attemptNumber++
} # End of while ($attemptNumber -le $maxRetries ...)
#endregion Main Script Logic

#region Final Status Reporting
if ($sessionEstablishedAndNormallyTerminated) {
    Write-Log -Message "`nScript finished: SSH session completed successfully and met all criteria."
}
else {
    Write-Log -Message "`nScript finished: All connection attempts in the last series failed or did not meet criteria. Please check network, SSH server configuration, credentials, and host availability." -Level ERROR
}
#endregion Final Status Reporting