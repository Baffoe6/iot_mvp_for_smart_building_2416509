 Cloud Architecture and Data Pipeline

 Overview

The cloud backend ingests sensor telemetry via MQTT, stores it in a time-series database, applies analytics and alerting rules, and serves data to web dashboards and mobile applications. The architecture is built on AWS IoT Core for device connectivity and AWS Timestream for time-series storage.

---

 Architecture Diagram (Textual Description)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (eu-west-1)                        │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Ingestion Layer                                              │  │
│  │                                                              │  │
│  │  ┌────────────────────┐         ┌────────────────────────┐  │  │
│  │  │  AWS IoT Core      │         │  AWS IoT Rules Engine  │  │  │
│  │  │  MQTT Broker       │────────►│  - Route telemetry     │  │  │
│  │  │  (TLS 1.2, X.509)  │         │  - Trigger alerts      │  │  │
│  │  │                    │         │  - Transform data      │  │  │
│  │  └────────────────────┘         └─────────┬──────────────┘  │  │
│  │                                            │                 │  │
│  └────────────────────────────────────────────┼─────────────────┘  │
│                                               │                    │
│  ┌────────────────────────────────────────────▼─────────────────┐  │
│  │ Storage Layer                                                │  │
│  │                                                              │  │
│  │  ┌────────────────────┐         ┌────────────────────────┐  │  │
│  │  │ Amazon Timestream  │         │  Amazon S3             │  │  │
│  │  │ Time-series DB     │         │  Cold storage          │  │  │
│  │  │ - 90 days hot      │         │  - >2 years archive    │  │  │
│  │  │ - 2 years warm     │         │  - Compliance, audit   │  │  │
│  │  └────────────────────┘         └────────────────────────┘  │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                               │                    │
│  ┌────────────────────────────────────────────▼─────────────────┐  │
│  │ Processing & Analytics Layer                                 │  │
│  │                                                              │  │
│  │  ┌────────────────────┐         ┌────────────────────────┐  │  │
│  │  │ AWS Lambda         │         │  Amazon SNS            │  │  │
│  │  │ - Aggregation      │────────►│  Notifications         │  │  │
│  │  │ - Anomaly detection│         │  - Email, SMS, push    │  │  │
│  │  │ - Energy calc      │         └────────────────────────┘  │  │
│  │  └────────────────────┘                                     │  │
│  │           │                                                  │  │
│  │           ▼                                                  │  │
│  │  ┌────────────────────┐                                     │  │
│  │  │ AWS CloudWatch     │                                     │  │
│  │  │ Logs & Metrics     │                                     │  │
│  │  └────────────────────┘                                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                               │                    │
│  ┌────────────────────────────────────────────▼─────────────────┐  │
│  │ Presentation Layer                                           │  │
│  │                                                              │  │
│  │  ┌────────────────────┐         ┌────────────────────────┐  │  │
│  │  │ API Gateway        │         │  Amplify (web hosting) │  │  │
│  │  │ REST API           │◄────────│  React dashboard       │  │  │
│  │  │ (authenticated)    │         │  (facilities manager)  │  │  │
│  │  └────────────────────┘         └────────────────────────┘  │  │
│  │           │                                                  │  │
│  │           └─────────────────────┐                            │  │
│  │                                 ▼                            │  │
│  │                        ┌────────────────────┐                │  │
│  │                        │ Mobile App (iOS/   │                │  │
│  │                        │ Android, React     │                │  │
│  │                        │ Native)            │                │  │
│  │                        └────────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Security & Identity                                          │  │
│  │                                                              │  │
│  │  ┌────────────────────┐         ┌────────────────────────┐  │  │
│  │  │ AWS IAM            │         │  AWS Cognito           │  │  │
│  │  │ Service roles      │         │  User authentication   │  │  │
│  │  │ Device policies    │         │  (facilities manager)  │  │  │
│  │  └────────────────────┘         └────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

---

 Component 1: AWS IoT Core (Ingestion)

 Role
- MQTT broker: Receives telemetry from gateways
- Device registry: Tracks all registered gateways and sensors (via gateway shadows)
- Authentication: X.509 certificate validation
- Authorization: IoT policies enforce publish/subscribe permissions
- Rules Engine: Routes messages to downstream services (Timestream, Lambda, SNS)

 Configuration

