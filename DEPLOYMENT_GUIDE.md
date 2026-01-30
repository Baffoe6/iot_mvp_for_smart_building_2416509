 IoT MVP - Complete Deployment Guide

Step-by-step instructions to deploy the entire IoT MVP system from scratch.

 Overview

This guide will take you from zero to a fully operational IoT system monitoring air quality and occupancy in your building.

Estimated Time: 4-6 hours  
Skill Level: Intermediate to Advanced  
Prerequisites: AWS account, Raspberry Pi, basic Linux/cloud knowledge

---

 Architecture Recap

```
Sensors (20×) → Gateway (RPi) → AWS Cloud → Dashboard/Mobile
  (BLE)           (MQTT/TLS)      (IoT Core)    (HTTPS)
```

---

 Phase 1: Cloud Infrastructure (1-2 hours)

 Step 1.1: Setup AWS Account

1. Create AWS account at https://aws.amazon.com/
2. Enable billing alerts (Budget: £50/month)
3. Create IAM user with AdministratorAccess
4. Generate access keys for CLI

 Step 1.2: Configure AWS CLI

```bash
 Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

 Configure credentials
aws configure
 AWS Access Key ID: [your-key-id]
 AWS Secret Access Key: [your-secret-key]
 Default region: eu-west-1
 Default output format: json

 Test access
aws sts get-caller-identity
```

 Step 1.3: Create Terraform Backend

```bash
 Create S3 bucket for state
aws s3api create-bucket \
  --bucket iot-mvp-terraform-state-$(date +%s) \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

 Enable versioning
aws s3api put-bucket-versioning \
  --bucket iot-mvp-terraform-state- \
  --versioning-configuration Status=Enabled

 Create DynamoDB lock table
aws dynamodb create-table \
  --table-name iot-mvp-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

 Step 1.4: Deploy Infrastructure with Terraform

```bash
cd cloud/terraform

 Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

 Update backend configuration in main.tf
 Set bucket name to your S3 bucket created above

 Initialize Terraform
terraform init

 Review planned changes
terraform plan -var="environment=prod" -out=tfplan

 Apply (creates ~30 resources, takes 5-10 minutes)
terraform apply tfplan

 Save outputs for later use
terraform output -json > ../outputs.json

 Display key outputs
echo "IoT Endpoint: $(terraform output -raw iot_endpoint)"
echo "API Gateway URL: $(terraform output -raw api_gateway_url)"
echo "Cognito User Pool ID: $(terraform output -raw cognito_user_pool_id)"
```

 Step 1.5: Create IoT Certificates for Gateway

```bash
 Create gateway certificate
aws iot create-keys-and-certificate \
  --set-as-active \
  --certificate-pem-outfile gateway.crt \
  --public-key-outfile gateway_public.key \
  --private-key-outfile gateway.key \
  --region eu-west-1

 Get certificate ARN
CERT_ARN=$(aws iot list-certificates --query 'certificates[0].certificateArn' --output text)

 Attach policy
aws iot attach-policy \
  --policy-name iot-mvp-gateway-policy-prod \
  --target $CERT_ARN

 Download Amazon Root CA
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -o AmazonRootCA1.pem

 Securely store these files - you'll need them for gateway setup
mkdir -p ~/iot-mvp-certs
mv gateway.crt gateway.key gateway_public.key AmazonRootCA1.pem ~/iot-mvp-certs/
chmod 600 ~/iot-mvp-certs/
```

---

 Phase 2: Gateway Setup (1-2 hours)

 Step 2.1: Prepare Raspberry Pi

Hardware needed:
- Raspberry Pi 4 Model B (4GB RAM recommended)
- 32GB microSD card (Class 10 or better)
- Power supply (5V 3A USB-C)
- Ethernet cable (or WiFi configured)

```bash
 Flash Raspberry Pi OS Lite (64-bit) to SD card
 Use Raspberry Pi Imager: https://www.raspberrypi.com/software/

 Insert SD card and boot Raspberry Pi
 SSH into Pi (default password: raspberry)
ssh pi@raspberrypi.local

 Update system
sudo apt update && sudo apt full-upgrade -y
sudo reboot

 After reboot, SSH back in
ssh pi@raspberrypi.local
```

 Step 2.2: Install Gateway Software

```bash
 Install system dependencies
