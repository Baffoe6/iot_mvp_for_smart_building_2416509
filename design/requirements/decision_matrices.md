 Decision Matrices

 Purpose
These matrices systematically compare technology options against the quantified constraints defined in `01_use_case_and_constraints.md`. Each matrix uses weighted scoring to justify final selections.

Scoring scale: 1 (poor) to 5 (excellent)

Weights (from constraints document):
- Energy: 30%
- Cost: 25%
- Accuracy/Performance: 20%
- Reliability: 15%
- Security: 10%

---

 Matrix 1: CO₂ Sensor Selection

 Comparison Options
1. Sensirion SCD40 (NDIR, I²C)
2. Sensirion SCD41 (NDIR, I²C, improved accuracy)
3. Senseair Sunrise (NDIR, UART, modular)

 Metrics and Scoring

| Metric | Weight | SCD40 | SCD41 | Sunrise | Notes |
|--------|--------|-------|-------|---------|-------|
| Energy Consumption | 30% | | | | Average current over duty cycle |
| - Measurement current | | 5 (18 mA @ 5s) | 5 (18 mA @ 5s) | 3 (35 mA typ) | SCD4x superior |
| - Sleep current | | 5 (<0.5 µA) | 5 (<0.5 µA) | 4 (2 µA) | SCD4x negligible |
| - Duty cycle flexibility | | 5 (5s-30min) | 5 (5s-30min) | 4 (configurable) | All adequate |
| Cost | 25% | | | | Unit cost in qty 100 |
| - BOM cost | | 5 (~£12) | 4 (~£16) | 4 (~£14) | SCD40 most economical |
| Accuracy | 20% | | | | Against reference |
| - CO₂ accuracy | | 4 (±40ppm ±3%) | 5 (±40ppm ±2.5%) | 4 (±30ppm ±3%) | All meet ±50ppm target |
| - Auto-calibration | | 5 (ASC built-in) | 5 (ASC built-in) | 4 (manual + ASC) | SCD4x easier |
| - Temp/RH compensation | | 5 (integrated) | 5 (integrated) | 3 (external needed) | SCD4x advantage |
| Reliability | 15% | | | | Field deployment |
| - MTBF / lifetime | | 5 (>10 yrs) | 5 (>10 yrs) | 5 (>10 yrs) | NDIR stable |
| - Calibration drift | | 5 (ASC handles) | 5 (ASC handles) | 4 (periodic check) | ASC critical |
| - Operating temp | | 5 (0-50°C) | 5 (0-50°C) | 5 (0-60°C) | All adequate |
| Security | 10% | | | | I²C/UART interface |
| - Tamper resistance | | 3 (I²C sniffable) | 3 (I²C sniffable) | 3 (UART sniffable) | Not sensor concern |
| - Supply chain | | 5 (reputable) | 5 (reputable) | 5 (reputable) | All tier-1 vendors |

 Weighted Scores

| Option | Energy (30%) | Cost (25%) | Accuracy (20%) | Reliability (15%) | Security (10%) | Total |
|--------|-------------|-----------|---------------|------------------|---------------|-----------|
| SCD40 | 5.0 × 0.30 = 1.50 | 5.0 × 0.25 = 1.25 | 4.7 × 0.20 = 0.94 | 5.0 × 0.15 = 0.75 | 4.0 × 0.10 = 0.40 | 4.84 |
| SCD41 | 5.0 × 0.30 = 1.50 | 4.0 × 0.25 = 1.00 | 5.0 × 0.20 = 1.00 | 5.0 × 0.15 = 0.75 | 4.0 × 0.10 = 0.40 | 4.65 |
| Sunrise | 3.7 × 0.30 = 1.11 | 4.0 × 0.25 = 1.00 | 3.7 × 0.20 = 0.74 | 4.7 × 0.15 = 0.70 | 4.0 × 0.10 = 0.40 | 3.95 |

 Decision: Sensirion SCD40

Rationale:
- Highest weighted score (4.84), driven by best-in-class energy efficiency and cost
- Meets accuracy target (±40 ppm ±3% < ±50 ppm requirement)
- Automatic Self-Calibration (ASC) reduces maintenance and field calibration needs
- Integrated temperature/humidity sensor reduces BOM (multi-function)
- I²C interface simplifies MCU integration
- Wide availability, strong technical support, active community