IoT Thing (Gateway):
```json
{
  "thingName": "gw-floor2-east",
  "thingTypeName": "Gateway",
  "attributes": {
    "building": "BuildingA",
    "floor": "2",
    "zone": "East Wing",
    "firmware_version": "v1.0.0"
  },
  "certificateArn": "arn:aws:iot:eu-west-1:123456789012:cert/abc123..."
}
```

IoT Policy (attached to gateway certificate):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iot:Connect"],
      "Resource": ["arn:aws:iot:eu-west-1:123456789012:client/gw-floor2-east"]
    },
    {
      "Effect": "Allow",
      "Action": ["iot:Publish"],
      "Resource": [
        "arn:aws:iot:eu-west-1:123456789012:topic/building/BuildingA/gateway/gw-floor2-east/"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["iot:Subscribe", "iot:Receive"],
      "Resource": [
        "arn:aws:iot:eu-west-1:123456789012:topicfilter/building/BuildingA/gateway/gw-floor2-east/config",
        "arn:aws:iot:eu-west-1:123456789012:topic/building/BuildingA/gateway/gw-floor2-east/config"
      ]
    }
  ]
}
```

Explanation:
- Gateway can connect only with its own client ID (prevents impersonation)
- Gateway can publish to any topic under its hierarchy (`building/BuildingA/gateway/gw-floor2-east/`)
- Gateway can subscribe only to its own configuration topic (receives commands from cloud)
- Principle of least privilege: Gateway cannot publish to other gateways' topics or subscribe to telemetry (no lateral movement)

 IoT Rules Engine

Rule 1: Route Telemetry to Timestream

```sql
SELECT 
  timestamp,
  device_id,
  gateway_id,
  building_id,
  sensor_data.co2_ppm AS co2,
  sensor_data.temperature_c AS temperature,
  sensor_data.humidity_percent AS humidity,
  sensor_data.occupancy AS occupancy,
  device_status.battery_mv AS battery_voltage,
  device_status.rssi_dbm AS rssi
FROM 'building/+/gateway/+/device/+/telemetry'
```

Action: Write to Amazon Timestream database `IoTSensorData`, table `Telemetry`

Rule 2: Trigger Alerts

```sql
SELECT 
  
FROM 'building/+/gateway/+/device/+/alerts'
WHERE alert_type IN ('high_co2', 'high_temperature', 'low_battery')
```

Actions:
1. Lambda function `AlertProcessor`: Logs alert, checks if duplicate (last 10 min), sends SNS notification if new
2. SNS topic `BuildingAlerts`: Publishes to facilities manager email/SMS/mobile push

Rule 3: Gateway Status Monitoring

```sql
SELECT 
  gateway_id,
  uptime_seconds,
  connected_devices,
  errors_last_hour
FROM 'building/+/gateway/+/status'
```

Action: CloudWatch Logs + CloudWatch Metric (custom metric for connected devices, errors)

 Pricing (AWS IoT Core)

Connectivity:
- 20 devices × 1 gateway = 1 connection
- £0.08 per million connection-minutes
- 1 gateway × 30 days × 24 hr × 60 min = 43,200 min/mo
- Cost: 0.0432 × £0.08 = £0.003/mo (negligible)

Messaging (inbound):
- 20 devices × 108 msg/day × 30 days = 64,800 msg/mo (blended 10/20 min sampling)
- £0.80 per million messages
- Cost: 0.0648 × £0.80 = £0.052/mo

Rules Engine (actions):
- 64,800 telemetry → Timestream: 64,800 actions

Total AWS IoT Core: £0.055/mo → £0.66/year

Complete cost breakdown (all services for 20 devices): See detailed pricing table at end of section. Total: £22/year (£1.10/device/year). Comprehensive scaling analysis (100/500/5,000 devices) in Appendix D.
- 10 alerts/mo → Lambda + SNS: 10 × 2 = 20 actions
- 8,640 status → CloudWatch: 8,640 actions
- Total: 95,060 actions/mo
- £0.12 per million actions
- Cost: 0.095 × £0.12 = £0.01/mo

Total AWS IoT Core: £0.08/mo = £0.96/year (for 20 devices)

---

 Component 2: Amazon Timestream (Storage)

 Role
- Time-series database: Optimized for IoT sensor data (timestamp + metrics)
- Automatic tiering: Hot storage (90 days, fast queries), warm storage (2 years, lower cost)
- SQL-like queries: Supports aggregations, windowing, interpolation
- Compression: 10:1 typical for sensor data (vs. relational DB)

 Data Model

Table: `Telemetry`

| Column | Type | Description |
|--------|------|-------------|
| `time` | TIMESTAMP | Measurement timestamp (device-generated, NTP-synced via gateway) |
| `device_id` | VARCHAR (dimension) | Unique sensor identifier (e.g., "sensor001") |
| `gateway_id` | VARCHAR (dimension) | Gateway that ingested data |
| `building_id` | VARCHAR (dimension) | Building identifier |
| `floor` | INT (dimension) | Floor number |
| `room` | VARCHAR (dimension) | Room name |
| `co2` | DOUBLE (measure) | CO₂ concentration (ppm) |
| `temperature` | DOUBLE (measure) | Temperature (°C) |
| `humidity` | DOUBLE (measure) | Relative humidity (%) |
| `occupancy` | BOOLEAN (measure) | Presence detected |
| `battery_voltage` | INT (measure) | Battery voltage (mV) |
| `rssi` | INT (measure) | BLE signal strength (dBm) |

Dimensions: Used for filtering (WHERE clauses)
Measures: Numeric values for aggregation (AVG, SUM, etc.)

 Example Queries

Query 1: Average CO₂ by room (last 24 hours)

```sql
SELECT 
  room,
  AVG(co2) AS avg_co2,
  MAX(co2) AS max_co2
