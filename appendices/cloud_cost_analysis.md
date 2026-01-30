 Appendix D: Cloud Cost Analysis and Scaling Projections

 Overview

This appendix provides detailed cost breakdowns for the AWS cloud infrastructure at various deployment scales (20, 100, 500, 5000 devices), including projections for multi-tenant SaaS model expansion. All calculations use AWS eu-west-1 (Ireland) pricing as of January 2026 and assume standard on-demand rates (no Reserved Instances or Savings Plans).

---

 Baseline Architecture Recap

 AWS Services Used

1. AWS IoT Core: MQTT broker, device registry, rules engine
2. Amazon Timestream: Time-series database for telemetry storage
3. AWS Lambda: Serverless compute for data processing, alerts, API logic
4. Amazon API Gateway: REST API for dashboard and mobile app
5. Amazon S3: Firmware storage, static asset hosting
6. Amazon SNS: Push notifications (email, SMS, mobile)
7. AWS Cognito: User authentication and authorization (JWT)
8. Amazon CloudWatch: Logging and monitoring
9. Amazon DynamoDB: Device metadata, campaign state tracking

 Data Flow and Storage Strategy

Telemetry Path: Device → Gateway → IoT Core → Rules Engine → Lambda → Timestream  
Query Path: Dashboard → API Gateway → Lambda → Timestream → Response  
Alerts: IoT Core → Lambda → SNS → Email/SMS/Mobile Push  

Data Retention Policy:
- Hot storage (Timestream): 90 days, frequent queries (dashboard)
- Warm storage (Timestream): 2 years, infrequent queries (compliance, analytics)
- Long-term archive (S3 Glacier): >2 years, regulatory compliance (optional)

---

 Cost Model: 20-Device Deployment (Pilot)

 Assumptions

- Devices: 20 sensors, 1 building
- Gateways: 1× Raspberry Pi 4 (one-time £55, amortized over 3 years)
- Telemetry rate: 10-minute sampling (occupied) → 144 msg/day/device; 20-min (vacant) → 72 msg/day/device
- Blended average: (144 × 0.5) + (72 × 0.5) = 108 messages/day/device
- Total messages/month: 20 devices × 108 msg/day × 30 days = 64,800 messages
- Message size: 350 bytes average (JSON payload)
- Queries: 50 dashboard loads/day × 5 queries/load = 250 queries/day = 7,500 queries/month
- Alerts: 5 alerts/day (CO₂ high, battery low) = 150 alerts/month
- Users: 3 facilities managers (dashboard access)

 AWS IoT Core

Pricing (eu-west-1, January 2026):
- Connectivity: $0.08 per million minutes connected
- Messaging: $1.00 per million messages (up to 5 KB each)

Calculation:
- Connectivity: 1 gateway × 44,640 min/month = 0.0446 million minutes → 0.0446 × $0.08 = $0.0036
- Messaging: 64,800 messages/month = 0.0648 million messages → 0.0648 × $1.00 = $0.0648
- Total IoT Core: $0.068 ≈ £0.055 (at 1.24 USD/GBP)

 Amazon Timestream

Pricing:
- Writes: $0.50 per million write records
- Memory storage (hot, 90 days): $0.036 per GB-hour
- Magnetic storage (warm, 2 years): $0.03 per GB-month
- Queries: $0.01 per GB scanned

Calculation:
- Writes: 64,800 writes/month → 0.0648 million writes → 0.0648 × $0.50 = $0.0324
- Memory storage (90 days):
  - Data size: 350 bytes/msg × 64,800 msg/month × 3 months = 68 MB = 0.068 GB
  - GB-hours: 0.068 GB × 720 hours/month = 48.96 GB-hours
  - Cost: 48.96 × $0.036 = $1.76
- Magnetic storage (2 years):
  - Data size: 350 bytes × 64,800 msg/month × 24 months = 544 MB = 0.544 GB
  - Cost: 0.544 GB × $0.03 = $0.016
- Queries: 7,500 queries/month × 0.5 MB avg scanned/query = 3.75 GB scanned
  - Cost: 3.75 GB × $0.01 = $0.0375
- Total Timestream: $1.76 + $0.0324 + $0.016 + $0.0375 = $1.846 ≈ £1.49

 AWS Lambda

