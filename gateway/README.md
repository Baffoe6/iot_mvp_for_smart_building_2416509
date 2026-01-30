 IoT MVP Gateway

Python-based gateway application for Raspberry Pi 4 that bridges BLE sensor devices to AWS IoT Core via MQTT.

 Overview

- Platform: Raspberry Pi 4 Model B (4GB RAM recommended)
- OS: Raspberry Pi OS Lite (64-bit, Debian Bookworm)
- Language: Python 3.11+
- Communication: BLE 5.2 scanning → MQTT/TLS 1.2 → AWS IoT Core
- Capacity: ~20 devices per gateway
- Power: 6W average (5V@1.2A USB-C)

 Features

- BLE Scanning: Continuous scanning for sensor advertisements (5s intervals)
- Local Buffering: 7-day SQLite buffer for network resilience (10,080 readings)
- MQTT Bridge: TLS 1.2 mutual authentication with AWS IoT Core
- Auto-Recovery: Automatic reconnection and buffered message replay
- OTA Support: Facilitates firmware updates for sensor devices
- Health Monitoring: Periodic status reporting and logging

 Architecture

```
┌──────────────────────────────────────────────────────┐
│             Raspberry Pi 4 Gateway                   │
│                                                      │
│  ┌───────────────┐         ┌──────────────────┐    │
│  │  BLE Scanner  │────────>│   SQLite Buffer  │    │
│  │  (bleak)      │         │   (7-day store)  │    │
│  └───────────────┘         └──────────────────┘    │
│         │                           │               │
│         v                           v               │
│  ┌────────────────────────────────────┐            │
│  │       MQTT Client (paho-mqtt)      │            │
│  │   TLS 1.2 + X.509 Mutual Auth      │            │
│  └────────────────────────────────────┘            │
└──────────────────────────────────────────────────────┘
                      │
                      │ Internet (TLS 1.2)
                      v
┌──────────────────────────────────────────────────────┐
│             AWS IoT Core (eu-west-1)                 │
│  ├── Rules Engine → Amazon Timestream                │
│  ├── Lambda Functions → SNS Alerts                   │
│  └── ACL Policies → Security                         │
└──────────────────────────────────────────────────────┘
```

 Installation

 1. Prepare Raspberry Pi

```bash
 Update system
sudo apt update && sudo apt full-upgrade -y

 Install dependencies
sudo apt install -y python3-pip python3-venv bluetooth bluez libbluetooth-dev \
    libglib2.0-dev libboost-python-dev libboost-thread-dev sqlite3

 Enable Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

 2. Install Gateway Software

```bash
 Clone repository (or copy files)
cd /opt
sudo git clone https://github.com/your-org/iot-mvp.git
cd iot-mvp/gateway

 Create virtual environment
python3 -m venv venv
source venv/bin/activate

 Install Python dependencies
pip install -r requirements.txt
```

 3. Configure AWS IoT Certificates

```bash
 Create certificate directory
sudo mkdir -p /etc/iot-mvp
sudo chmod 700 /etc/iot-mvp

 Copy certificates (generated in AWS IoT Core)
sudo cp ~/certs/AmazonRootCA1.pem /etc/iot-mvp/
sudo cp ~/certs/gateway-certificate.pem.crt /etc/iot-mvp/gateway.crt
sudo cp ~/certs/gateway-private.pem.key /etc/iot-mvp/gateway.key

 Set permissions
sudo chmod 644 /etc/iot-mvp/AmazonRootCA1.pem
sudo chmod 644 /etc/iot-mvp/gateway.crt
sudo chmod 600 /etc/iot-mvp/gateway.key
```

 4. Configure Gateway

Edit `gateway.py` configuration section or create `config.json`:

```json
{
  "building_id": "building-001",
  "mqtt_broker": "a3xxxxxxx-ats.iot.eu-west-1.amazonaws.com",
  "mqtt_port": 8883,
  "ca_cert_path": "/etc/iot-mvp/AmazonRootCA1.pem",
  "client_cert_path": "/etc/iot-mvp/gateway.crt",
  "client_key_path": "/etc/iot-mvp/gateway.key",
  "buffer_db_path": "/var/lib/iot-mvp/buffer.db",
  "log_level": "INFO"
}
```

 5. Install as Systemd Service

```bash
 Copy systemd service file
sudo cp iot-mvp-gateway.service /etc/systemd/system/

 Reload systemd
sudo systemctl daemon-reload

 Enable and start service
sudo systemctl enable iot-mvp-gateway
sudo systemctl start iot-mvp-gateway

 Check status
sudo systemctl status iot-mvp-gateway
```

 Usage

 Manual Execution
```bash
cd /opt/iot-mvp/gateway
source venv/bin/activate
python gateway.py
```

 Service Management
```bash
 Start gateway
sudo systemctl start iot-mvp-gateway

 Stop gateway
sudo systemctl stop iot-mvp-gateway

 Restart gateway
sudo systemctl restart iot-mvp-gateway

 View logs
sudo journalctl -u iot-mvp-gateway -f

 Or view log file