sudo apt install -y \
  python3-pip python3-venv \
  bluetooth bluez libbluetooth-dev \
  libglib2.0-dev libboost-python-dev \
  sqlite3 git

 Enable Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

 Clone repository (or copy files via SCP)
cd /opt
sudo git clone https://github.com/your-org/iot-mvp.git
sudo chown -R pi:pi iot-mvp
cd iot-mvp/gateway

 Create virtual environment
python3 -m venv venv
source venv/bin/activate

 Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

 Step 2.3: Configure Gateway

```bash
 Create certificate directory
sudo mkdir -p /etc/iot-mvp
sudo chmod 700 /etc/iot-mvp

 Copy certificates from your local machine
 Run this on your LOCAL machine:
scp ~/iot-mvp-certs/ pi@raspberrypi.local:/tmp/

 Back on Raspberry Pi, move certificates
sudo mv /tmp/gateway.crt /etc/iot-mvp/
sudo mv /tmp/gateway.key /etc/iot-mvp/
sudo mv /tmp/AmazonRootCA1.pem /etc/iot-mvp/
sudo chmod 644 /etc/iot-mvp/gateway.crt /etc/iot-mvp/AmazonRootCA1.pem
sudo chmod 600 /etc/iot-mvp/gateway.key

 Edit gateway configuration
nano gateway.py
 Update these values:
 - mqtt_broker: [your IoT endpoint from terraform output]
 - building_id: "building-001" (or your building ID)

 Create data directory
sudo mkdir -p /var/lib/iot-mvp
sudo chown pi:pi /var/lib/iot-mvp
```

 Step 2.4: Install as System Service

```bash
 Create systemd service file
sudo tee /etc/systemd/system/iot-mvp-gateway.service > /dev/null <<EOF
[Unit]
Description=IoT MVP Gateway Service
After=network.target bluetooth.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/iot-mvp/gateway
ExecStart=/opt/iot-mvp/gateway/venv/bin/python gateway.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

 Reload systemd
sudo systemctl daemon-reload

 Enable and start service
sudo systemctl enable iot-mvp-gateway
sudo systemctl start iot-mvp-gateway

 Check status
sudo systemctl status iot-mvp-gateway

 View logs
sudo journalctl -u iot-mvp-gateway -f
```

---

 Phase 3: Firmware Development (2-3 hours)

 Step 3.1: Setup Development Environment

Hardware needed:
- STM32WB55 Nucleo board (for development/testing)
- ST-Link V2 programmer
- USB cable

Software needed:
- STM32CubeIDE v1.14.0+
- STM32CubeProgrammer
- ARM GCC Toolchain

```bash
 Download STM32CubeIDE from:
 https://www.st.com/en/development-tools/stm32cubeide.html

 Install on Linux
sudo dpkg -i st-stm32cubeide.deb
sudo apt-get install -f

 Clone firmware repository
cd ~/workspace
git clone https://github.com/your-org/iot-mvp.git
cd iot-mvp/firmware
```

 Step 3.2: Build Firmware

```bash
 Open STM32CubeIDE
stm32cubeide &

 Import project:
 File → Import → Existing Projects into Workspace
 Select firmware/ directory

 Build:
 Project → Build All (or Ctrl+B)

 Flash to board:
 Run → Debug (F11)
 Or use command line:
make flash
```

 Step 3.3: Configure Sensors

Hardware connections:
- SCD40 (CO₂ sensor): I2C1 (SCL=PB6, SDA=PB7, VDD=3.3V, GND)
- PIR sensor: GPIO PA5 (interrupt), VDD=3.3V, GND
- Battery monitor: ADC1_IN14 (internal VBAT divider)

```c
// Update firmware_config.h with your settings:
define SAMPLING_INTERVAL_OCCUPIED_MS   (10  60  1000)  // 10 min
define SAMPLING_INTERVAL_VACANT_MS     (20  60  1000)  // 20 min
define CO2_ALERT_THRESHOLD_PPM         1200
define TEMP_ALERT_THRESHOLD_C          27.0f
```

 Step 3.4: Test and Validate

```bash
 Open serial terminal (115200 baud)
minicom -D /dev/ttyUSB0 -b 115200

 Expected output:
 [INFO] IoT MVP Firmware v1.0.0 starting...
 [INFO] Device ID: 12345678-ABCDEF01-DEADBEEF
 [INFO] SCD40 serial: 1234567890AB
 [INFO] BLE advertising started
 [SENS] CO2=450 ppm, Temp=22.3°C, Hum=45%, Occ=1
 [COMM] BLE adv sent
```