FROM "IoTSensorData"."Telemetry"
WHERE time BETWEEN ago(24h) AND now()
  AND building_id = 'BuildingA'
GROUP BY room
ORDER BY avg_co2 DESC
```

Query 2: Occupancy heatmap (hourly, last 7 days)

```sql
SELECT 
  BIN(time, 1h) AS hour,
  room,
  SUM(CASE WHEN occupancy = true THEN 1 ELSE 0 END) AS occupied_samples,
  COUNT() AS total_samples
FROM "IoTSensorData"."Telemetry"
WHERE time BETWEEN ago(7d) AND now()
  AND building_id = 'BuildingA'
GROUP BY BIN(time, 1h), room
ORDER BY hour, room
```

Query 3: Energy savings estimate (HVAC runtime reduction)

```sql
SELECT 
  room,
  SUM(CASE WHEN occupancy = false THEN 10 ELSE 0 END) AS minutes_vacant,
  SUM(CASE WHEN occupancy = false THEN 10 ELSE 0 END)  0.5 AS kwh_saved
  -- Assumes 0.5 kW HVAC power, 10-min intervals
FROM "IoTSensorData"."Telemetry"
WHERE time BETWEEN ago(30d) AND now()
  AND building_id = 'BuildingA'
GROUP BY room
ORDER BY kwh_saved DESC
```

 Pricing (Timestream)

Write requests:
- 20 devices × 6 msg/hr × 24 hr × 30 days = 86,400 writes/mo
- £0.45 per million writes
- Cost: 0.0864 × £0.45 = £0.04/mo

Storage (hot, 90 days):
- Payload size: ~200 bytes per reading (JSON overhead removed, compressed 10:1)
- 20 bytes per row in Timestream
- 86,400 writes/mo × 3 mo × 20 bytes = 5.18 MB
- £0.027 per GB-mo
- Cost: 0.00518 × £0.027 = £0.0001/mo (negligible)

Storage (warm, 2 years):
- 86,400 × 24 mo × 20 bytes = 41.5 MB
- £0.0027 per GB-mo
- Cost: 0.0415 × £0.0027 = £0.0001/mo (negligible)

Query scanned data:
- Assume 100 queries/day (dashboards, mobile app refreshes)
- Each query scans ~10 MB (1 day of data for 20 devices)
- 100 × 30 × 10 MB = 30 GB scanned/mo
- £0.0027 per GB scanned
- Cost: 30 × £0.0027 = £0.08/mo

Total Timestream: £0.12/mo = £1.44/year

---

 Component 3: AWS Lambda (Processing & Analytics)

 Lambda Function 1: `AlertProcessor`

Trigger: IoT Rules Engine (alerts topic)

Purpose: Deduplicate alerts, enrich with historical context, send notifications

Logic:
1. Receive alert message (CO₂ >1200 ppm, temperature >27°C, battery <20%)
2. Query Timestream: Has same alert occurred in last 10 minutes for this device?
3. If yes: Log but do not notify (avoid notification storm)
4. If no: 
   - Publish to SNS topic `BuildingAlerts`
   - Log to CloudWatch
   - Store alert in DynamoDB `AlertHistory` (for dashboard display)

Runtime: Python 3.12, 128 MB RAM, timeout 30 s

Estimated invocations: 10 alerts/mo (not per device; infrequent high-CO₂ events)

 Lambda Function 2: `DataAggregator`

Trigger: CloudWatch Events (cron: every hour)

Purpose: Compute hourly aggregates for faster dashboard queries

Logic:
1. Query Timestream: Last hour's data for all devices
2. Compute per-room aggregates:
   - Average CO₂, temperature, humidity
   - Occupancy percentage (% of time occupied)
   - Max CO₂, min temperature
3. Write aggregates back to Timestream table `HourlyAggregates`

Runtime: Python 3.12, 512 MB RAM, timeout 5 min

Estimated invocations: 24/day × 30 days = 720/mo

 Lambda Function 3: `BatteryMonitor`

Trigger: CloudWatch Events (cron: daily at 02:00 UTC)

Purpose: Identify devices with low battery, send maintenance alert

Logic:
1. Query Timestream: Latest battery voltage for all devices
2. Filter: voltage <2.8 V (20% remaining, ~2 months before replacement)
3. Send SNS notification to facilities manager: "Device sensor017 battery low (2.7V), replace within 4 weeks"

Runtime: Python 3.12, 128 MB RAM, timeout 1 min

Estimated invocations: 30/mo (daily)

 Pricing (Lambda)

Requests:
- AlertProcessor: 10/mo
- DataAggregator: 720/mo
- BatteryMonitor: 30/mo
- Total: 760/mo
- £0.15 per million requests
- Cost: 0.00076 × £0.15 = £0.0001/mo

Compute (GB-seconds):
- AlertProcessor: 10 × 0.128 GB × 5 s = 6.4 GB-s
- DataAggregator: 720 × 0.512 GB × 30 s = 11,059 GB-s
- BatteryMonitor: 30 × 0.128 GB × 10 s = 38.4 GB-s
- Total: 11,104 GB-s/mo
- £0.0000147 per GB-s (after 400,000 free tier GB-s)
- Cost: (11,104 - 400,000) × £0.0000147 ≈ £0 (within free tier)

Total Lambda: £0/mo (free tier covers MVP usage)

---

 Component 4: Amazon SNS (Notifications)

 SNS Topic: `BuildingAlerts`

Subscribers:
1. Email: facilities.manager@buildinga.com
2. SMS: +44 7700 900123 (on-call engineer)
3. Mobile app push: AWS SNS → Firebase Cloud Messaging (FCM) → mobile app

Message Format (JSON):

```json
{
  "alert_type": "high_co2",
  "severity": "warning",
  "device_id": "sensor001",
  "room": "Room 215",
  "floor": 2,
  "building": "BuildingA",
  "current_value": 1350,
  "threshold": 1200,
  "timestamp": "2026-01-12T14:42:18Z",
  "message": "CO₂ level exceeded 1200 ppm in Room 215 (Floor 2). Current: 1350 ppm. Check ventilation."
}
```

Email template (human-readable):

```
 Alert: High CO₂ in Room 215