tail -f /var/log/iot-mvp-gateway.log
```

 MQTT Topics

 Telemetry (Published by Gateway)
```
building/{building_id}/gateway/{gateway_id}/device/{device_id}/telemetry
```

Payload example:
```json
{
  "version": "1.0",
  "gateway_id": "gateway-abcd1234",
  "device_id": "a4c138f5a1b2",
  "timestamp": 1706872350,
  "received_at": 1706872352,
  "sensor_data": {
    "co2_ppm": 650,
    "temperature_c": 22.5,
    "humidity_rh": 45.2,
    "occupancy": true,
    "battery_mv": 3200
  },
  "metadata": {
    "rssi": -65,
    "latency_ms": 2000
  }
}
```

 Status (Published by Gateway)
```
building/{building_id}/gateway/{gateway_id}/status
```

Payload example:
```json
{
  "status": "online",
  "timestamp": 1706872350,
  "version": "1.0.0",
  "uptime_seconds": 86400,
  "mqtt_connected": true,
  "active_devices": 15,
  "buffered_messages": 0
}
```

 OTA Update Request (Subscribed by Gateway)
```
building/{building_id}/gateway/{gateway_id}/ota/request
```

Payload example:
```json
{
  "device_id": "a4c138f5a1b2",
  "firmware_version": "1.0.1",
  "firmware_url": "s3://iot-mvp-firmware/v1.0.1/firmware.bin",
  "signature_url": "s3://iot-mvp-firmware/v1.0.1/firmware.sig"
}
```

 Database Schema

 telemetry_buffer table
```sql
CREATE TABLE telemetry_buffer (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    co2_ppm INTEGER,
    temperature_c REAL,
    humidity_rh REAL,
    occupancy INTEGER,
    battery_mv INTEGER,
    rssi INTEGER,
    received_at INTEGER NOT NULL,
    published INTEGER DEFAULT 0,
    published_at INTEGER
);
```

 Monitoring

 Health Checks
```bash
 Check gateway process
ps aux | grep gateway.py

 Check Bluetooth status
hciconfig hci0
sudo systemctl status bluetooth

 Check network connectivity
ping -c 3 a3xxxxxxx-ats.iot.eu-west-1.amazonaws.com

 View buffered messages
sqlite3 /var/lib/iot-mvp/buffer.db "SELECT COUNT() FROM telemetry_buffer WHERE published = 0;"
```

 Performance Metrics
- BLE scan rate: 5-second intervals
- MQTT publish latency: <100 ms (when online)
- End-to-end latency: 18s mean, 27s 95th percentile
- CPU usage: ~5% average (Raspberry Pi 4)
- Memory usage: ~150 MB
- Network bandwidth: ~10 KB/s (20 devices × 10-min sampling)

 Troubleshooting

 BLE Scanning Issues
```bash
 Reset Bluetooth adapter
sudo hciconfig hci0 down
sudo hciconfig hci0 up

 Check for interference
sudo hcitool lescan
```

 MQTT Connection Failures
```bash
 Test TLS connection
openssl s_client -connect a3xxxxxxx-ats.iot.eu-west-1.amazonaws.com:8883 \
  -CAfile /etc/iot-mvp/AmazonRootCA1.pem \
  -cert /etc/iot-mvp/gateway.crt \
  -key /etc/iot-mvp/gateway.key

 Check certificate expiry
openssl x509 -in /etc/iot-mvp/gateway.crt -noout -dates
```

 Database Corruption
```bash
 Check database integrity
sqlite3 /var/lib/iot-mvp/buffer.db "PRAGMA integrity_check;"

 Backup and rebuild if corrupted
sudo systemctl stop iot-mvp-gateway
cp /var/lib/iot-mvp/buffer.db /var/lib/iot-mvp/buffer.db.backup
sqlite3 /var/lib/iot-mvp/buffer.db ".dump" | sqlite3 /var/lib/iot-mvp/buffer_new.db
mv /var/lib/iot-mvp/buffer_new.db /var/lib/iot-mvp/buffer.db
sudo systemctl start iot-mvp-gateway
```

 Security

 Certificate Rotation
1. Generate new certificate in AWS IoT Core
2. Download new certificate and private key
3. Replace files in `/etc/iot-mvp/`
4. Restart gateway: `sudo systemctl restart iot-mvp-gateway`
5. Revoke old certificate in AWS IoT Core

 Firewall Configuration
```bash
 Allow only MQTT/TLS outbound
sudo ufw allow out 8883/tcp
sudo ufw enable
```

 Performance Tuning

 Increase BLE Scan Capacity
Edit `/etc/bluetooth/main.conf`:
```ini
[LE]
MinConnectionInterval=8
MaxConnectionInterval=12
```

Restart Bluetooth: `sudo systemctl restart bluetooth`

 Optimize Database
```bash
 Run VACUUM weekly
sqlite3 /var/lib/iot-mvp/buffer.db "VACUUM;"

 Analyze for query optimization
sqlite3 /var/lib/iot-mvp/buffer.db "ANALYZE;"
```

 Cost Analysis

Per gateway:
- Hardware: £55 (Raspberry Pi 4, 4GB) + £15 (case, power, SD card) = £70
- Power: 6W × 24h × 365d × £0.25/kWh = £13.14/year
- Total: £70 + £13.14/year operating cost

 References

- [AWS IoT Core Developer Guide](https://docs.aws.amazon.com/iot/)
- [Bleak BLE Library](https://bleak.readthedocs.io/)
- [Paho MQTT Python](https://www.eclipse.org/paho/index.php?page=clients/python/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)

 License

Proprietary - IoT MVP Team, January 2026