---

 Phase 4: Web Dashboard (30 minutes)

 Step 4.1: Setup Development Environment

```bash
 Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

 Verify installation
node --version   Should be v20.x
npm --version    Should be v10.x

 Navigate to dashboard directory
cd web-dashboard
```

 Step 4.2: Configure Dashboard

```bash
 Install dependencies
npm install

 Create .env file
cat > .env <<EOF
VITE_AWS_REGION=eu-west-1
VITE_IOT_ENDPOINT=$(cd ../cloud && terraform output -raw iot_endpoint)
VITE_API_GATEWAY_URL=$(cd ../cloud && terraform output -raw api_gateway_url)
VITE_COGNITO_USER_POOL_ID=$(cd ../cloud && terraform output -raw cognito_user_pool_id)
VITE_COGNITO_CLIENT_ID=$(cd ../cloud && terraform output -raw cognito_client_id)
EOF
```

 Step 4.3: Run Development Server

```bash
 Start development server
npm run dev

 Open browser to http://localhost:5173
 Dashboard should load (no data until sensors connect)
```

 Step 4.4: Build and Deploy to Production

```bash
 Build optimized production bundle
npm run build

 Deploy to S3 (if configured)
aws s3 sync dist/ s3://iot-mvp-dashboard-prod --delete

 Or deploy to any static hosting service:
 - Netlify: netlify deploy --prod --dir=dist
 - Vercel: vercel --prod
 - GitHub Pages: npm run deploy
```

---

 Phase 5: Mobile App (30 minutes)

 Step 5.1: Setup React Native Environment

```bash
 Install Expo CLI
npm install -g expo-cli eas-cli

 Navigate to mobile app directory
cd mobile-app

 Install dependencies
npm install
```

 Step 5.2: Configure Mobile App

```bash
 Create .env file
cat > .env <<EOF
EXPO_PUBLIC_AWS_REGION=eu-west-1
EXPO_PUBLIC_IOT_ENDPOINT=$(cd ../cloud && terraform output -raw iot_endpoint)
EXPO_PUBLIC_API_GATEWAY_URL=$(cd ../cloud && terraform output -raw api_gateway_url)
EXPO_PUBLIC_COGNITO_USER_POOL_ID=$(cd ../cloud && terraform output -raw cognito_user_pool_id)
EXPO_PUBLIC_COGNITO_CLIENT_ID=$(cd ../cloud && terraform output -raw cognito_client_id)
EOF
```

 Step 5.3: Run on Simulator/Device

```bash
 Start development server
npm start

 Scan QR code with Expo Go app (iOS/Android)
 Or press 'i' for iOS simulator, 'a' for Android emulator
```

 Step 5.4: Build Production Apps

```bash
 Configure EAS (Expo Application Services)
eas build:configure

 Build for iOS (requires Apple Developer account)
eas build --platform ios

 Build for Android
eas build --platform android

 Submit to app stores
eas submit --platform ios
eas submit --platform android
```

---

 Phase 6: Testing and Validation (1 hour)

 Step 6.1: End-to-End Test

Test 1: Sensor to Cloud
```bash
 On sensor device, trigger measurement
 Check gateway logs:
sudo journalctl -u iot-mvp-gateway -f | grep "CO2="

 Expected: "Published telemetry for [device_id]: CO2=XXX ppm"
```

Test 2: Cloud to Dashboard
```bash
 Query Timestream directly
aws timestream-query query --query-string \
  "SELECT  FROM \"iot-mvp-sensor-data-prod\".\"telemetry\" 
   WHERE time > ago(1h) 
   ORDER BY time DESC 
   LIMIT 10"

 Check dashboard shows data (refresh browser)
```

Test 3: Alerts
```bash
 Manually trigger high CO2 alert
 Or use AWS IoT Core Test client:
 Topic: building/building-001/gateway/gateway-xxx/device/xxx/telemetry
 Payload:
{
  "sensor_data": {
    "co2_ppm": 1500,
    "temperature_c": 22.5,
    "humidity_rh": 45.0
  }
}

 Check email for alert notification (5-60 seconds)
```

 Step 6.2: Performance Testing

