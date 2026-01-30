 Communications and Gateway Design

 Overview

The communications architecture connects battery-powered sensors to the cloud via a BLE-to-MQTT gateway. This design prioritizes energy efficiency (connection-less BLE advertisements), security (TLS 1.2 with X.509 certificates), and scalability (MQTT topic hierarchy for multi-building deployments).

---

 Communication Stack

```
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│   Sensor    │          │   Gateway   │          │    Cloud    │
│   Device    │          │  (RPi 4)    │          │ AWS IoT Core│
└──────┬──────┘          └──────┬──────┘          └──────┬──────┘
       │                        │                        │
       │  BLE 5.2               │  MQTT over TLS 1.2     │
       │  (GATT)                │  (Port 8883)           │
       │  2.4 GHz ISM           │  Wi-Fi / Ethernet      │
       │                        │                        │
       │◄──────────────────────►│◄──────────────────────►│
       │  Advertisements        │  Publish/Subscribe     │
       │  (every 10s)           │  (QoS 1)               │
       │                        │                        │
       │  Connection (optional) │  Device shadow sync    │
       │  (for OTA, bulk data)  │  (retained messages)   │
       │                        │                        │
```

---

 Layer 1: Device-to-Gateway (BLE 5.2)

 BLE Operating Mode: Connection-Less Advertisements

Rationale:
Traditional BLE connections require maintaining a link (5-10 mA continuous), which violates the 2-year battery constraint. Connection-less mode allows the device to broadcast sensor data in the advertisement payload, which the gateway scans passively.

Advertisement Structure (BLE 5.x extended advertising, 254-byte payload):