Trade-offs accepted:
- SCD41 offers marginally better accuracy (±2.5% vs ±3%) but £4 higher cost; not justified given energy savings priority and both meet spec
- Sunrise is modular but higher power consumption violates 2-year battery constraint

---

 Matrix 2: Occupancy Sensor Selection

 Comparison Options
1. Panasonic EKMB Series PIR (passive infrared)
2. Infineon BGT60TR13C (60 GHz mmWave radar)
3. STM VL53L1X (Time-of-Flight laser ranging)

 Metrics and Scoring

| Metric | Weight | PIR (EKMB) | mmWave (BGT60) | ToF (VL53L1X) | Notes |
|--------|--------|------------|----------------|---------------|-------|
| Energy | 30% | | | | |
| - Active current | | 5 (<10 µA) | 2 (~15 mA) | 4 (~20 mA pulsed) | PIR negligible |
| - Standby | | 5 (<5 µA) | 3 (~500 µA) | 5 (<1 µA) | PIR and ToF excellent |
| Cost | 25% | | | | |
| - BOM cost | | 5 (~£3) | 1 (~£20) | 4 (~£5) | PIR most economical |
| Accuracy | 20% | | | | |
| - Detection range | | 4 (5 m) | 5 (10 m) | 2 (1-2 m) | PIR adequate for rooms |
| - False positives | | 3 (heat sources) | 5 (Doppler) | 5 (distance) | PIR acceptable indoors |
| - Stationary detect | | 1 (motion only) | 5 (breathing) | 3 (presence if aimed) | PIR limitation known |
| Reliability | 15% | | | | |
| - Field-proven | | 5 (decades) | 3 (emerging) | 4 (established) | PIR mature |
| - Environmental | | 4 (temp sensitive) | 5 (robust) | 4 (optical) | All adequate indoors |
| Security | 10% | | | | |
| - Privacy | | 5 (no PII) | 5 (no imaging) | 5 (distance only) | All compliant |

 Weighted Scores

| Option | Energy (30%) | Cost (25%) | Accuracy (20%) | Reliability (15%) | Security (10%) | Total |
|--------|-------------|-----------|---------------|------------------|---------------|-----------|
| PIR (EKMB) | 5.0 × 0.30 = 1.50 | 5.0 × 0.25 = 1.25 | 2.7 × 0.20 = 0.54 | 4.5 × 0.15 = 0.68 | 5.0 × 0.10 = 0.50 | 4.47 |
| mmWave | 2.5 × 0.30 = 0.75 | 1.0 × 0.25 = 0.25 | 5.0 × 0.20 = 1.00 | 4.0 × 0.15 = 0.60 | 5.0 × 0.10 = 0.50 | 3.10 |
| ToF | 4.5 × 0.30 = 1.35 | 4.0 × 0.25 = 1.00 | 3.3 × 0.20 = 0.66 | 4.0 × 0.15 = 0.60 | 5.0 × 0.10 = 0.50 | 4.11 |

 Decision: PIR (Panasonic EKMB Series)

Rationale:
- Highest weighted score (4.47), dominated by best energy and cost performance
- Ultra-low power (<10 µA) critical for 2-year battery target
- Lowest BOM cost (~£3) supports <£50 device constraint
- Adequate for use case: motion detection in office spaces (people move, type, shift in chairs)
- Mature technology, extensive field deployment history

Trade-offs accepted:
- Cannot detect stationary occupants (meeting room with still participants)—acceptable for MVP; majority of occupancy involves movement
- False positives from heat sources (radiators, sunlight)—placement guidelines mitigate (away from windows, HVAC vents)
- mmWave superior accuracy but 7× cost and 1500× active power consumption violates constraints

Mitigation:
- Placement protocol: mount at 1.2-1.5 m height, 45° downward angle, away from windows and vents
- Combine with CO₂ sensor: if CO₂ rising but PIR idle, occupancy likely (people are stationary); if CO₂ stable and PIR idle, room truly vacant

---

 Matrix 3: Microcontroller Unit (MCU) Selection

 Comparison Options
