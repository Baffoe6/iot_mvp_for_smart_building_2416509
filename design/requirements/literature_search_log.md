 Literature and Market Survey - Search Log

 Purpose
This log documents the search strategy, sources consulted, and inclusion/exclusion criteria for each component category. It supports reproducibility and demonstrates systematic, research-led decision-making.

---

 Search Strategy

 Source Categories
1. Scholarly Literature: IEEE Xplore, ACM Digital Library, Google Scholar
2. Standards Bodies: IETF RFCs, 3GPP, Bluetooth SIG, LoRa Alliance, Connectivity Standards Alliance (Matter/Zigbee)
3. Manufacturer Datasheets: Bosch, Sensirion, STMicroelectronics, Nordic Semiconductor, Texas Instruments, Espressif
4. Industry White Papers: Cloud providers (AWS IoT, Azure IoT, Google Cloud IoT), broker vendors (HiveMQ, EMQX)
5. Open-Source Projects: Zephyr RTOS, FreeRTOS, Eclipse Mosquitto, Node-RED

 Temporal Scope
- Scholarly: 2019-2026 (last 7 years; IoT protocols and sensors evolve rapidly)
- Standards: Current ratified versions (e.g., MQTT 5.0, BLE 5.x, LoRaWAN 1.0.4)
- Datasheets: Currently in production (exclude obsolete or "not recommended for new designs")

 General Inclusion Criteria
- Production-ready components (not research prototypes)
- Safety/EMC compliance (CE, FCC, RoHS)
- Available through major distributors (Mouser, DigiKey, Farnell)
- Documented power consumption (active/sleep currents specified)
- English-language documentation

 General Exclusion Criteria
- Hobby-grade boards without datasheets (e.g., undocumented clones)
- Components requiring NDAs for specs (not suitable for academic transparency)
- Discontinued or end-of-life products
- Proprietary protocols with no open-source implementations
- Sources without peer review or manufacturer verification

---

 Component Category 1: CO₂ Sensors

 Search Queries
| Query | Source | Date | Results |
|-------|--------|------|---------|
| `NDIR CO2 sensor low power battery` | Google Scholar | 2026-01-12 | [Record count] |
| `"indoor air quality" IoT sensor accuracy` | IEEE Xplore | 2026-01-12 | [Record count] |
| `Sensirion SCD40 datasheet` | Manufacturer | 2026-01-12 | Direct link |
| `Bosch BME680 VOC BSEC` | Manufacturer | 2026-01-12 | Direct link |

 Inclusion Criteria (Sensors)
- NDIR (non-dispersive infrared) or equivalent optical CO₂ measurement
- Range 400-5000 ppm (covers typical indoor scenarios)
- Accuracy ≤±50 ppm + 3%
- Operating current <50 mA average (during measurement)
- Sleep current <10 µA
- I²C or UART interface (low pin count, MCU-friendly)
- Unit cost <£20 in qty 100

 Exclusion Criteria (Sensors)
- Electrochemical CO₂ sensors (drift, short lifetime)
- Metal-oxide gas sensors without calibration (poor CO₂ selectivity)
- Sensors requiring external pump or fan (power budget violation)
- Sensors without auto-calibration or baseline correction

 Key Findings (To be populated)
- Sensirion SCD40/SCD41: [Note accuracy, power, cost, pros/cons]
- Senseair Sunrise: [Compare]
- Alternative considerations: [If any]

---

 Component Category 2: Occupancy Sensors

 Search Queries
| Query | Source | Date | Results |
|-------|--------|------|---------|
| `PIR motion sensor low power` | DigiKey parametric | 2026-01-12 | [Count] |
| `mmWave radar occupancy detection indoor` | Google Scholar | 2026-01-12 | [Count] |
| `"time-of-flight" presence detection` | Manufacturer (STM) | 2026-01-12 | VL53L1X docs |

 Inclusion Criteria
- Presence detection (not identity)
- Detection range 3-5 m (typical office room)
- False negative rate <5% (occupied room must be detected)
- Standby current <5 µA
- Digital output (interrupt-driven, no ADC needed)
- Privacy-preserving (no image capture)

 Exclusion Criteria
- Camera-based solutions (privacy violation)
- BLE/Wi-Fi MAC address sniffing (personal data, GDPR risk)
- Ultrasonic sensors (audible artifacts, higher power)

 Key Findings (To be populated)
- Passive Infrared (PIR): [e.g., Panasonic EKMB series]
- mmWave radar: [e.g., Infineon BGT60TR13C—higher cost, better accuracy]
- Time-of-Flight: [e.g., STM VL53L1X—very low power, short range]

---

 Component Category 3: Microcontroller Unit (MCU)

 Search Queries
| Query | Source | Date | Results |
|-------|--------|------|---------|
| `low power MCU BLE 5 ARM Cortex` | Manufacturer | 2026-01-12 | Nordic, TI, STM catalogs |
| `"ultra-low-power" IoT microcontroller` | IEEE Xplore | 2026-01-12 | [Papers on MCU benchmarking] |
| `nRF52840 power consumption` | Nordic datasheet | 2026-01-12 | Direct |
| `STM32WB55 BLE stack` | STMicro docs | 2026-01-12 | Direct |

 Inclusion Criteria