```bash
 Test gateway capacity (scan for 20 devices)
cd gateway
python -c "
import asyncio
from gateway import GatewayApp, CONFIG
gateway = GatewayApp(CONFIG)
asyncio.run(gateway._scan_ble_devices())
"

 Check latency (sensor to dashboard)
 Expected: 18s mean, 27s 95th percentile

 Monitor AWS costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

 Expected: <£2/month for 20 devices
```

---

 Phase 7: Production Readiness

 Step 7.1: Setup Monitoring

```bash
 Create CloudWatch dashboard
aws cloudwatch put-dashboard \
  --dashboard-name IoT-MVP-Production \
  --dashboard-body file://monitoring/cloudwatch-dashboard.json

 Setup alarms
aws cloudwatch put-metric-alarm \
  --alarm-name iot-mvp-high-error-rate \
  --alarm-description "Alert on high IoT Core error rate" \
  --metric-name RuleMessageThrottled \
  --namespace AWS/IoT \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:eu-west-1:xxx:iot-mvp-alerts
```

 Step 7.2: Setup Backups

```bash
 Enable S3 versioning (already done in Terraform)
 Enable Timestream backups
aws timestream-write update-table \
  --database-name iot-mvp-sensor-data-prod \
  --table-name telemetry \
  --magnetic-store-write-properties EnableMagneticStoreWrites=true

 Schedule regular exports to S3
 (Create EventBridge rule + Lambda function)
```

 Step 7.3: Security Hardening

```bash
 Rotate certificates (annually)
aws iot update-certificate --certificate-id xxx --new-status INACTIVE

 Enable AWS IoT Device Defender
aws iot create-security-profile \
  --security-profile-name iot-mvp-security \
  --behaviors file://security/device-defender-behaviors.json

 Enable CloudTrail audit logging
aws cloudtrail create-trail \
  --name iot-mvp-audit \
  --s3-bucket-name iot-mvp-cloudtrail-logs
```

---

 Troubleshooting

 Gateway Not Connecting to AWS
```bash
 Check certificates
openssl x509 -in /etc/iot-mvp/gateway.crt -noout -dates

 Test MQTT connection
mosquitto_pub \
  --cafile /etc/iot-mvp/AmazonRootCA1.pem \
  --cert /etc/iot-mvp/gateway.crt \
  --key /etc/iot-mvp/gateway.key \
  -h $(cd cloud && terraform output -raw iot_endpoint) \
  -p 8883 \
  -t test/topic \
  -m "test"
```

 Sensors Not Appearing in Dashboard
```bash
 Check BLE scanning
sudo hcitool lescan

 Check gateway logs
sudo journalctl -u iot-mvp-gateway -n 100

 Check Timestream data
aws timestream-query query --query-string \
  "SELECT COUNT() FROM \"iot-mvp-sensor-data-prod\".\"telemetry\" 
   WHERE time > ago(1h)"
```

 High AWS Costs
```bash
 Check cost breakdown
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

 Optimize:
 - Reduce Timestream retention (90d → 30d)
 - Increase sensor sampling interval (10min → 15min)
 - Enable Lambda Provisioned Concurrency for frequent invocations
```

---

 Success Criteria

✅ Gateway connected to AWS IoT Core  
✅ Sensors transmitting data every 10-20 minutes  
✅ Timestream receiving and storing data  
✅ Dashboard showing real-time sensor data  
✅ Mobile app functional on iOS/Android  
✅ Alerts triggering for high CO2/temperature  
✅ Email notifications being received  
✅ Average current <50 µA (2.4-year battery life)  
✅ Cloud costs <£2/month (20 devices)  
✅ End-to-end latency <30 seconds (95th percentile)  

---

 Next Steps

1. Scale Deployment: Add more sensors (tested up to 20 per gateway)
2. ML Integration: Add anomaly detection (predict HVAC failures)
3. BMS Integration: Connect to BACnet for automated HVAC control
4. Multi-Tenancy: Deploy across multiple buildings

---

 Support

- Documentation: See `docs/` directory for detailed guides
- Issues: Report bugs on GitHub Issues
- Email: iot-mvp-team@example.com

---

Congratulations! Your IoT MVP system is now fully operational. 🎉

Total deployment time: ~4-6 hours  
Estimated monthly cost (20 devices): £2-3  
Expected battery life: 2.4 years  
HVAC energy savings: 15-30%