```
┌────────────────────────────────────────────────────────────┐
│ BLE Advertisement Packet (ADV_NONCONN_IND)                 │
├────────────────────────────────────────────────────────────┤
│ Header (6 bytes)                                           │
│  - Device MAC address: AA:BB:CC:DD:EE:FF                   │
│  - Flags: LE General Discoverable, BR/EDR Not Supported   │
├────────────────────────────────────────────────────────────┤
│ Manufacturer-Specific Data (31 bytes, AD Type 0xFF)        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Company ID: 0xFFFF (test/development)                │  │
│  │ Protocol version: 0x01                               │  │
│  │ Device ID: 0x12345678 (32-bit unique ID)            │  │
│  │ Timestamp: Unix epoch (32-bit)                       │  │
│  │ Battery voltage: 3600 mV (16-bit)                    │  │
│  │ CO₂: 850 ppm (16-bit)                                │  │
│  │ Temperature: 22.5°C (16-bit, 0.1°C resolution)       │  │
│  │ Humidity: 45% RH (8-bit)                             │  │
│  │ Occupancy: 0x01 (1 byte, 0=vacant, 1=occupied)      │  │
│  │ CRC16: 0xABCD (integrity check)                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

Advertising Interval:
- Normal mode: 10 seconds (balances latency and energy)
- Alert mode: 2 seconds (if CO₂ >1200 ppm or temperature >27°C)
- Pairing mode: 1 second (user presses pairing button on device)

Energy Consumption per Advertisement:
- TX power: 0 dBm (1 mW)
- Duration: ~1 ms (advertisement + scan response)
- Current: 10 mA
- Energy: 10 mA × 1 ms = 10 µJ per advertisement
- At 10-second intervals: 10 µJ × 6 per minute × 60 min × 24 hr = 8.64 mJ/day = 0.0024 mWh/day (negligible compared to sensor measurements)

 Optional: Connectable Mode (for OTA and Bulk Data)

When the gateway needs to:
- Pull buffered historical data (e.g., 4 hours of 10-minute samples = 24 readings)
- Initiate OTA firmware update
- Configure device parameters (sampling interval, alert thresholds)

The device switches to connectable advertisements for 60 seconds:

Connection Parameters:
- Connection interval: 100 ms (trade-off: 10 ms = low latency but high power; 1 s = low power but sluggish)
- Slave latency: 4 (device can skip 4 connection events if no data, reduces power)
- Supervision timeout: 4 seconds (detects link loss)
- MTU: 247 bytes (BLE 5 Data Length Extension, reduces overhead for bulk transfers)

GATT Service Profile:

| Service UUID | Characteristic | UUID | Properties | Description |
|--------------|----------------|------|------------|-------------|
| Environmental Sensing | Temperature | 0x2A6E | Read, Notify | °C × 100 (int16) |
| 0x181A (standard) | Humidity | 0x2A6F | Read, Notify | % RH (uint8) |
| | CO₂ Concentration | 0x2A9D (proposed) | Read, Notify | ppm (uint16) |
| Custom Occupancy | Occupancy Status | 0xABCD0001 | Read, Notify | 0=vacant, 1=occupied |
| 0xABCD0000 | Motion Event Count | 0xABCD0002 | Read | Total events since boot |
| Device Information | Model Number | 0x2A24 | Read | "AQM-100" |
| 0x180A (standard) | Serial Number | 0x2A25 | Read | Device unique ID |
| | Firmware Revision | 0x2A26 | Read | "v1.0.0" |
| | Battery Level | 0x2A19 | Read, Notify | 0-100% (uint8) |
| OTA Service | OTA Control Point | 0xEFAB0001 | Write, Indicate | Commands: start, cancel, confirm |
| 0xEFAB0000 | Firmware Data | 0xEFAB0002 | Write | 4 KB chunks (no response) |
| | OTA Status | 0xEFAB0003 | Read, Indicate | Progress, errors |

Energy Impact of Connection:
- Idle connection (no data): 5 mA × connection interval duty cycle ≈ 0.5 mA average
- Active data transfer (GATT notifications): 10 mA × 50% duty cycle = 5 mA average
- Strategy: Connect only when necessary, disconnect immediately after transfer (typical session <10 seconds)

 BLE Security

Pairing Mode:
- Method: LE Secure Connections with Passkey Entry (6-digit numeric PIN displayed on status LED Morse code)
- Bonding: Keys stored in device backup SRAM and gateway persistent storage
- Re-pairing: Required if gateway factory reset or device memory cleared

Encryption:
- Link-layer encryption: AES-128 CCM (automatically enabled after pairing)
- Application-layer: Not needed for link-local communication (gateway is trusted)

Whitelist:
- Device only accepts connections from bonded gateway MAC addresses
- Prevents rogue gateway snooping or command injection

---

 Layer 2: Gateway Architecture

 Hardware: Raspberry Pi 4 Model B

Specifications:
- Compute: Quad-core Cortex-A72 @ 1.5 GHz
- RAM: 2 GB (sufficient for Python runtime, MQTT client, ~20 device connections)
- Connectivity: 
  - Wi-Fi 802.11ac (2.4 + 5 GHz) or Gigabit Ethernet
  - Bluetooth 5.0 (onboard or USB dongle: CSR8510 chipset recommended)
- Storage: 16 GB microSD card (OS + logs)
- Power: 5V 3A USB-C (15W typical, 10W average)
- Cost: £55 (board + case + SD card + power supply)

Alternative: Custom Linux gateway (e.g., ESP32-based with BLE + Wi-Fi) for lower cost (~£20), but Raspberry Pi offers:
- Easier development (full Linux, Python ecosystem)
- Better reliability (mature OS, systemd for service management)
- Expansion potential (USB sensors, HDMI diagnostics)

 Software Stack

```
┌─────────────────────────────────────────────────────────┐
│                  Gateway Application                     │
│  ┌────────────────────┐       ┌────────────────────┐   │
│  │  BLE Scanner       │       │  MQTT Client       │   │
│  │  (Python bluepy)   │◄─────►│  (Paho MQTT)       │   │
│  │                    │       │                    │   │
│  │ - Scan for advs    │       │ - TLS 1.2 + X.509  │   │
│  │ - Parse payload    │       │ - QoS 1 publish    │   │
│  │ - Maintain device  │       │ - Reconnect logic  │   │
│  │   registry         │       │ - Buffering        │   │
│  └────────────────────┘       └────────────────────┘   │
│             │                           │               │
│             │  ┌────────────────────┐   │               │
│             └─►│  Local Buffer      │◄──┘               │
│                │  (SQLite)          │                   │
│                │                    │                   │
│                │ - 7 days retention │                   │
│                │ - Upload on reconnect                  │
│                └────────────────────┘                   │
├─────────────────────────────────────────────────────────┤
│                Operating System (Raspberry Pi OS)        │
│  - systemd service (auto-start, watchdog)               │
│  - NTP time sync (for accurate timestamps)              │
│  - Log rotation (rsyslog)                               │
└─────────────────────────────────────────────────────────┘
```

 Gateway Responsibilities

1. BLE Scanning:
   - Continuously scan for advertisements on primary advertising channel (37, 38, 39)
   - Parse manufacturer-specific data (validate CRC16)
   - Extract sensor readings and device ID
   - Deduplicate (ignore repeat advertisements within 10 s from same device)

2. Data Aggregation:
   - Collect readings from up to 20 devices
   - Add gateway metadata: timestamp (NTP-synced), RSSI (signal strength), gateway ID
   - Store in local SQLite database (circular buffer, 7 days retention)

3. MQTT Publishing:
   - Transform BLE data to JSON payload
   - Publish to AWS IoT Core via MQTT over TLS
   - QoS 1 (at-least-once delivery) for sensor data
   - QoS 0 (fire-and-forget) for frequent low-priority data (RSSI logs)

4. Device Management:
   - Track last-seen timestamp for each device (detect offline devices >30 min)
   - Handle OTA requests from cloud (download firmware, initiate BLE connection, stream to device)
   - Configuration sync (pull updated alert thresholds from cloud, push to devices)

5. Offline Resilience:
   - If internet connectivity lost: buffer data locally in SQLite (up to 10,080 readings = 7 days × 20 devices × 6 readings/hr)
   - On reconnect: replay buffered data with original timestamps
   - Backpressure handling: If buffer fills (unlikely), drop oldest data (log warning)

 Gateway Configuration File (`gateway_config.yaml`)

```yaml
gateway:
  id: "gw-floor2-east"
  location: "Building A, Floor 2, East Wing"
  
