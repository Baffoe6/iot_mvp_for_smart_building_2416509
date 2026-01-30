# IoT MVP - Start Local Development Servers
# This script starts the web dashboard and mobile app simultaneously

param(
    [switch]$WebOnly,
    [switch]$MobileOnly
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - Starting Development Servers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$jobs = @()

# Start Web Dashboard
if (-not $MobileOnly) {
    Write-Host "Starting Web Dashboard on http://localhost:3000..." -ForegroundColor Yellow
    $webJob = Start-Job -ScriptBlock {
        Set-Location $using:PSScriptRoot\..\web-dashboard
        npm run dev
    }
    $jobs += $webJob
    Write-Host "✓ Web Dashboard started (Job ID: $($webJob.Id))" -ForegroundColor Green
}

# Start Mobile App
if (-not $WebOnly) {
    Write-Host "Starting Mobile App on http://localhost:8082..." -ForegroundColor Yellow
    $mobileJob = Start-Job -ScriptBlock {
        Set-Location $using:PSScriptRoot\..\mobile-app
        python -m http.server 8082
    }
    $jobs += $mobileJob
    Write-Host "✓ Mobile App started (Job ID: $($mobileJob.Id))" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Development servers are running!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
if (-not $MobileOnly) {
    Write-Host "Web Dashboard:  http://localhost:3000" -ForegroundColor Cyan
}
if (-not $WebOnly) {
    Write-Host "Mobile App:     http://localhost:8082" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Press Ctrl+C to stop all servers..." -ForegroundColor Yellow
Write-Host ""

# Wait for user to press Ctrl+C
try {
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Check if any job failed
        foreach ($job in $jobs) {
            if ($job.State -eq "Failed") {
                Write-Host "⚠ Job $($job.Id) failed!" -ForegroundColor Red
                Receive-Job -Job $job
            }
        }
    }
} finally {
    Write-Host ""
    Write-Host "Stopping servers..." -ForegroundColor Yellow
    $jobs | Stop-Job
    $jobs | Remove-Job
    Write-Host "✓ All servers stopped" -ForegroundColor Green
}