Building: Building A, Floor 2
Device: sensor001
Time: 2026-01-12 14:42:18 UTC

CO₂ level: 1350 ppm (threshold: 1200 ppm)

Action required: Increase ventilation or reduce occupancy.

View dashboard: https://dashboard.buildinga.com/alerts/12345
```

 Pricing (SNS)

Email notifications:
- 10 alerts/mo
- £1.60 per 100,000 emails
- Cost: 0.00001 × £1.60 = £0.00002/mo

SMS notifications (UK):
- 5 critical alerts/mo (subset of email alerts)
- £0.06 per SMS
- Cost: 5 × £0.06 = £0.30/mo

Push notifications (mobile app):
- 10 alerts/mo
- £0.40 per million notifications
- Cost: 0.00001 × £0.40 = £0.000004/mo

Total SNS: £0.30/mo = £3.60/year (dominated by SMS cost)

---

 Component 5: API Gateway (Presentation Layer)

 Role
- REST API: Exposes data to web dashboard and mobile app
- Authentication: AWS Cognito integration (JWT tokens)
- Rate limiting: 1000 requests/min per user (prevent abuse)
- Caching: 300 s TTL for frequently accessed queries (reduce Timestream queries)

 Endpoints

GET /buildings/{building_id}/rooms
- Returns list of all rooms with latest sensor readings
- Response:
  ```json
  {
    "building_id": "BuildingA",
    "rooms": [
      {
        "room_id": "Room215",
        "floor": 2,
        "device_id": "sensor001",
        "last_update": "2026-01-12T15:00:00Z",
        "co2_ppm": 850,
        "temperature_c": 22.5,
        "humidity_percent": 45,
        "occupancy": true,
        "battery_percent": 85
      },
      ...
    ]
  }
  ```

GET /buildings/{building_id}/devices/{device_id}/history
- Query parameters: `start_time`, `end_time`, `interval` (1m, 10m, 1h, 1d)
- Returns time-series data for charts
- Response:
  ```json
  {
    "device_id": "sensor001",
    "interval": "10m",
    "data": [
      {"timestamp": "2026-01-12T14:00:00Z", "co2": 820, "temperature": 22.3, "occupancy": true},
      {"timestamp": "2026-01-12T14:10:00Z", "co2": 850, "temperature": 22.5, "occupancy": true},
      ...
    ]
  }
  ```

GET /buildings/{building_id}/alerts
- Returns recent alerts (last 7 days)
- Response:
  ```json
  {
    "alerts": [
      {
        "alert_id": "12345",
        "timestamp": "2026-01-12T14:42:18Z",
        "alert_type": "high_co2",
        "room": "Room 215",
        "severity": "warning",
        "resolved": false
      },
      ...
    ]
  }
  ```

POST /buildings/{building_id}/devices/{device_id}/config
- Update device configuration (sampling interval, thresholds)
- Body:
  ```json
  {
    "sampling_interval_sec": 600,
    "co2_threshold_ppm": 1200,
    "temperature_threshold_c": 27
  }
  ```
- Action: Publishes config to MQTT topic (IoT Core routes to gateway, gateway updates device)

 Authentication: AWS Cognito

User Pool: `BuildingManagers`
- Users: Facilities managers (email-verified accounts)
- MFA: Enabled (TOTP or SMS)
- Password policy: ≥12 chars, uppercase, lowercase, numbers, symbols

Authorization:
- JWT token issued on login (expires 1 hour)
- API Gateway validates JWT signature (Cognito public key)
- Lambda authorizer checks user's `building_id` claim (ensures manager only accesses their building)

 Pricing (API Gateway)

Requests:
- Web dashboard: 100 requests/day (10 users, 10 refreshes/day)
- Mobile app: 200 requests/day (10 users, 20 API calls/day)
- Total: 300 × 30 = 9,000 requests/mo
- £2.80 per million requests
- Cost: 0.009 × £2.80 = £0.03/mo

Data transfer out (to dashboard):
- 9,000 requests × 5 KB average response = 45 MB/mo
- First 1 GB free, then £0.07/GB
- Cost: £0/mo (within free tier)

Total API Gateway: £0.03/mo = £0.36/year

---

 Data Lifecycle and Retention

 Hot Path (Real-Time)

```
Device → Gateway → IoT Core → Timestream (hot storage, 90 days) → Dashboard
         (10s latency)         (sub-second write)                 (5s refresh)