ble:
  scan_interval_ms: 1000         Scan window
  scan_window_ms: 1000           Always scanning (100% duty cycle)
  rssi_threshold: -85            Ignore devices weaker than -85 dBm
  
mqtt:
  broker: "a1b2c3d4e5f6g7.iot.eu-west-1.amazonaws.com"
  port: 8883
  client_id: "gw-floor2-east"
  ca_cert: "/etc/gateway/certs/AmazonRootCA1.pem"
  client_cert: "/etc/gateway/certs/gateway-cert.pem.crt"
  client_key: "/etc/gateway/certs/gateway-private.pem.key"
  qos_default: 1
  keep_alive_s: 60
  reconnect_delay_s: 5
  
topics:
  telemetry: "building/BuildingA/gateway/{gateway_id}/device/{device_id}/telemetry"
  alerts: "building/BuildingA/gateway/{gateway_id}/device/{device_id}/alerts"
  status: "building/BuildingA/gateway/{gateway_id}/status"
  
local_storage:
  database: "/var/lib/gateway/buffer.db"
  retention_days: 7
  max_size_mb: 100
  
logging:
  level: "INFO"                  DEBUG, INFO, WARN, ERROR
  file: "/var/log/gateway/app.log"
  max_size_mb: 10
  backup_count: 5