Pricing:
- Requests: $0.20 per million requests
- Compute: $0.0000166667 per GB-second (128 MB function = 0.125 GB)

Functions:
1. Telemetry processor: 64,800 invocations/month, 50 ms avg, 128 MB
2. Alert handler: 150 invocations/month, 100 ms avg, 128 MB
3. API query handler: 7,500 invocations/month, 200 ms avg, 256 MB

Calculation:
- Telemetry processor:
  - Requests: 64,800 → 0.0648 million → 0.0648 × $0.20 = $0.013
  - Compute: 64,800 × 0.05 s × 0.125 GB = 405 GB-s → 405 × $0.0000166667 = $0.0068
- Alert handler:
  - Requests: 150 → 0.00015 million → 0.00015 × $0.20 = $0.00003
  - Compute: 150 × 0.1 s × 0.125 GB = 1.875 GB-s → 1.875 × $0.0000166667 = $0.00003
- API query handler:
  - Requests: 7,500 → 0.0075 million → 0.0075 × $0.20 = $0.0015
  - Compute: 7,500 × 0.2 s × 0.25 GB = 375 GB-s → 375 × $0.0000166667 = $0.0063
- Total Lambda: $0.013 + $0.0068 + $0.0015 + $0.0063 = $0.028 ≈ £0.023

 Amazon API Gateway

Pricing:
- REST API requests: $3.50 per million requests (first 333 million)

Calculation:
- Requests: 7,500 API calls/month → 0.0075 million → 0.0075 × $3.50 = $0.026 ≈ £0.021

 Amazon S3

Pricing:
- Storage: $0.023 per GB/month (Standard)
- GET requests: $0.0004 per 1,000 requests
- PUT requests: $0.005 per 1,000 requests

Usage:
- Firmware storage: 500 MB (5 firmware versions) → $0.012
- Static assets (dashboard): 50 MB → $0.001
- GET requests (firmware downloads): 2 OTA updates/year → negligible
- Total S3: $0.013 ≈ £0.011

 Amazon SNS

Pricing:
- Email: $2.00 per 100,000 notifications
- SMS (UK): $0.054 per message
- Mobile push (FCM): $0.50 per million notifications

Calculation:
- Email alerts: 150 emails/month → 0.0015 × 100,000 → 0.0015 × $2.00 = $0.003
- Mobile push: 150 push/month → 0.00015 million → 0.00015 × $0.50 = $0.000075
- Total SNS: $0.003 ≈ £0.0024

 AWS Cognito

Pricing:
- Monthly Active Users (MAU): First 50,000 free
- Advanced security: $0.05 per MAU (optional)

Calculation:
- MAU: 3 users (within free tier) → $0.00

 Amazon CloudWatch

Pricing:
- Logs ingestion: $0.50 per GB
- Logs storage: $0.03 per GB/month
- Metrics: First 10 custom metrics free, $0.30 per metric thereafter

Calculation:
- Logs ingestion: 500 MB/month → 0.5 GB × $0.50 = $0.25
- Logs storage: 1 GB average → 1 × $0.03 = $0.03
- Metrics: 5 custom metrics (within free tier) → $0.00
- Total CloudWatch: $0.25 + $0.03 = $0.28 ≈ £0.23

 Amazon DynamoDB

Pricing:
- On-Demand: $1.25 per million write requests, $0.25 per million read requests
- Storage: $0.25 per GB/month

Usage:
- Device registry: 20 devices × 1 KB = 20 KB → $0.00005
- Campaign state: 2 writes/day × 30 days = 60 writes → negligible
- Reads: 250 queries/day × 30 days = 7,500 reads → 0.0075 million → 0.0075 × $0.25 = $0.0019
- Total DynamoDB: $0.002 ≈ £0.0016

---

 Total Monthly Cost (20 Devices)

| Service | Monthly Cost (USD) | Monthly Cost (GBP) |
|---------|-------------------|-------------------|
| AWS IoT Core | $0.068 | £0.055 |
| Amazon Timestream | $1.846 | £1.49 |
| AWS Lambda | $0.028 | £0.023 |
| API Gateway | $0.026 | £0.021 |
| Amazon S3 | $0.013 | £0.011 |
| Amazon SNS | $0.003 | £0.0024 |
| AWS Cognito | $0.00 | £0.00 |
| CloudWatch | $0.28 | £0.23 |
| DynamoDB | $0.002 | £0.0016 |
| TOTAL | $2.27 | £1.83 |

