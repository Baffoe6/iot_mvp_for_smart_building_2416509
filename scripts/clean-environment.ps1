# IoT MVP - Clean Project Environment
# This script removes all temporary files, build artifacts, and dependencies

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - Cleaning Project Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalSize = 0
$itemsRemoved = 0

# Function to safely remove directory
function Remove-SafeDirectory {
    param([string]$Path, [string]$Name)
    
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        
        if ($size) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host "  Removing $Name... ($sizeMB MB)" -ForegroundColor Yellow
            Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
            
            if (-not (Test-Path $Path)) {
                Write-Host "  ✓ Removed $Name" -ForegroundColor Green
                $script:totalSize += $size
                $script:itemsRemoved++
            } else {
                Write-Host "  ⚠ Failed to remove $Name" -ForegroundColor Red
            }
        } else {
            Write-Host "  Removing $Name..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
            Write-Host "  ✓ Removed $Name" -ForegroundColor Green
            $script:itemsRemoved++
        }
    }
}

# Clean Web Dashboard
Write-Host "[1/3] Cleaning Web Dashboard..." -ForegroundColor Cyan
$webDir = "$PSScriptRoot\..\web-dashboard"
if (Test-Path $webDir) {
    Push-Location $webDir
    Remove-SafeDirectory "node_modules" "node_modules"
    Remove-SafeDirectory "dist" "dist build"
    Remove-SafeDirectory ".vite" ".vite cache"
    Remove-SafeDirectory ".cache" ".cache"
    
    # Remove lock files (optional)
    if (Test-Path "package-lock.json") {
        Remove-Item "package-lock.json" -Force
        Write-Host "  ✓ Removed package-lock.json" -ForegroundColor Green
    }
    Pop-Location
} else {
    Write-Host "  ⚠ Web Dashboard directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Clean Mobile App
Write-Host "[2/3] Cleaning Mobile App..." -ForegroundColor Cyan
$mobileDir = "$PSScriptRoot\..\mobile-app"
if (Test-Path $mobileDir) {
    Push-Location $mobileDir
    Remove-SafeDirectory "node_modules" "node_modules"
    Remove-SafeDirectory ".expo" ".expo cache"
    Remove-SafeDirectory ".expo-shared" ".expo-shared"
    Remove-SafeDirectory "dist" "dist build"
    Remove-SafeDirectory ".cache" ".cache"
    
    # Remove lock files (optional)
    if (Test-Path "package-lock.json") {
        Remove-Item "package-lock.json" -Force
        Write-Host "  ✓ Removed package-lock.json" -ForegroundColor Green
    }
    Pop-Location
} else {
    Write-Host "  ⚠ Mobile App directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Clean Gateway Python
Write-Host "[3/3] Cleaning Gateway..." -ForegroundColor Cyan
$gatewayDir = "$PSScriptRoot\..\gateway"
if (Test-Path $gatewayDir) {
    Push-Location $gatewayDir
    Remove-SafeDirectory "__pycache__" "__pycache__"
    Remove-SafeDirectory ".pytest_cache" ".pytest_cache"
    Remove-SafeDirectory "*.egg-info" "egg-info"
    Remove-SafeDirectory "venv" "venv"
    Remove-SafeDirectory "env" "env"
    
    # Remove Python bytecode files
    Get-ChildItem -Recurse -Filter "*.pyc" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
    }
    Write-Host "  ✓ Removed .pyc files" -ForegroundColor Green
    
    Pop-Location
} else {
    Write-Host "  ⚠ Gateway directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Clean Build Directory
$buildDir = "$PSScriptRoot\..\build"
if (Test-Path $buildDir) {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
    Remove-SafeDirectory $buildDir "build directory"
    Write-Host ""
}

# Clean Root Temporary Files
Write-Host "Cleaning root temporary files..." -ForegroundColor Cyan
$rootDir = "$PSScriptRoot\.."
Push-Location $rootDir

# Remove log files
Get-ChildItem -Filter "*.log" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "  ✓ Removed $($_.Name)" -ForegroundColor Green
}

# Remove temp files
Get-ChildItem -Filter "*.tmp" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "  ✓ Removed $($_.Name)" -ForegroundColor Green
}

Pop-Location
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Items removed: $itemsRemoved" -ForegroundColor Cyan
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
$totalSizeGB = [math]::Round($totalSize / 1GB, 2)
if ($totalSizeGB -gt 0.1) {
    Write-Host "Space freed: $totalSizeGB GB" -ForegroundColor Cyan
} else {
    Write-Host "Space freed: $totalSizeMB MB" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "To reinstall dependencies, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\setup-dev-environment.ps1" -ForegroundColor White
Write-Host ""