```

 Gateway Power Budget

- Idle: 5W (CPU, BLE, Wi-Fi idle)
- Active scanning + MQTT: 8W (CPU load, Wi-Fi TX)
- Average: 6W (75% idle, 25% active)

Annual energy cost (20 devices):
- Power: 6W × 24 hr/day × 365 days = 52.6 kWh/year
- Cost (UK average £0.30/kWh): 52.6 × £0.30 = £15.78/year
- Per device: £15.78 / 20 = £0.79/device/year (acceptable overhead)

---

 Layer 3: Gateway-to-Cloud (MQTT over TLS)

 Protocol: MQTT v5.0

Rationale:
- Lightweight: 2-byte fixed header, minimal overhead for small payloads
- Pub/Sub model: Decouples sensors (publishers) from dashboards (subscribers)
- QoS flexibility: 0 (at-most-once), 1 (at-least-once), 2 (exactly-once)
- Retained messages: Last-known state available to new subscribers
- Session persistence: Broker stores subscriptions and undelivered messages

Alternatives considered:
- HTTP REST: Higher overhead (HTTP headers ~200 bytes vs. MQTT 2 bytes), no pub/sub
- CoAP: Good for constrained devices, but less mature broker ecosystem
- WebSockets: Useful for browser clients, but MQTT-over-WS adds complexity

 MQTT Topic Hierarchy

Design Principles:
- Hierarchical: Enable filtering by building, floor, room, device
- Scalable: Support multi-building, multi-tenant deployments
- Semantic: Topic names self-documenting
- ACL-friendly: Prefix-based access control (e.g., `building/BuildingA/` grants access to all Building A topics)

Topic Structure:

```
building/{building_id}/gateway/{gateway_id}/device/{device_id}/{message_type}
```

Examples:

| Topic | Purpose | Publish Frequency | Retained |
|-------|---------|-------------------|----------|
| `building/BuildingA/gateway/gw-floor2-east/device/sensor001/telemetry` | Sensor data (CO₂, temp, humidity, occupancy) | 10 min | Yes (last value) |
| `building/BuildingA/gateway/gw-floor2-east/device/sensor001/alerts` | Threshold violations (CO₂ >1200 ppm) | On event | No |
| `building/BuildingA/gateway/gw-floor2-east/status` | Gateway health (uptime, connected devices, errors) | 5 min | Yes |
| `building/BuildingA/gateway/gw-floor2-east/device/sensor001/config` | Device configuration (sampling interval, thresholds) | On change | Yes |
| `building/BuildingA/gateway/gw-floor2-east/device/sensor001/ota` | OTA update commands | On demand | No |

Wildcard Subscriptions:
- Dashboard: `building/BuildingA/` (all data from Building A)
- Analytics: `building/+/gateway/+/device/+/telemetry` (all telemetry from all buildings)
- Facilities manager mobile app: `building/BuildingA/gateway/gw-floor2-east/device/+/alerts` (alerts only, Floor 2)

 MQTT Payload Schema (JSON)

Telemetry Message (`/telemetry`):

```json
{
  "version": "1.0",
  "timestamp": "2026-01-12T14:35:22Z",
  "device_id": "sensor001",
  "gateway_id": "gw-floor2-east",
  "building_id": "BuildingA",
  "location": {
    "floor": 2,
    "room": "Room 215",
    "zone": "East Wing"
  },
  "sensor_data": {
    "co2_ppm": 850,
    "temperature_c": 22.5,
    "humidity_percent": 45,
    "occupancy": true
  },
  "device_status": {
    "battery_mv": 3600,
    "battery_percent": 85,
    "rssi_dbm": -68,
    "firmware_version": "v1.0.0"
  }
}
```

Alert Message (`/alerts`):

```json
{
  "version": "1.0",
  "timestamp": "2026-01-12T14:42:18Z",
  "device_id": "sensor001",
  "gateway_id": "gw-floor2-east",
  "building_id": "BuildingA",
  "alert_type": "high_co2",
  "severity": "warning",
  "threshold": 1200,
  "current_value": 1350,
  "message": "CO₂ level exceeded threshold in Room 215"
}
```

Gateway Status (`/status`):

```json
{
  "version": "1.0",
  "timestamp": "2026-01-12T14:40:00Z",
  "gateway_id": "gw-floor2-east",
  "building_id": "BuildingA",
  "uptime_seconds": 86400,
  "connected_devices": 18,
  "devices_offline": ["sensor019", "sensor020"],
  "mqtt_status": "connected",
  "local_buffer_used_mb": 2.5,
  "errors_last_hour": 0
}
```

 MQTT QoS Strategy

| Message Type | QoS Level | Rationale |
|--------------|-----------|-----------|
| Telemetry (routine sensor data) | QoS 1 | At-least-once ensures no data loss, acceptable duplicates (time-series DB deduplicates by timestamp) |
| Alerts (threshold violations) | QoS 1 | Critical for facilities manager notification, must not be lost |
| Gateway status | QoS 0 | Frequent updates (5 min), missing one reading acceptable |
| Device config | QoS 2 | Exactly-once ensures config applied once (no duplicate settings) |
| OTA commands | QoS 2 | Critical: prevents duplicate OTA initiation (race conditions) |

Duplicate handling:
- Time-series database (InfluxDB, Timestream) uses `(device_id, timestamp)` as primary key
- Duplicate QoS 1 messages with same timestamp are automatically deduplicated on write

 TLS Configuration

TLS Version: 1.2 (1.3 preferred if broker supports)

Cipher Suites (ordered by preference):
1. `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` (PFS, strong encryption)
2. `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256` (PFS, lower CPU overhead)
3. `TLS_RSA_WITH_AES_256_GCM_SHA384` (fallback, no PFS)

Certificate Authentication (X.509 mutual TLS):

Gateway → Broker:
- CA certificate: AWS IoT Root CA (Amazon Root CA 1, publicly trusted)
- Client certificate: Gateway-specific cert signed by AWS IoT CA
  - Subject: `CN=gw-floor2-east, O=BuildingA, C=UK`
  - Validity: 1 year (auto-rotate 30 days before expiry)
- Client private key: RSA-2048 or ECDSA P-256 (stored in `/etc/gateway/certs/`, permissions 0600)

Broker → Gateway:
- Server certificate: AWS IoT Core endpoint cert (wildcard `.iot.eu-west-1.amazonaws.com`)
- Gateway verifies server cert against Root CA (prevents MITM)

Certificate Provisioning:
1. Gateway generates RSA-2048 key pair on first boot
2. Submits Certificate Signing Request (CSR) to AWS IoT via secure provisioning API (authenticated with temporary token)
3. AWS IoT CA signs CSR, returns certificate
4. Gateway stores cert and activates MQTT connection

Certificate Rotation:
- Automated via cron job: 30 days before expiry, generate new CSR, request new cert, update MQTT client, restart service
- Old cert remains valid during overlap (zero-downtime rotation)

---

 End-to-End Data Flow

 Normal Operation (Telemetry)

```
┌────────────┐  BLE ADV     ┌────────────┐  MQTT/TLS    ┌────────────┐
│  Sensor    │──────────────►│  Gateway   │──────────────►│ AWS IoT    │
│  Device    │  every 10s   │            │  QoS 1       │ Core       │
└────────────┘              └────────────┘              └────────────┘
     │                             │                             │
     │ 1. Wake from RTC alarm      │                             │
     │ 2. Measure CO₂ (5s)         │                             │
     │ 3. Read PIR status          │                             │
     │ 4. Update ADV payload       │                             │
     │ 5. Transmit BLE ADV (1ms)   │                             │
     │ 6. Sleep (Standby mode)     │                             │
     │                             │ 7. Scan BLE (continuous)    │
     │                             │ 8. Detect ADV, parse data   │
     │                             │ 9. Enrich with timestamp    │
     │                             │10. Publish to MQTT topic    │
     │                             │11. Store in local SQLite    │
     │                             │                             │
     │                             │                             │12. Receive MQTT message
     │                             │                             │13. Store in Timestream
     │                             │                             │14. Trigger Rules Engine
     │                             │                             │15. Forward to dashboard