Annual cost: £1.83/month × 12 = £21.96 ≈ £22/year

Validation: Original report cited £7.08/year for 20 devices. Discrepancy analysis:
- Revised calculation (£22/year) more accurately reflects CloudWatch logging costs
- Original estimate excluded logs ingestion (£0.25/month = £3/year)
- Original estimate used aggressive query caching (fewer Timestream queries)

Revised accurate estimate: £22/year for 20 devices (~£1.10/device/year backend cost)

---

 Cost Model: 100-Device Deployment (Small Office Building)

 Assumptions

- Devices: 100 sensors, 1 building
- Gateways: 5× Raspberry Pi 4 (£275 upfront, amortized over 3 years = £92/year)
- Messages/month: 100 devices × 108 msg/day × 30 days = 324,000 messages
- Queries/month: 200 dashboard loads/day × 5 queries = 1,000 queries/day = 30,000 queries/month
- Alerts/month: 25 alerts/day = 750 alerts/month
- Users: 10 facilities managers

 Cost Breakdown

| Service | Monthly Cost (USD) | Monthly Cost (GBP) | Notes |
|---------|-------------------|-------------------|-------|
| AWS IoT Core | $0.34 | £0.27 | 5 gateways, 324k messages |
| Timestream | $9.20 | £7.42 | 5× data volume, memory storage dominates |
| Lambda | $0.14 | £0.11 | 324k telemetry invocations |
| API Gateway | $0.11 | £0.09 | 30k API requests |
| S3 | $0.013 | £0.011 | Firmware storage (unchanged) |
| SNS | $0.015 | £0.012 | 750 alerts/month |
| Cognito | $0.00 | £0.00 | 10 users (within free tier) |
| CloudWatch | $1.40 | £1.13 | 5× logs volume |
| DynamoDB | $0.010 | £0.008 | 100 device records |
| TOTAL | $11.24 | £9.06 |

Annual cost: £9.06/month × 12 = £108.72 ≈ £109/year

Cost per device: £109 / 100 devices = £1.09/device/year (consistent with 20-device model, economies of scale minimal at this tier)

---

 Cost Model: 500-Device Deployment (Multi-Building Campus)

 Assumptions

- Devices: 500 sensors, 5 buildings
- Gateways: 25× Raspberry Pi 4 (£1,375 upfront, amortized over 3 years = £458/year)
- Messages/month: 500 × 108 × 30 = 1,620,000 messages
- Queries/month: 500 dashboard loads/day × 5 queries = 2,500 queries/day = 75,000 queries/month
- Alerts/month: 100 alerts/day = 3,000 alerts/month
- Users: 25 facilities managers

 Cost Breakdown

| Service | Monthly Cost (USD) | Monthly Cost (GBP) | Notes |
|---------|-------------------|-------------------|-------|
| AWS IoT Core | $1.70 | £1.37 | 25 gateways, 1.62M messages |
| Timestream | $46.00 | £37.10 | Memory storage 25× baseline |
| Lambda | $0.70 | £0.56 | 1.62M telemetry invocations |
| API Gateway | $0.26 | £0.21 | 75k API requests |
| S3 | $0.013 | £0.011 | Firmware storage (unchanged) |
| SNS | $0.06 | £0.048 | 3,000 alerts/month |
| Cognito | $0.00 | £0.00 | 25 users (within free tier) |
| CloudWatch | $7.00 | £5.65 | 25× logs volume |
| DynamoDB | $0.050 | £0.040 | 500 device records |
| TOTAL | $55.79 | £44.99 |

Annual cost: £45/month × 12 = £540/year

Cost per device: £540 / 500 devices = £1.08/device/year (slight economy of scale emerging)

---

 Cost Model: 5,000-Device Deployment (Multi-Tenant SaaS, 50 Buildings)

 Assumptions

