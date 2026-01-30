# IoT MVP - Run All Tests
# This script runs tests for all project components

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - Running All Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    gateway = $false
    webDashboard = $false
    mobileApp = $false
    cloud = $false
}

# Test Gateway
Write-Host "[1/4] Testing Gateway (Python)..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\gateway"
if (Test-Path "tests") {
    python -m pytest tests/ -v
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Gateway tests passed" -ForegroundColor Green
        $testResults.gateway = $true
    } else {
        Write-Host "✗ Gateway tests failed" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ Gateway tests not found (create tests/ directory)" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Test Web Dashboard
Write-Host "[2/4] Testing Web Dashboard (React)..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\web-dashboard"
if (Test-Path "package.json") {
    npm test -- --watchAll=false
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Web Dashboard tests passed" -ForegroundColor Green
        $testResults.webDashboard = $true
    } else {
        Write-Host "⚠ Web Dashboard tests not configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Web Dashboard not found" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Test Mobile App
Write-Host "[3/4] Testing Mobile App..." -ForegroundColor Cyan
Write-Host "⚠ Mobile App tests not configured" -ForegroundColor Yellow
Write-Host ""

# Test Cloud (Terraform validation)
Write-Host "[4/4] Validating Cloud Infrastructure..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\cloud\terraform"
if (Test-Path "main.tf") {
    terraform init -backend=false
    terraform validate
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Terraform configuration valid" -ForegroundColor Green
        $testResults.cloud = $true
    } else {
        Write-Host "✗ Terraform validation failed" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ Cloud infrastructure not found" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gateway:        $(if ($testResults.gateway) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($testResults.gateway) { 'Green' } else { 'Red' })
Write-Host "Web Dashboard:  $(if ($testResults.webDashboard) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($testResults.webDashboard) { 'Green' } else { 'Red' })
Write-Host "Mobile App:     ⚠ NOT CONFIGURED" -ForegroundColor Yellow
Write-Host "Cloud:          $(if ($testResults.cloud) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($testResults.cloud) { 'Green' } else { 'Red' })
Write-Host ""
