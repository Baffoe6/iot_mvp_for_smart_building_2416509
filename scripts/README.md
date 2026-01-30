 IoT MVP - Automation Scripts

This directory contains automation scripts for building, deploying, and managing the IoT MVP project.

 Available Scripts

 Development Setup

 `setup-dev-environment.ps1`
Sets up the complete development environment by installing dependencies for all components.

```powershell
.\scripts\setup-dev-environment.ps1
```

What it does:
- Checks prerequisites (Node.js, Python, Terraform)
- Installs Gateway dependencies (Python packages)
- Installs Web Dashboard dependencies (npm packages)
- Installs Mobile App dependencies (npm packages with legacy peer deps)

---

 Local Development

 `start-local-dev.ps1`
Starts local development servers for web dashboard and mobile app.

```powershell
 Start both servers
.\scripts\start-local-dev.ps1

 Start only web dashboard
.\scripts\start-local-dev.ps1 -WebOnly

 Start only mobile app
.\scripts\start-local-dev.ps1 -MobileOnly
```

URLs:
- Web Dashboard: http://localhost:3000
- Mobile App: http://localhost:8082

Press `Ctrl+C` to stop all servers.

---

 Building

 `build-all.ps1`
Builds all project components for production deployment.

```powershell
.\scripts\build-all.ps1
```

Output: `build/` directory containing:
- `web-dashboard/` - Production React build
- `mobile-app.html` - Standalone mobile app
- `gateway/` - Python gateway files
- `manifest.json` - Build metadata

---

 Testing

 `test-all.ps1`
Runs tests for all project components.

```powershell
.\scripts\test-all.ps1
```

Tests:
- Gateway: Python pytest
- Web Dashboard: Jest tests
- Cloud: Terraform validation

---

 Cloud Deployment

 `deploy-cloud.ps1`
Deploys AWS infrastructure using Terraform.

```powershell
 Deploy to dev environment
.\scripts\deploy-cloud.ps1

 Deploy to production
.\scripts\deploy-cloud.ps1 -Environment prod

 Create deployment plan (dry-run)
.\scripts\deploy-cloud.ps1 -Plan

 Destroy infrastructure
.\scripts\deploy-cloud.ps1 -Destroy
```

Prerequisites:
- AWS CLI configured with credentials
- Terraform 1.6+ installed

What it deploys:
- AWS IoT Core (MQTT broker)
- AWS Timestream (time-series database)
- AWS Lambda (alert processing)
- AWS API Gateway (REST API)
- AWS Cognito (authentication)
- AWS S3 (firmware storage)

---

 Raspberry Pi Setup

 `setup-raspberry-pi.sh`
Sets up a Raspberry Pi as a BLE-to-MQTT gateway (Linux/bash script).

```bash
 On Raspberry Pi
chmod +x scripts/setup-raspberry-pi.sh
./scripts/setup-raspberry-pi.sh
```

What it does:
- Installs Python 3 and Bluetooth packages
- Creates `/opt/iot-mvp-gateway` directory
- Sets up Python virtual environment
- Installs gateway dependencies
- Creates systemd service for auto-start
- Configures logging

After setup:
1. Configure AWS credentials
2. Place certificates in `/etc/iot-mvp/`
3. Enable service: `sudo systemctl enable iot-gateway`
4. Start service: `sudo systemctl start iot-gateway`
5. Monitor logs: `sudo journalctl -u iot-gateway -f`

---

 Typical Workflow

 First-Time Setup
```powershell
 1. Install dependencies
.\scripts\setup-dev-environment.ps1

 2. Deploy cloud infrastructure
.\scripts\deploy-cloud.ps1 -Plan   Review plan
.\scripts\deploy-cloud.ps1         Deploy

 3. Start local development
.\scripts\start-local-dev.ps1
```

 Daily Development
```powershell
 Start development servers
.\scripts\start-local-dev.ps1

 Make changes to code...

 Run tests
.\scripts\test-all.ps1
```

 Production Deployment
```powershell
 1. Run tests
.\scripts\test-all.ps1

 2. Build production artifacts
.\scripts\build-all.ps1

 3. Deploy to production cloud
.\scripts\deploy-cloud.ps1 -Environment prod

 4. Upload web dashboard to S3
aws s3 sync build/web-dashboard/ s3://your-bucket-name/ --delete
```

 Gateway Deployment
```bash
 On Raspberry Pi
./scripts/setup-raspberry-pi.sh

 Configure credentials
sudo nano /opt/iot-mvp-gateway/config.json

 Start gateway service
sudo systemctl start iot-gateway
```

---

 Requirements

 Windows (PowerShell Scripts)
- PowerShell 5.1 or higher
- Node.js 18+
- Python 3.11+
- Terraform 1.6+ (for cloud deployment)
- AWS CLI (for cloud deployment)

 Linux (Bash Scripts)
- Bash 4.0+
- Python 3.11+
- Bluetooth packages (bluez)
- systemd (for service management)

---

 Troubleshooting

 "Terraform not found"
Install Terraform from https://terraform.io/downloads

 "AWS credentials not configured"
Run `aws configure` and enter your credentials

 "npm install fails"
Try using `--legacy-peer-deps` flag:
```powershell
npm install --legacy-peer-deps
```

 "Bluetooth not working on Raspberry Pi"
```bash
 Enable Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

 Check Bluetooth status
hciconfig
```

---

 Script Customization

All scripts are designed to be customizable. Edit the scripts to:
- Change port numbers
- Modify build directories
- Add custom deployment steps
- Configure additional services

---

 License

Proprietary - IoT MVP Team, January 2026
