# IoT MVP - Build All Components
# This script builds all project components for production

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - Building All Components" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$buildDir = "$PSScriptRoot\..\build"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create build directory
if (Test-Path $buildDir) {
    Write-Host "Cleaning old build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $buildDir
}
New-Item -ItemType Directory -Path $buildDir | Out-Null
Write-Host "✓ Build directory created: $buildDir" -ForegroundColor Green
Write-Host ""

# Build Web Dashboard
Write-Host "[1/3] Building Web Dashboard..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\web-dashboard"
if (Test-Path "package.json") {
    npm run build
    if (Test-Path "dist") {
        Copy-Item -Recurse "dist" "$buildDir\web-dashboard"
        Write-Host "✓ Web Dashboard built successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ Web Dashboard build output not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Web Dashboard not found" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Build Mobile App (web version)
Write-Host "[2/3] Building Mobile App..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\mobile-app"
if (Test-Path "index.html") {
    Copy-Item "index.html" "$buildDir\mobile-app.html"
    Write-Host "✓ Mobile App built successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Mobile App not found" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Package Gateway
Write-Host "[3/3] Packaging Gateway..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\gateway"
if (Test-Path "gateway.py") {
    $gatewayBuildDir = "$buildDir\gateway"
    New-Item -ItemType Directory -Path $gatewayBuildDir | Out-Null
    Copy-Item "*.py" $gatewayBuildDir
    Copy-Item "requirements.txt" $gatewayBuildDir -ErrorAction SilentlyContinue
    Copy-Item "README.md" $gatewayBuildDir -ErrorAction SilentlyContinue
    Write-Host "✓ Gateway packaged successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Gateway not found" -ForegroundColor Yellow
}
Pop-Location
Write-Host ""

# Create build manifest
$manifest = @{
    buildDate = $timestamp
    version = "1.0.0"
    components = @{
        webDashboard = Test-Path "$buildDir\web-dashboard"
        mobileApp = Test-Path "$buildDir\mobile-app.html"
        gateway = Test-Path "$buildDir\gateway"
    }
} | ConvertTo-Json

$manifest | Out-File "$buildDir\manifest.json"

Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Build complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Build output: $buildDir" -ForegroundColor Cyan
Write-Host "Build timestamp: $timestamp" -ForegroundColor Cyan
Write-Host ""