```

- SLA: 95th percentile end-to-end latency <30 seconds
- Availability: 99.9% (AWS IoT Core + Timestream SLAs)

 Warm Path (Historical)

```
Timestream (hot) → Timestream (warm storage, 2 years)
                   (automatic tiering after 90 days)
```

- Queries: Slower (10-30 s for 1-month query), acceptable for trend analysis
- Cost: 10× cheaper than hot storage

 Cold Path (Archive)

```
Timestream (warm) → S3 Glacier Deep Archive (>2 years)
                    (manual export via scheduled Lambda)
```

- Purpose: Compliance, audit trails, long-term research
- Retrieval: 12-48 hours (rarely accessed)
- Cost: £0.0008 per GB-mo (cheapest)

 Retention Policy Summary

| Data Type | Retention | Storage | Rationale |
|-----------|-----------|---------|-----------|
| Telemetry (raw) | 90 days | Timestream hot | Fast queries for dashboards, alerts |
| Telemetry (aggregated hourly) | 2 years | Timestream warm | Trend analysis, energy reporting |
| Telemetry (raw, old) | >2 years | S3 Glacier | Compliance, audit (GDPR allows longer for non-personal data) |
| Alerts | 2 years | DynamoDB | Incident review, compliance |
| Logs (gateway, Lambda) | 30 days | CloudWatch Logs | Debugging, troubleshooting |

---

 Scalability and Performance

 Current Load (20 devices, 1 building)
- MQTT messages: 86,400/mo
- Timestream writes: 86,400/mo
- API requests: 9,000/mo
- Lambda invocations: 760/mo

 Projected Load (200 devices, 10 buildings)
- MQTT messages: 864,000/mo
- Timestream writes: 864,000/mo
- API requests: 90,000/mo (10× buildings, proportional)
- Lambda invocations: 7,600/mo

 Bottleneck Analysis

| Component | Current Utilization | Capacity | Headroom |
|-----------|---------------------|----------|----------|
| AWS IoT Core | 86,400 msg/mo | ~10M msg/mo (soft limit) | 116× |
| Timestream writes | 86,400/mo | ~1M writes/s | 1000× |
| API Gateway | 9,000 req/mo | ~10M req/mo (default limit) | 1111× |
| Lambda (concurrent) | <1 execution | 1,000 concurrent (default) | 1000× |

Conclusion: Architecture scales to 1,000× current load without redesign. Beyond that:
- Increase IoT Core quotas (AWS support request)
- Shard Timestream tables by building (parallel writes)
- Add API Gateway caching (CDN for static responses)

---

 Disaster Recovery and Backup

 RTO (Recovery Time Objective): 4 hours
- Time to restore service after AWS region failure

 RPO (Recovery Point Objective): 10 minutes
- Maximum acceptable data loss (one telemetry interval)

 Backup Strategy

Timestream data:
- Automatic replication within region (3 AZs)
- Manual snapshot export to S3 (weekly via Lambda)
- Cross-region replication to `us-east-1` (optional, for critical deployments)

IoT device certificates:
- Stored in AWS Secrets Manager (automatic backup, encrypted)
- Certificate revocation list (CRL) backed up to S3

Lambda functions & configuration:
- Infrastructure as Code (Terraform/CDK) in Git repository
- Deployment pipeline (CI/CD) can recreate all resources in <1 hour

Gateway configuration:
- Stored in S3 bucket (versioned, lifecycle policy: 90 days)
- Gateway pulls config on boot (self-healing)

 Failover Procedure (if `eu-west-1` down)

1. Detect: CloudWatch alarm triggers SNS → on-call engineer
2. Assess: Check AWS Health Dashboard, confirm regional outage
3. Redirect: Update DNS (Route 53) to point to `us-east-1` backup region
4. Restore: Gateways reconnect to new IoT Core endpoint (automatic retry with exponential backoff)
5. Verify: Dashboard and mobile app functional, data flowing
6. Communicate: Notify stakeholders (expected <10 min data loss)

---

 Cost Summary (AWS Cloud Backend, 20 devices)

| Service | Monthly Cost | Annual Cost | Notes |
|---------|-------------|-------------|-------|
| AWS IoT Core | £0.08 | £0.96 | Connectivity + messaging + rules |
| Amazon Timestream | £0.12 | £1.44 | Writes + storage + queries |
| AWS Lambda | £0.00 | £0.00 | Within free tier |
| Amazon SNS | £0.30 | £3.60 | Dominated by SMS alerts |
| API Gateway | £0.03 | £0.36 | REST API requests |
| CloudWatch | £0.05 | £0.60 | Logs + metrics (estimated) |
| S3 (backups) | £0.01 | £0.12 | Minimal usage |
| TOTAL | £0.59 | £7.08 | <£500/year target |

Per-device cost: £7.08 / 20 = £0.35/device/year (excellent cost efficiency)

Note: Excludes one-time costs (Cognito setup, Lambda development) and assumes steady state (no unexpected traffic spikes).

---

 Related Documents

- [Mobile App Design](mobile_app_design.md) – Mobile app wireframes and user experience.
- [Security, Privacy & Sustainability](../implementation/security_privacy_sustainability.md) – Threat model and GDPR compliance.
- [Cloud Cost Analysis (Appendix)](../../appendices/cloud_cost_analysis.md) – Cost model at 20/100/500/5,000 devices.
- [MQTT Schema (Appendix)](../../appendices/mqtt_schema.md) – Topic hierarchy and ACL policies.
- [INDEX](../../INDEX.md) – Full document map and keyword search.