1. Nordic nRF52840 (ARM Cortex-M4F, BLE 5.2)
2. STM32WB55 (Dual Cortex-M4 + M0, BLE 5.0)
3. TI CC2652R (ARM Cortex-M4F, Zigbee/Thread)

 Metrics and Scoring

| Metric | Weight | nRF52840 | STM32WB55 | CC2652R | Notes |
|--------|--------|----------|-----------|---------|-------|
| Energy | 30% | | | | |
| - Deep sleep (RTC on) | | 5 (0.6 µA) | 5 (0.6 µA) | 4 (1.0 µA) | nRF/STM excellent |
| - Active (per MHz) | | 5 (~50 µA/MHz) | 5 (~50 µA/MHz) | 4 (~60 µA/MHz) | Similar efficiency |
| - Radio TX power options | | 5 (+8 to -20 dBm) | 4 (+6 to -20 dBm) | 4 (+5 to -20 dBm) | nRF flexible |
| - Radio RX current | | 5 (5.3 mA) | 4 (6.0 mA) | 4 (6.5 mA) | nRF slightly better |
| Cost | 25% | | | | |
| - Unit price (qty 100) | | 4 (~£6) | 5 (~£5) | 4 (~£5.50) | STM most economical |
| Accuracy/Performance | 20% | | | | |
| - Flash / RAM | | 5 (1 MB / 256 KB) | 4 (1 MB / 256 KB) | 3 (352 KB / 80 KB) | nRF and STM superior |
| - Crypto accelerator | | 5 (AES-128/256) | 5 (AES-128/256, PKA) | 4 (AES-128) | All adequate for TLS |
| - Peripherals (I²C, ADC) | | 5 (2×I²C, 12-bit ADC) | 5 (2×I²C, 12-bit ADC) | 4 (1×I²C, 12-bit ADC) | nRF/STM richer |
| Reliability | 15% | | | | |
| - RTOS support | | 5 (Zephyr, FreeRTOS) | 5 (FreeRTOS, Azure) | 4 (TI-RTOS, Zephyr) | nRF/STM better ecosystem |
| - Toolchain maturity | | 5 (GCC, Segger, VSCode) | 5 (GCC, STM32CubeIDE) | 4 (TI CCS, GCC) | nRF/STM open |
| - Community support | | 5 (extensive) | 4 (growing) | 3 (moderate) | nRF strongest |
| Security | 10% | | | | |
| - Secure boot | | 5 (built-in) | 5 (secure boot) | 4 (optional) | nRF/STM robust |
| - OTA capability | | 5 (dual-bank) | 5 (dual-bank) | 4 (single-bank) | nRF/STM safer rollback |

 Weighted Scores

| Option | Energy (30%) | Cost (25%) | Performance (20%) | Reliability (15%) | Security (10%) | Total |
|--------|-------------|-----------|------------------|------------------|---------------|-----------|
| nRF52840 | 5.0 × 0.30 = 1.50 | 4.0 × 0.25 = 1.00 | 5.0 × 0.20 = 1.00 | 5.0 × 0.15 = 0.75 | 5.0 × 0.10 = 0.50 | 4.75 |
| STM32WB55 | 5.0 × 0.30 = 1.50 | 5.0 × 0.25 = 1.25 | 4.7 × 0.20 = 0.94 | 4.7 × 0.15 = 0.70 | 5.0 × 0.10 = 0.50 | 4.89 |
| CC2652R | 4.0 × 0.30 = 1.20 | 4.0 × 0.25 = 1.00 | 3.7 × 0.20 = 0.74 | 3.7 × 0.15 = 0.55 | 4.0 × 0.10 = 0.40 | 3.89 |

 Decision: STM32WB55

Rationale:
- Highest weighted score (4.89), balancing all criteria
- Equivalent deep sleep performance to nRF52840 (0.6 µA), meeting 2-year battery target
- Lowest unit cost (~£5), improving BOM margin
- Dual-core architecture: M4 for application, M0 for BLE stack—reduces timing conflicts
- Strong security: secure boot, dual-bank OTA, AES + PKA accelerators
- STM32 ecosystem mature, extensive ST tools (CubeMX, CubeIDE), active community