- ARM Cortex-M0+/M4 or equivalent (efficient, toolchain support)
- Deep sleep current <2 µA (RTC running, RAM retention)
- Active current <5 mA/MHz (for short burst processing)
- Integrated BLE 5.x or LoRa radio (reduces BOM, improves power efficiency)
- ≥256 KB Flash, ≥64 KB RAM (OTA updates, TLS stack)
- I²C, UART, SPI peripherals
- Hardware crypto accelerator (AES for TLS)
- Development ecosystem: GCC support, RTOS ports (Zephyr, FreeRTOS)

 Exclusion Criteria
- No Wi-Fi MCUs (e.g., ESP32—too high active current for 2-year battery life)
- Legacy 8-bit MCUs (limited tooling, no TLS crypto acceleration)
- Proprietary toolchains requiring paid licenses

 Key Findings (To be populated)
- Nordic nRF52840: [BLE 5.2, excellent power, strong ecosystem]
- STM32WB55: [Dual-core, BLE + 802.15.4, lower cost]
- TI CC2652R: [Zigbee/Thread, lower RAM]

---

 Component Category 4: Communication Protocols

 Search Queries
| Query | Source | Date | Results |
|-------|--------|------|---------|
| `MQTT QoS battery-powered IoT` | IEEE Xplore | 2026-01-12 | [Papers] |
| `LoRaWAN vs Zigbee power consumption` | Google Scholar | 2026-01-12 | [Comparisons] |
| `BLE GATT IoT gateway` | Bluetooth SIG | 2026-01-12 | Specs |
| `CoAP vs MQTT constrained devices` | IETF RFC 7252 | 2026-01-12 | Standard |

 Inclusion Criteria
- Proven in building automation or IoT deployments (not experimental)
- Open standard with multiple vendor implementations
- Security: supports TLS 1.2+ or equivalent (DTLS, application-layer encryption)
- QoS flexibility (at-least-once for critical alerts)
- Low overhead for small payloads (<100 bytes)
- Gateway/hub availability (for sub-GHz or BLE)

 Exclusion Criteria
- Proprietary protocols (vendor lock-in)
- Protocols without encryption (plain HTTP, MQTT without TLS)
- Protocols requiring continuous connection (TCP keep-alive drains battery)

 Key Findings (To be populated)
- BLE → Gateway → MQTT/TLS: [Rationale, power, complexity]
- LoRaWAN → Network Server → MQTT: [Range, power, latency]
- Zigbee → Coordinator → MQTT Bridge: [Mesh, reliability, ecosystem]

---

 Component Category 5: Cloud Platform

 Search Queries
| Query | Source | Date | Results |
|-------|--------|------|---------|
| `AWS IoT Core pricing 2026` | AWS Docs | 2026-01-12 | Pricing page |
| `Azure IoT Hub MQTT broker` | Microsoft Docs | 2026-01-12 | Feature comparison |
| `self-hosted MQTT broker scalability` | EMQX / HiveMQ | 2026-01-12 | White papers |
| `time-series database IoT` | InfluxData, TimescaleDB | 2026-01-12 | Documentation |

 Inclusion Criteria
- MQTT 5.0 or 3.1.1 support (device compatibility)
- TLS 1.2+ with X.509 certificate authentication
- Per-device authentication and ACL support
- Time-series storage or integration (InfluxDB, TimescaleDB, AWS Timestream)
- SLA ≥99.5% uptime
- Transparent pricing (no surprise data egress fees)
- EU data residency options (GDPR compliance)

 Exclusion Criteria
- Platforms without device-level authentication (shared keys only)
- Closed ecosystems without MQTT bridge (e.g., proprietary-only APIs)
- Platforms with prohibitive data egress costs (>£0.10/GB)

 Key Findings (To be populated)
- AWS IoT Core + Timestream: [Pros, cons, cost model]
- Azure IoT Hub + Azure Data Explorer: [Comparison]
- Self-hosted Mosquitto + InfluxDB + Grafana: [Control, cost, maintenance overhead]

---

 Search Screening Summary Template

For the Literature Review section of the report:

> "A systematic search was conducted across five source categories: scholarly databases (IEEE Xplore, ACM DL), standards bodies (IETF, Bluetooth SIG, LoRa Alliance), manufacturer documentation, industry white papers, and open-source repositories. Searches were restricted to 2019-2026 for scholarly work and current production-grade components for hardware.
>
> Inclusion criteria prioritized: (1) production readiness, (2) documented power consumption, (3) safety/EMC compliance, (4) open standards, and (5) cost transparency. Exclusion criteria filtered out: (1) hobby-grade or undocumented components, (2) proprietary protocols without open implementations, (3) discontinued products, and (4) components with prohibitive cost or power budgets.
>
> For each component category (CO₂ sensors, occupancy sensors, MCUs, communication protocols, cloud platforms), 2-3 leading options were identified and subjected to weighted decision matrix analysis (Section X)."

---

 Notes

- Update this log as you conduct real searches. Record actual dates, result counts, and which papers/datasheets you consulted.
- In the final report, summarize the methodology in 1-2 paragraphs (see template above) and reference this log as an appendix if needed.
- Citation management: Use a reference manager (Zotero, Mendeley) to track DOIs, URLs, and datasheet versions.
