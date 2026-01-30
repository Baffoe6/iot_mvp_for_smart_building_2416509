# IoT MVP - Deploy to AWS Cloud
# This script deploys the cloud infrastructure using Terraform

param(
    [switch]$Plan,
    [switch]$Destroy,
    [string]$Environment = "dev"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IoT MVP - AWS Cloud Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Terraform
try {
    $terraformVersion = terraform --version | Select-Object -First 1
    Write-Host "✓ Terraform: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Terraform not found. Please install Terraform 1.6+ from https://terraform.io/" -ForegroundColor Red
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version
    Write-Host "✓ AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI not found. Please install AWS CLI from https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Navigate to Terraform directory
$terraformDir = "$PSScriptRoot\..\cloud\terraform"
if (-not (Test-Path $terraformDir)) {
    Write-Host "✗ Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $terraformDir

Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Working directory: $terraformDir" -ForegroundColor Cyan
Write-Host ""

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Terraform initialization failed" -ForegroundColor Red
    Pop-Location
    exit 1
}
Write-Host "✓ Terraform initialized" -ForegroundColor Green
Write-Host ""

if ($Destroy) {
    # Destroy infrastructure
    Write-Host "WARNING: This will destroy all cloud resources!" -ForegroundColor Red
    $confirmation = Read-Host "Type 'yes' to confirm destruction"
    
    if ($confirmation -eq "yes") {
        Write-Host "Destroying infrastructure..." -ForegroundColor Yellow
        terraform destroy -var="environment=$Environment" -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Infrastructure destroyed" -ForegroundColor Green
        } else {
            Write-Host "✗ Destruction failed" -ForegroundColor Red
        }
    } else {
        Write-Host "Destruction cancelled" -ForegroundColor Yellow
    }
} elseif ($Plan) {
    # Plan only
    Write-Host "Creating deployment plan..." -ForegroundColor Yellow
    terraform plan -var="environment=$Environment" -out="tfplan"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Plan created successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "Review the plan above. To apply, run:" -ForegroundColor Cyan
        Write-Host "  terraform apply tfplan" -ForegroundColor White
    } else {
        Write-Host "✗ Planning failed" -ForegroundColor Red
    }
} else {
    # Apply infrastructure
    Write-Host "Deploying infrastructure..." -ForegroundColor Yellow
    terraform apply -var="environment=$Environment" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ Deployment complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Get outputs
        Write-Host "Infrastructure outputs:" -ForegroundColor Cyan
        terraform output
        
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Update web-dashboard/.env with API Gateway URL" -ForegroundColor White
        Write-Host "2. Deploy Lambda functions from cloud/lambda/" -ForegroundColor White
        Write-Host "3. Configure gateway with IoT Core endpoint" -ForegroundColor White
    } else {
        Write-Host "✗ Deployment failed" -ForegroundColor Red
    }
}

Pop-Location
Write-Host ""