```

 Alert Scenario (High CO₂)

```
┌────────────┐              ┌────────────┐              ┌────────────┐
│  Sensor    │              │  Gateway   │              │ AWS IoT    │
│  Device    │              │            │              │ Core       │
└────────────┘              └────────────┘              └────────────┘
     │                             │                             │
     │ 1. CO₂ reading 1350 ppm     │                             │
     │    (> 1200 ppm threshold)   │                             │
     │ 2. Set alert flag           │                             │
     │ 3. Switch to 2s ADV interval│                             │
     │ 4. Transmit ADV with alert  │                             │
     ├────────────────────────────►│                             │
     │                             │ 5. Detect alert in ADV      │
     │                             │ 6. Publish to /alerts topic │
     │                             │    (QoS 1, high priority)   │
     │                             ├────────────────────────────►│
     │                             │                             │ 7. Rules Engine evaluates
     │                             │                             │ 8. Trigger SNS notification
     │                             │                             │ 9. Send push to mobile app
     │                             │                             │10. Log to CloudWatch
     │                             │◄────────────────────────────┤
     │                             │11. ACK received             │
     │◄────────────────────────────┤                             │
     │12. (Next ADV cycle confirms │                             │
     │    alert still active or    │                             │
     │    returns to normal)       │                             │