Trade-offs accepted:
- nRF52840 has slightly better radio RX efficiency (5.3 mA vs 6.0 mA) and stronger community—not decisive given similar sleep currents
- CC2652R supports Zigbee mesh (multi-hop resilience) but lower RAM limits TLS stack and OTA buffer; BLE sufficient for single-room-to-gateway model

Alternative justification:
If BLE ecosystem and community support are prioritized over £1 cost saving, nRF52840 is an equally defensible choice (score 4.75 vs 4.89—within margin of error). Final decision may depend on team familiarity or existing infrastructure.

---

 Matrix 4: Communication Protocol Selection

 Comparison Options
1. BLE 5.x + Gateway → MQTT/TLS
2. LoRaWAN 1.0.4 + Network Server → MQTT
3. Zigbee 3.0 + Coordinator → MQTT Bridge

 Metrics and Scoring

| Metric | Weight | BLE + MQTT | LoRaWAN + MQTT | Zigbee + MQTT | Notes |
|--------|--------|------------|----------------|---------------|-------|
| Energy | 30% | | | | |
| - Device TX energy | | 5 (~10 mA × 3 ms) | 4 (~40 mA × 100 ms) | 4 (~30 mA × 5 ms) | BLE lowest per msg |
| - Connection overhead | | 4 (conn intervals) | 5 (ALOHA, no assoc) | 3 (mesh routing) | LoRa best for infrequent |
| - Sleep between TX | | 5 (immediate sleep) | 5 (immediate sleep) | 4 (parent polling) | BLE/LoRa better |
| Cost | 25% | | | | |
| - Device radio cost | | 5 (integrated MCU) | 3 (£3-5 module) | 4 (£2-4 module) | BLE cheapest (in MCU) |
| - Gateway cost | | 4 (£50 RPi + dongle) | 3 (£150 LoRa GW) | 4 (£50 Zigbee coord) | BLE and Zigbee lower |
| - Backend cost | | 5 (standard MQTT) | 4 (LNS fees or self-host) | 5 (standard MQTT) | LoRa may need LNS sub |
| Performance | 20% | | | | |
| - Latency (routine) | | 5 (<1 s) | 3 (1-5 s Class A) | 4 (<2 s) | BLE fastest |
| - Latency (alerts) | | 5 (<1 s) | 2 (Class A delay) | 4 (~1 s routed) | BLE immediate |
| - Payload size | | 5 (244 bytes BLE 5) | 4 (51-242 bytes DR) | 5 (80+ bytes) | All adequate |
| - Range | | 3 (10-30 m indoors) | 5 (2-5 km LoS) | 4 (30-100 m mesh) | LoRa for long range |
| Reliability | 15% | | | | |
| - QoS support | | 5 (MQTT QoS 0/1/2) | 3 (LoRa unconf/conf) | 5 (MQTT QoS via bridge) | BLE/Zigbee flexible |
| - Retry/ACK | | 5 (BLE + MQTT ACKs) | 4 (LoRa confirmed) | 5 (Zigbee APS + MQTT) | All adequate |
| - Network density | | 4 (1 GW per 10-20 dev) | 5 (1 GW per 1000s) | 4 (mesh scales) | LoRa best for sparse |
| Security | 10% | | | | |
| - Encryption | | 5 (BLE pair + TLS) | 4 (AES-128 + AppKey) | 5 (AES-128 + TLS) | All meet req |
| - Key management | | 5 (X.509 certs) | 4 (static keys) | 5 (install codes) | BLE/Zigbee better |

 Weighted Scores

| Option | Energy (30%) | Cost (25%) | Performance (20%) | Reliability (15%) | Security (10%) | Total |
|--------|-------------|-----------|------------------|------------------|---------------|-----------|
| BLE + MQTT | 4.7 × 0.30 = 1.41 | 4.7 × 0.25 = 1.17 | 5.0 × 0.20 = 1.00 | 4.7 × 0.15 = 0.70 | 5.0 × 0.10 = 0.50 | 4.78 |
| LoRaWAN | 4.7 × 0.30 = 1.41 | 3.3 × 0.25 = 0.83 | 3.5 × 0.20 = 0.70 | 4.0 × 0.15 = 0.60 | 4.0 × 0.10 = 0.40 | 3.94 |
| Zigbee | 3.7 × 0.30 = 1.11 | 4.3 × 0.25 = 1.08 | 4.3 × 0.20 = 0.86 | 4.7 × 0.15 = 0.70 | 5.0 × 0.10 = 0.50 | 4.25 |

 Decision: BLE 5.x + Gateway → MQTT/TLS