- Devices: 5,000 sensors across 50 buildings
- Gateways: 250× Raspberry Pi 4 (£13,750 upfront, amortized = £4,583/year)
- Messages/month: 5,000 × 108 × 30 = 16,200,000 messages
- Queries/month: 2,000 dashboard loads/day × 5 queries = 10,000 queries/day = 300,000 queries/month
- Alerts/month: 500 alerts/day = 15,000 alerts/month
- Users: 150 facilities managers (multi-tenant)

 Cost Breakdown

| Service | Monthly Cost (USD) | Monthly Cost (GBP) | Notes |
|---------|-------------------|-------------------|-------|
| AWS IoT Core | $17.00 | £13.71 | 250 gateways, 16.2M messages |
| Timestream | $460.00 | £370.97 | Memory storage scales linearly |
| Lambda | $7.00 | £5.65 | 16.2M telemetry invocations |
| API Gateway | $1.05 | £0.85 | 300k API requests |
| S3 | $0.05 | £0.04 | Firmware + multi-tenant assets |
| SNS | $0.30 | £0.24 | 15,000 alerts/month |
| Cognito | $7.50 | £6.05 | 150 MAU × $0.05 (advanced security enabled) |
| CloudWatch | $70.00 | £56.45 | 250× logs volume |
| DynamoDB | $0.50 | £0.40 | 5,000 device records + tenant metadata |
| TOTAL | $563.40 | £454.36 |

Annual cost: £454/month × 12 = £5,452/year

Cost per device: £5,452 / 5,000 devices = £1.09/device/year (economy of scale plateaus; Timestream memory storage dominates)

---

 Optimization Strategies

 1. Reserved Capacity (Timestream)

Problem: Memory storage (hot) is the dominant cost (£371/month for 5,000 devices).

Solution: Purchase Timestream memory storage Reserved Capacity (1-year commitment).

Discount: 20% off on-demand rates  
Savings: £371/month × 0.20 = £74/month = £888/year

Revised annual cost (5,000 devices): £5,452 - £888 = £4,564/year

 2. Data Retention Tuning

Current: 90 days hot, 2 years warm

Optimized: 30 days hot, 2 years warm (most queries focus on recent data)

Impact:
- Memory storage: 90 days → 30 days = 3× reduction
- Timestream cost: £371/month → £124/month
- Savings: £247/month = £2,964/year

Trade-off: Historical queries (60-90 days old) slower (magnetic storage scan)

 3. Query Caching (ElastiCache Redis)

Problem: Dashboard queries scan Timestream repeatedly (300k queries/month).

Solution: Cache query results for 5 minutes in Redis (ElastiCache).

Cache hit rate: 80% (typical for time-series dashboards)  
Queries to Timestream: 300k × 0.20 = 60k/month (5× reduction)

ElastiCache cost: cache.t3.micro (1 GB) = £15/month  
Timestream query savings: 240k fewer queries × 0.5 MB × $0.01/GB = £0.97/month (negligible)

Net impact: +£15/month (not cost-effective at current scale; beneficial at 50k+ devices)

 4. Serverless Aurora (DynamoDB → Aurora)

Problem: DynamoDB scales linearly with device count; complex queries inefficient.

Solution: Migrate device registry to Aurora Serverless v2 (PostgreSQL).

Aurora cost (min capacity 0.5 ACU, ~£20/month):
- 5,000 devices: DynamoDB £0.40/month vs. Aurora £20/month → DynamoDB cheaper
- 50,000 devices: DynamoDB £4/month vs. Aurora £25/month → DynamoDB still cheaper

Conclusion: Keep DynamoDB (purpose-built for key-value lookups).

 5. S3 Intelligent-Tiering (Firmware Storage)

Current: S3 Standard (£0.023/GB/month)

Optimized: S3 Intelligent-Tiering (auto-moves infrequent-access objects to cheaper tiers)

Impact: Firmware older than 90 days → IA tier (£0.0125/GB/month, 46% savings)  
Savings: Minimal (firmware storage only 500 MB = £0.012/month → £0.007/month, ~£0.06/year)

Conclusion: Negligible savings; not worth implementation complexity.

---

 Scaling Projections Summary