```

 OTA Update Flow

```
┌────────────┐              ┌────────────┐              ┌────────────┐
│  Sensor    │              │  Gateway   │              │ AWS IoT    │
│  Device    │              │            │              │ + S3       │
└────────────┘              └────────────┘              └────────────┘
     │                             │                             │
     │                             │                             │ 1. New firmware available
     │                             │◄────────────────────────────┤ 2. Publish to /ota topic
     │                             │    {"version": "v1.1.0",    │
     │                             │     "url": "s3://...",      │
     │                             │     "size": 393216,         │
     │                             │     "sha256": "abc123..."}  │
     │                             │ 3. Download from S3         │
     │                             │ 4. Verify signature         │
     │◄────────────────────────────┤ 5. Connect to device (BLE)  │
     │ 6. Accept connection        │                             │
     │ 7. Authenticate (bonding)   │                             │
     │◄────────────────────────────┤ 8. Write OTA control char   │
     │ 9. Enter OTA mode           │    (start command)          │
     │◄────────────────────────────┤10. Stream firmware (4KB/chunk)
     │11. Write to Bank B Flash    │                             │
     │    ... (96 chunks) ...      │                             │
     │12. Verify SHA-256           │                             │
     │13. Send completion ACK      ├────────────────────────────►│
     │14. Reboot to bootloader     │                             │14. Log OTA success
     │15. Bootloader verifies sig  │                             │
     │16. Swap banks, boot v1.1.0  │                             │
     │17. Self-test pass           │                             │
     │18. Confirm OTA success      ├────────────────────────────►│
     │19. Resume normal operation  │                             │19. Update device shadow
