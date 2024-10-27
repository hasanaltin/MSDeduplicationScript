# Author: HASAN ALTIN
# Website: hasanaltin.com
# Description: This PowerShell script provides a menu-driven interface to manage deduplication jobs on a specified volume.
# It allows users to start a deduplication optimization job, retrieve current deduplication job statuses, 
# check the overall deduplication status, and see live results for deduplication status.
# Results are cleared after 2, 5, and 20 seconds for better readability.
# Logs are saved in C:\ITLog, and existing logs are appended.

# Define log file paths
$logDir = "C:\ITLog"
$optimizationLog = "$logDir\DedupOptimizationLog.txt"
$statusLog = "$logDir\DedupStatusLog.txt"

# Create log directory if it does not exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Show-Menu {
    Clear-Host
    Write-Host "=== Deduplication Job Menu ===" -ForegroundColor Cyan
    Write-Host "1. Start Deduplication Job (Optimization)"
    Write-Host "2. Get Deduplication Job Status"
    Write-Host "3. Get Deduplication Status"
    Write-Host "4. Live Deduplication Status (Press any key to stop)"
    Write-Host "5. Exit"
}

function Run-DedupJob {
    $startTime = Get-Date
    Start-DedupJob -Type Optimization -Volume D:
    $startLogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Started Deduplication Job (Optimization) on Volume D at $($startTime.ToString('hh:mm tt')) on $($startTime.ToString('dddd')):`r`n"
    Add-Content -Path $optimizationLog -Value $startLogMessage

    # Wait until the job is completed
    while ($true) {
        $job = Get-DedupJob | Where-Object { $_.Status -eq 'Running' }
        if (-not $job) {
            break
        }
        Start-Sleep -Seconds 5
    }

    $endTime = Get-Date
    $completeLogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Completed Deduplication Job (Optimization) on Volume D that started at $($startTime.ToString('hh:mm tt')) on $($startTime.ToString('dddd')) and finished at $($endTime.ToString('hh:mm tt')) on $($endTime.ToString('dddd')).`r`n"
    Add-Content -Path $optimizationLog -Value $completeLogMessage
    Write-Host "Started and completed Deduplication Job (Optimization) on Volume D."
}

function Get-DedupJobStatus {
    $jobs = Get-DedupJob
    if ($jobs) {
        Write-Host "Current Deduplication Jobs:" -ForegroundColor Green
        $jobs | Format-Table -AutoSize
    } else {
        Write-Host "No current deduplication jobs."
    }
}

function Format-Size {
    param (
        [double]$sizeInBytes
    )

    if ($sizeInBytes -ge 1TB) {
        return "{0:N2} TB" -f ($sizeInBytes / 1TB)
    } elseif ($sizeInBytes -ge 1GB) {
        return "{0:N2} GB" -f ($sizeInBytes / 1GB)
    } elseif ($sizeInBytes -ge 1MB) {
        return "{0:N2} MB" -f ($sizeInBytes / 1MB)
    } elseif ($sizeInBytes -ge 1KB) {
        return "{0:N2} KB" -f ($sizeInBytes / 1KB)
    } else {
        return "{0:N2} Bytes" -f $sizeInBytes
    }
}

function Show-DedupStatus {
    $status = Get-DedupStatus
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Retrieved Deduplication Status:`r`n$status`r`n"
    Add-Content -Path $statusLog -Value $logMessage
    Write-Host "Current Deduplication Status:" -ForegroundColor Green

    # Calculate the deduplication percentage
    $dedupPercentage = if ($status.SavedSpace -gt 0 -and $status.SavedSpace + $status.FreeSpace -gt 0) {
        [math]::Round(($status.SavedSpace / ($status.SavedSpace + $status.FreeSpace)) * 100, 2)
    } else {
        0
    }

    # Prepare a formatted status object
    $formattedStatus = [PSCustomObject]@{
        FreeSpace       = Format-Size $status.FreeSpace
        SavedSpace      = Format-Size $status.SavedSpace
        DedupPercentage = "$dedupPercentage%"
        Volume          = $status.Volume
    }

    $formattedStatus | Format-Table -AutoSize
}

function Show-LiveDedupStatus {
    Write-Host "Press any key to stop live updates..." -ForegroundColor Yellow
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    while (-not $host.UI.RawUI.KeyAvailable) {
        Clear-Host
        Show-DedupStatus
        Start-Sleep -Seconds 5
    }

    $stopWatch.Stop()
    $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

do {
    Show-Menu
    $choice = Read-Host "Please select an option (1-5)"

    switch ($choice) {
        '1' {
            Run-DedupJob
            Start-Sleep -Seconds 2
        }
        '2' {
            Get-DedupJobStatus
            Start-Sleep -Seconds 5
        }
        '3' {
            Show-DedupStatus
            Start-Sleep -Seconds 20
        }
        '4' {
            Show-LiveDedupStatus
        }
        '5' {
            Write-Host "Exiting..." -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "Invalid choice. Please select 1, 2, 3, 4, or 5." -ForegroundColor Red
        }
    }
    
    # Clear the screen after waiting
    Clear-Host

} while ($true)