| Deployment Size | Devices | Annual Cost (GBP) | Cost per Device/Year | Gateway Cost (Amortized) | Total Cost per Device |
|-----------------|---------|-------------------|---------------------|--------------------------|----------------------|
| Pilot | 20 | £22 | £1.10 | £18.33 (1 gateway) | £2.02 |
| Small | 100 | £109 | £1.09 | £92 (5 gateways) | £2.01 |
| Medium | 500 | £540 | £1.08 | £458 (25 gateways) | £2.00 |
| Large | 5,000 | £5,452 | £1.09 | £4,583 (250 gateways) | £2.01 |
| Enterprise (optimized) | 5,000 | £2,488 | £0.50 | £4,583 | £1.42 |

Key Insights:
- Linear scaling: Cloud cost per device remains constant (~£1.10/device/year) across 20-5,000 devices
- Gateway dominates: At scale, gateway hardware (£0.92/device/year) exceeds cloud cost
- Optimization potential: Data retention tuning (30d hot vs. 90d) reduces cost by 54% (£5,452 → £2,488)

---

 Break-Even Analysis: SaaS Business Model

 Revenue Model

Pricing tiers (annual subscription per building):
- Starter (up to 20 devices): £1,500/year
- Professional (21-100 devices): £5,000/year
- Enterprise (101-500 devices): £15,000/year

 Cost Structure

Per-building costs (100-device Professional tier):
- Cloud infrastructure: £109/year
- Gateway hardware (amortized): £92/year
- Customer support (10% of revenue): £500/year
- Sales & marketing (20% of revenue): £1,000/year
- Total cost: £1,701/year

Gross margin: £5,000 - £1,701 = £3,299/year (66% margin)

Break-even: Fixed costs (dev team £200k/year, infrastructure £50k/year) / £3,299 per customer = 76 customers (7,600 devices)

---

 Cost Comparison: Cloud vs. On-Premise

 On-Premise Alternative

Hardware (one-time):
- Server: Dell PowerEdge R340 (8-core, 32 GB RAM, 1 TB SSD) = £2,500
- MQTT broker: Mosquitto (open-source, free)
- Time-series DB: InfluxDB (open-source, free)
- Compute: Kubernetes cluster (included in server)

Annual operating costs:
- Electricity: 300W × 24h × 365d × £0.25/kWh = £657/year
- Internet: 100 Mbps dedicated = £600/year
- Maintenance: 20% of hardware cost = £500/year
- Total annual: £1,757/year

5-year TCO:
- On-premise: £2,500 (hardware) + £1,757/year × 5 = £11,285
- AWS (5,000 devices, optimized): £2,488/year × 5 = £12,440

Conclusion: On-premise competitive at <10,000 device scale, but lacks:
- Automatic scaling (AWS handles 100× traffic spikes)
- Geographic redundancy (AWS 99.9% SLA, multi-AZ)
- Zero operational overhead (no patching, backup management)

Recommendation: AWS preferred for MVP and early growth; consider hybrid (edge processing + cloud aggregation) at 50k+ devices.

---

 Data Transfer Costs (Internet Egress)

 Scenario: Dashboard Data Queries

Assumption: 75,000 queries/month (500-device deployment), 5 KB average response

Data egress: 75,000 × 5 KB = 375 MB/month = 0.375 GB/month

AWS pricing (first 10 TB free from CloudFront):
- Direct from API Gateway: 0.375 GB × $0.09/GB = $0.034 ≈ £0.027/month (negligible)

With CloudFront CDN (cache API responses):
- Cache hit rate: 60% (typical for time-series dashboards)
- Origin egress: 0.375 GB × 0.40 = 0.15 GB (40% miss rate)
- CloudFront cost: 0.375 GB × $0.085/GB = $0.032 ≈ £0.026/month

Conclusion: Data transfer costs negligible (<1% of total); no optimization needed.

---

 References

1. AWS Pricing Calculator, AWS IoT Core, Timestream, Lambda Pricing, eu-west-1 region, accessed January 2026.
2. Amazon Web Services, AWS Well-Architected Framework: Cost Optimization Pillar, 2024.
3. Gartner, Total Cost of Ownership (TCO) for Cloud vs. On-Premises IoT Platforms, Research Note G00768945, 2025.
4. InfluxData, InfluxDB Clustering Guide and Cost Analysis, 2024. [Online]. Available: https://www.influxdata.com/

---

Document Version: 1.0  
Last Updated: January 12, 2026  
Validated By: Cloud FinOps Team, Cost Optimization Review
