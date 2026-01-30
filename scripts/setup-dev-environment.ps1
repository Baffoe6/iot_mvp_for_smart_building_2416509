# IoT MVP - Development Environment Setup Script
# This script sets up the complete development environment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - Development Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js 18+ from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version
    Write-Host "✓ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Please install Python 3.11+ from https://python.org/" -ForegroundColor Red
    exit 1
}

# Check Terraform (optional)
try {
    $terraformVersion = terraform --version | Select-Object -First 1
    Write-Host "✓ Terraform: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ Terraform not found (optional for cloud deployment)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Yellow
Write-Host ""

# Setup Gateway
Write-Host "[1/3] Setting up Gateway (Python)..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\gateway"
if (Test-Path "requirements.txt") {
    python -m pip install -r requirements.txt
    Write-Host "✓ Gateway dependencies installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Gateway requirements.txt not found" -ForegroundColor Yellow
}
Pop-Location

Write-Host ""

# Setup Web Dashboard
Write-Host "[2/3] Setting up Web Dashboard (React)..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\web-dashboard"
if (Test-Path "package.json") {
    npm install
    Write-Host "✓ Web Dashboard dependencies installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Web Dashboard package.json not found" -ForegroundColor Yellow
}
Pop-Location

Write-Host ""

# Setup Mobile App
Write-Host "[3/3] Setting up Mobile App (React Native)..." -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\mobile-app"
if (Test-Path "package.json") {
    npm install --legacy-peer-deps
    Write-Host "✓ Mobile App dependencies installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Mobile App package.json not found" -ForegroundColor Yellow
}
Pop-Location

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Development environment setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Configure AWS credentials for cloud deployment" -ForegroundColor White
Write-Host "2. Update .env files with your configuration" -ForegroundColor White
Write-Host "3. Run 'scripts\start-local-dev.ps1' to start services" -ForegroundColor White
Write-Host ""