Rationale:
- Highest weighted score (4.78), excelling in energy, performance, and security
- BLE radio integrated into selected MCU (STM32WB55), zero additional BOM cost
- Lowest per-message energy (<30 µJ per 100-byte packet) supports 2-year battery target
- Sub-second latency for alerts meets <5 min requirement with margin
- Gateway cost-effective (Raspberry Pi 4 + BLE dongle ~£50, or commercial BLE-MQTT gateways ~£80-150)
- Security: BLE pairing + TLS 1.2 with X.509 certificates to cloud broker
- Adequate range for single-floor deployment (10-30 m typical, up to 100 m BLE 5 Long Range mode if needed)

Trade-offs accepted:
- LoRaWAN superior for outdoor, long-range, or multi-building deployments—not required for MVP (single building, indoor)
- Zigbee mesh offers multi-hop resilience but higher device complexity (routing tables, parent/child associations) and slightly higher power consumption—not justified for ~20 devices in gateway range
- BLE range limitation manageable: 1-2 gateways per floor adequate for typical office (500-1000 m²)

Protocol stack:
- Device → Gateway: BLE GATT (custom service with read/notify characteristics for sensor data)
- Gateway → Cloud: MQTT over TLS 1.2, QoS 1 (at-least-once) for sensor data, QoS 2 for alerts (rare)
- Topic schema: `building/{building_id}/device/{device_id}/telemetry` (JSON payload)

---

 Matrix 5: Cloud Platform Selection

 Comparison Options
1. AWS IoT Core + Timestream
2. Azure IoT Hub + Azure Data Explorer
3. Self-hosted: Mosquitto + InfluxDB + Grafana

 Metrics and Scoring

| Metric | Weight | AWS IoT | Azure IoT | Self-hosted | Notes |
|--------|--------|---------|-----------|-------------|-------|
| Energy | 30% | | | | (Indirect: cloud CO₂) |
| - Data center PUE | | 4 (1.2 typical) | 4 (1.2 typical) | 3 (1.5-1.8 coloc) | AWS/Azure greener |
| - Renewable energy | | 5 (80%+ regions) | 5 (70%+ regions) | 2 (depends on host) | Managed better |
| Cost | 25% | | | | 20 devices, 10 msg/hr |
| - Ingest cost | | 3 (£1/M msgs) | 3 (£8400/unit/yr) | 5 (VPS ~£10/mo) | Self-hosted cheapest |
| - Storage cost | | 4 (Timestream £0.50/GB-mo) | 3 (ADX £££) | 5 (InfluxDB on VPS) | Self-hosted wins |
| - Egress cost | | 3 (£0.09/GB) | 3 (similar) | 5 (flat VPS) | AWS/Azure surprise bills |
| Performance | 20% | | | | |
| - Ingest throughput | | 5 (millions/sec) | 5 (millions/sec) | 4 (10k/sec Mosquitto) | All exceed MVP needs |
| - Query latency | | 5 (Timestream fast) | 5 (ADX excellent) | 4 (InfluxDB good) | Managed DBs optimized |
| - Scalability | | 5 (auto-scale) | 5 (auto-scale) | 2 (manual tuning) | Managed elastic |
| Reliability | 15% | | | | |
| - SLA | | 5 (99.9%) | 5 (99.9%) | 3 (self-managed) | Managed guaranteed |
| - Backup/DR | | 5 (automated) | 5 (automated) | 3 (DIY scripts) | Managed safer |
| - Maintenance | | 5 (zero ops) | 5 (zero ops) | 2 (weekly updates) | Managed hands-off |
| Security | 10% | | | | |
| - X.509 auth | | 5 (native) | 5 (native) | 4 (Mosquitto plugin) | All adequate |
| - ACL management | | 5 (IAM + policies) | 5 (RBAC) | 3 (manual config files) | Managed richer |
| - Audit logs | | 5 (CloudTrail) | 5 (Monitor) | 2 (custom logging) | Managed compliant |

 Weighted Scores