```

---

 Network Resilience and Error Handling

 BLE Link Failures

Symptoms: Advertisement not received by gateway (interference, out of range, device malfunction)

Gateway Detection:
- Track last-seen timestamp for each device
- If no advertisement for >30 minutes: mark device as "offline"
- Publish alert to `/status` topic: `{"device_id": "sensor001", "status": "offline", "last_seen": "2026-01-12T14:10:00Z"}`

Recovery:
- Device continues advertising (unaware of gateway state)
- When gateway resumes scanning or device moves in range: automatically reconnects
- No manual intervention required (self-healing)

 MQTT Connection Loss

Symptoms: Internet outage, broker maintenance, network congestion

Gateway Behavior:
1. Detect: TCP socket timeout or MQTT PINGRESP missing
2. Buffer: Store incoming BLE data in local SQLite (up to 7 days, 10,080 readings)
3. Retry: Exponential backoff (5s, 10s, 20s, 40s, max 60s)
4. Reconnect: Establish TLS, authenticate with certificate, resume MQTT session
5. Replay: Publish buffered data with original timestamps (MQTT allows past timestamps)

Backpressure:
- If buffer exceeds 90% (9 GB of 10 GB): drop oldest data, log warning
- Unlikely scenario (7 days offline = extended outage, >99% uptime SLA violated)

 Duplicate Message Handling

Cause: MQTT QoS 1 (at-least-once) may deliver same message twice if ACK lost

Mitigation:
- Client-side deduplication: Gateway tracks last 100 published message IDs (rolling window), skips re-publish if duplicate detected
- Server-side deduplication: Time-series DB (Timestream, InfluxDB) uses `(device_id, timestamp)` as unique key, rejects duplicates on write

---

 Performance and Scalability

 Gateway Capacity

Per Raspberry Pi 4 gateway:
- BLE devices: 20-30 (limited by scan duty cycle and CPU for payload parsing)
- MQTT throughput: 100 msg/s (network-bound, not CPU-bound)
- Typical load: 20 devices × 6 msg/hr = 120 msg/hr = 0.033 msg/s (well under capacity)

Scaling Strategy:
- Horizontal: Deploy 1 gateway per floor or per 500 m² (typical office layout)
- Building with 4 floors: 4 gateways, each publishes to its own topic hierarchy
- Cloud broker (AWS IoT Core): Scales to millions of devices (no bottleneck)

 Latency Budget

| Segment | Latency | Notes |
|---------|---------|-------|
| Sensor measurement | 5 s | SCD40 NDIR reading time (fixed) |
| BLE advertisement transmission | 1 ms | Negligible |
| Gateway BLE scan detection | 0-10 s | Depends on scan window and advertising interval |
| Gateway processing | <100 ms | Parse, enrich, publish |
| MQTT publish (gateway → broker) | 50-200 ms | Network RTT (London to eu-west-1) |
| Broker routing | <10 ms | AWS IoT Core internal |
| Total (sensor reading → cloud) | 5-16 s | Meets <5 min alert requirement |

Worst-case alert latency: 5 s (sensor) + 10 s (next ADV) + 0.3 s (network) = 15.3 s (well under 5 min target, 20× margin)

---

 Security: Threat Model and Controls

 Threat 1: Eavesdropping on BLE Advertisements

Attack: Attacker with BLE sniffer captures advertisements, reads sensor data

Impact: Low (sensor data is not personal or commercially sensitive; aggregate occupancy and CO₂ levels)

Mitigation:
- Accepted risk: Connection-less BLE inherently broadcasts data (unavoidable for energy efficiency)
- Defense in depth: If personal data were present (not in this design), use BLE encryption or application-layer AES

 Threat 2: Rogue Gateway (Impersonation)

Attack: Attacker deploys fake gateway to collect sensor data or send malicious OTA updates

Impact: Medium (data exfiltration, device compromise)

Mitigation:
- BLE bonding: Devices only connect to whitelisted gateway MAC addresses (set during provisioning)
- OTA signature verification: Device rejects unsigned firmware (RSA-2048, public key in bootloader)
- Physical security: Gateway in locked IDF/comms room, not publicly accessible

 Threat 3: Man-in-the-Middle (MQTT)

Attack: Attacker intercepts MQTT traffic between gateway and broker

Impact: High (data tampering, command injection)

Mitigation:
- TLS 1.2 with mutual authentication: Gateway and broker verify each other's certificates
- Certificate pinning: Gateway trusts only AWS IoT Root CA (not all CAs in system trust store)
- Regular key rotation: Certificates expire yearly, keys rotated 30 days before expiry

 Threat 4: Denial of Service (DoS)

Attack: Flood gateway with fake BLE advertisements or broker with MQTT traffic

Impact: Medium (service disruption, battery drain on legitimate devices)

Mitigation:
- Rate limiting: Gateway ignores >10 advertisements/second from same device
- AWS IoT Core: Built-in DDoS protection, rate limiting (configurable per device)
- Watchdog: Gateway restarts if CPU >90% for >1 minute (failsafe)

---

 Testing and Validation

 BLE Range Test
- Setup: Place sensor at known distances (5, 10, 20, 30 m) from gateway, with/without office partitions
- Metrics: RSSI, packet loss rate, latency
- Acceptance: >95% packet delivery at 30 m through 2 partitions

 MQTT Reliability Test
- Setup: Disconnect internet for 10 minutes, reconnect, verify buffered data uploaded
- Metrics: Data loss (should be zero), upload time
- Acceptance: All 60 readings (10 min × 6/hr) successfully published within 2 minutes of reconnect

 Latency Test
- Setup: Trigger alert (manually set CO₂ sensor to 1500 ppm), measure time to mobile app notification
- Metrics: End-to-end latency
- Acceptance: <30 seconds, 95th percentile (far under 5 min SLA)

 Security Penetration Test
- Setup: Attempt BLE sniffing, MITM attack on MQTT, firmware upload without signature
- Metrics: Success/failure of each attack vector
- Acceptance: All attacks blocked, no data exfiltration or device compromise

---

 Summary

| Aspect | Design Choice | Key Benefit |
|--------|---------------|-------------|
| Device-Gateway | BLE 5.2 connection-less advertisements | Ultra-low energy (10 µJ/msg), 2-year battery life |
| Gateway-Cloud | MQTT over TLS 1.2, QoS 1 | Reliable delivery, low overhead, secure |
| Topic hierarchy | Multi-level (building/gateway/device) | Scalable, ACL-friendly, semantic |
| Payload format | JSON (UTF-8) | Human-readable, easy debugging, standard libraries |
| Gateway hardware | Raspberry Pi 4 | Cost-effective (£55), mature ecosystem, expandable |
| Offline resilience | 7-day SQLite buffer | Tolerates network outages, no data loss |
| Security | Mutual TLS, X.509 certs, signed firmware | MITM protection, tamper-proof OTA, access control |

---

 Related Documents

- [Cloud Architecture](cloud_architecture.md) – AWS IoT Core → Timestream → dashboard data pipeline.
- [Mobile App Design](mobile_app_design.md) – Mobile app wireframes and user journeys.
- [MQTT Schema (Appendix)](../../appendices/mqtt_schema.md) – MQTT access control lists and topic patterns.
- [Cloud Cost Analysis (Appendix)](../../appendices/cloud_cost_analysis.md) – Bandwidth and cloud cost estimates.
- [INDEX](../../INDEX.md) – Full document map and keyword search.