| Option | Energy (30%) | Cost (25%) | Performance (20%) | Reliability (15%) | Security (10%) | Total |
|--------|-------------|-----------|------------------|------------------|---------------|-----------|
| AWS IoT | 4.5 × 0.30 = 1.35 | 3.3 × 0.25 = 0.83 | 5.0 × 0.20 = 1.00 | 5.0 × 0.15 = 0.75 | 5.0 × 0.10 = 0.50 | 4.43 |
| Azure IoT | 4.5 × 0.30 = 1.35 | 3.0 × 0.25 = 0.75 | 5.0 × 0.20 = 1.00 | 5.0 × 0.15 = 0.75 | 5.0 × 0.10 = 0.50 | 4.35 |
| Self-hosted | 2.5 × 0.30 = 0.75 | 5.0 × 0.25 = 1.25 | 4.0 × 0.20 = 0.80 | 2.7 × 0.15 = 0.40 | 3.0 × 0.10 = 0.30 | 3.50 |

 Decision: AWS IoT Core + Timestream (with strong consideration for self-hosted)

Rationale for AWS IoT Core:
- Highest weighted score (4.43), strong in energy/sustainability, performance, reliability, security
- Native MQTT broker with per-device X.509 certificate authentication
- Rules Engine for routing data to Timestream (time-series DB optimized for IoT)
- Automatic scaling, 99.9% SLA, zero operational overhead for MVP phase
- Cost estimate for 20 devices @ 10 msg/hr:
  - Ingest: 20 × 24 × 30 × 10 = 144,000 msgs/mo ≈ £0.14/mo
  - Timestream: ~1 MB/day = 30 MB/mo = £15/mo (storage + queries)
  - Total: ~£180/year (within <£500 backend budget)
- AWS sustainability: 80% renewable energy in eu-west-1 (Ireland), PUE 1.2

Alternative: Self-hosted (score 3.50, but context-dependent)
- Lowest cost: DigitalOcean VPS (2 vCPU, 4 GB RAM) £20/mo = £240/yr, but includes compute/storage/egress
- Full control: Custom ACLs, audit logs, data residency, no vendor lock-in
- Learning value: Demonstrates understanding of broker internals, database tuning
- Trade-offs: Requires maintenance (security patches, backups, monitoring), no SLA, higher CO₂ (average data center PUE)

Recommendation:
- For MVP report and initial deployment: AWS IoT Core (de-risks reliability, scales easily, aligns with industry practice)
- For advanced discussion in report: Acknowledge self-hosted as cost-effective alternative if DevOps capacity available; include TCO comparison in appendix

---

 Summary of Final Selections

| Component | Selected Option | Key Justification |
|-----------|----------------|-------------------|
| CO₂ Sensor | Sensirion SCD40 | Best energy (18 mA @ 5s), cost (£12), auto-calibration, meets accuracy target |
| Occupancy | Panasonic EKMB PIR | Ultra-low power (<10 µA), lowest cost (£3), adequate for motion-based occupancy |
| MCU | STM32WB55 | Equivalent energy to nRF52840, lowest cost (£5), dual-core BLE, strong security/OTA |
| Protocol | BLE 5.x + MQTT/TLS | Lowest per-message energy, sub-second latency, integrated radio, X.509 security |
| Cloud | AWS IoT Core + Timestream | High reliability (99.9% SLA), zero ops, sustainable (80% renewable), scales effortlessly |

Total estimated BOM: £12 (CO₂) + £3 (PIR) + £5 (MCU) + £8 (battery, PCB, enclosure, passives) = £28 (well under £50 target, leaves margin for antenna, connectors, assembly)

Backend cost: ~£180/year for 20 devices (under £500 budget)

---

 Next Steps

1. Validate with datasheets: Cross-check power consumption figures, ensure parts are in stock
2. Prototype BOM: Order dev kits (STM32WB55 Nucleo, SCD40 breakout) for proof-of-concept
3. Architecture design: Define firmware modules, MQTT topic schema, data pipeline
4. Power budget spreadsheet: Model duty cycles, calculate battery lifetime with selected components
5. Security design: X.509 certificate generation, device provisioning flow, ACL policies
