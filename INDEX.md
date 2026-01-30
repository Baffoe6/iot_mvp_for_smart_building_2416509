 Master Document Index

Complete alphabetical and topical index of all documents in the IoT MVP project.

---

 Table of Contents

1. [Alphabetical Index](-alphabetical-index)
2. [Topical Index](️-topical-index)
3. [Search by Keyword](-search-by-keyword)
4. [By Technical Domain](-by-technical-domain)
5. [Reading Orders by Role](-reading-orders-by-role)
6. [External References Index](-external-references-index)

---

 Alphabetical Index

| Document | Location | Word Count | Purpose |
|----------|----------|------------|---------|
| Cloud Architecture | `design/architecture/cloud_architecture.md` | 4,800 | AWS IoT Core, Timestream, Lambda, API Gateway |
| Cloud Cost Analysis | `appendices/cloud_cost_analysis.md` | 9,500 | Pricing for 20/100/500/5k devices, SaaS model |
| Communications Design | `design/architecture/communications_design.md` | 3,800 | BLE 5.2, MQTT/TLS, Raspberry Pi gateway |
| Decision Matrices | `design/requirements/decision_matrices.md` | 4,200 | Weighted scoring for components (Energy 30%, Cost 25%) |
| Final Report | `report/final_report.md` | 1,500 | Academic submission - SUBMIT THIS |
| Firmware Architecture | `design/architecture/firmware_architecture.md` | 3,600 | FreeRTOS tasks, secure OTA, dual-bank flash |
| Hardware Design | `design/architecture/hardware_design.md` | 3,500 | STM32WB55, SCD40, BOM (£35), power (48 µA) |
| Literature Search Log | `design/requirements/literature_search_log.md` | 2,600 | Systematic review methodology, search queries |
| Mobile App Design | `design/architecture/mobile_app_design.md` | 4,400 | React dashboard, React Native mobile, WCAG 2.1 AA |
| MQTT Schema | `appendices/mqtt_schema.md` | 12,000 | Topic hierarchy, JSON payloads, ACL policies |
| OTA Updates | `appendices/ota_updates.md` | 15,000 | 5-phase update flow, RSA-2048, bootloader |
| Power Budget | `appendices/power_budget.md` | 18,500 | Component power, battery lifetime (2.4 years) |
| Security Privacy Sustainability | `design/implementation/security_privacy_sustainability.md` | 5,200 | Threat model, GDPR, carbon footprint |
| Test Plan | `testing/test_plan.md` | 8,000 | 92 tests (functional, security, UAT) |
| Use Case and Constraints | `design/requirements/use_case_and_constraints.md` | 2,800 | Problem statement, validated requirements |

---

 Topical Index

 Requirements & Planning
- [Use Case and Constraints](design/requirements/use_case_and_constraints.md) - Problem definition, success metrics (all )
- [Literature Search Log](design/requirements/literature_search_log.md) - Research methodology, IEEE/ACM/datasheets
- [Decision Matrices](design/requirements/decision_matrices.md) - SCD40 vs SCD41 vs Sunrise, STM32 vs nRF52 vs CC2652

 Hardware
- [Hardware Design](design/architecture/hardware_design.md) - Schematic, BOM (£35), 3× AA batteries, IP30 enclosure
- [Power Budget](appendices/power_budget.md) - 48 µA average → 2.4-year lifetime, temperature derating, Excel formulas

 Firmware
- [Firmware Architecture](design/architecture/firmware_architecture.md) - FreeRTOS (Sensing, Comms, Watchdog tasks)
- [OTA Updates](appendices/ota_updates.md) - Dual-bank flash, RSA-2048 signatures, anti-rollback (OTP fuses)

 Communications
- [Communications Design](design/architecture/communications_design.md) - BLE connection-less (10 µJ/msg), gateway buffering
- [MQTT Schema](appendices/mqtt_schema.md) - `{tenant}/building/{id}/gateway/{id}/device/{id}/{type}`, ACLs, QoS

 Cloud
- [Cloud Architecture](design/architecture/cloud_architecture.md) - AWS IoT Core rules, Timestream queries, Lambda
- [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - £22/year (20 devices), £1.09/device/year at all scales

 Applications
- [Mobile App Design](design/architecture/mobile_app_design.md) - 4 web screens, 3 mobile screens, floor plans, charts

 Security & Ethics
- [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 14 threats, GDPR Article 25, 7.17 kg CO₂e avoided

 Testing & Validation
- [Test Plan](testing/test_plan.md) - 92 tests, 98% pass rate, pilot results (3-31 Jan 2026)
- [Testing README](testing/README.md) - Summary table, security audit (Zero P0/P1)

 Submission
- [Final Report](report/final_report.md) - 1,500-word academic report - [Report README](report/README.md) - Submission checklist, assessment criteria mapping

---

 Search by Keyword

 Battery
- Lifetime: [Hardware Design](design/architecture/hardware_design.md) + [Power Budget](appendices/power_budget.md)
- Selection: [Decision Matrices](design/requirements/decision_matrices.md) - 3× AA lithium (Energizer L91)
- Monitoring: [Test Plan](testing/test_plan.md) - Voltage telemetry, low battery alerts

 BLE (Bluetooth Low Energy)
- Configuration: [Hardware Design](design/architecture/hardware_design.md) - STM32WB55, 0 dBm TX power
- Protocol: [Communications Design](design/architecture/communications_design.md) - Connection-less advertisements
- Testing: [Test Plan](testing/test_plan.md) - Range, interference, power consumption tests

 Cloud
- Architecture: [Cloud Architecture](design/architecture/cloud_architecture.md) - AWS services diagram
- Cost: [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - 4 scales (20/100/500/5k)
- Security: [MQTT Schema](appendices/mqtt_schema.md) - ACL policies, TLS 1.2

 CO₂ Sensor
- Selection: [Decision Matrices](design/requirements/decision_matrices.md) - Sensirion SCD40 (4.84/5.0)
- Integration: [Hardware Design](design/architecture/hardware_design.md) - I²C, 18 mA × 5s measurement
- Accuracy: [Test Plan](testing/test_plan.md) - ±45 ppm (vs. Vaisala GMP252 reference)

 Firmware
- Architecture: [Firmware Architecture](design/architecture/firmware_architecture.md) - FreeRTOS, Standby mode
- OTA: [OTA Updates](appendices/ota_updates.md) - 5-phase update flow, rollback
- Security: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - RSA-2048

 GDPR
- Compliance: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - Section 4.2
- Testing: [Test Plan](testing/test_plan.md) - GDPR compliance tests (5 tests, all )
- Report: [Final Report](report/final_report.md) - Section 4.2

 Gateway
- Hardware: [Communications Design](design/architecture/communications_design.md) - Raspberry Pi 4, £55
- Software: [MQTT Schema](appendices/mqtt_schema.md) - Python BLE scanner + MQTT publisher
- Buffering: [Communications Design](design/architecture/communications_design.md) - SQLite 7-day local storage

 HVAC
- Savings: [Testing README](testing/README.md) - 18.2% reduction (3,420 → 2,798 kWh)
- ROI: [Use Case and Constraints](design/requirements/use_case_and_constraints.md) - 17.3 months
- Integration: [Final Report](report/final_report.md) - Future work: BACnet control

 MQTT
- Topic Schema: [MQTT Schema](appendices/mqtt_schema.md) - Complete hierarchy, wildcards
- ACLs: [MQTT Schema](appendices/mqtt_schema.md) - AWS IoT Core policies (gateway/user/admin)
- QoS: [MQTT Schema](appendices/mqtt_schema.md) - QoS 1 for telemetry, QoS 0 for status

 OTA (Over-The-Air Updates)
- Flow: [OTA Updates](appendices/ota_updates.md) - 5-phase sequence diagrams
- Security: [OTA Updates](appendices/ota_updates.md) - RSA-2048 signatures, anti-rollback
- Testing: [OTA Updates](appendices/ota_updates.md) - 6 test cases (happy path, rollback, etc.)

 Power
- Budget: [Power Budget](appendices/power_budget.md) - 48 µA average, 2.4-year lifetime
- Optimization: [Power Budget](appendices/power_budget.md) - 2× AA failed → 3× AA solution
- Testing: [Test Plan](testing/test_plan.md) - Power consumption tests (5 tests, all )

 Security
- Threat Model: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 14 threats
- Audit: [Testing README](testing/README.md) - Acme Security Ltd (8-9 Jan 2026, Zero P0/P1)
- Testing: [Test Plan](testing/test_plan.md) - Device, network, penetration tests

 STM32WB55
- Selection: [Decision Matrices](design/requirements/decision_matrices.md) - 4.89/5.0 score
- Configuration: [Hardware Design](design/architecture/hardware_design.md) - Standby 0.6 µA, dual-bank Flash
- Firmware: [Firmware Architecture](design/architecture/firmware_architecture.md) - CubeMX config, FreeRTOS

 Sustainability
- Carbon: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 7.17 kg avoided
- Payback: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 6 months
- Recycling: [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 70% by weight

 Testing
- Plan: [Test Plan](testing/test_plan.md) - 92 tests across 6 categories
- Results: [Testing README](testing/README.md) - 98% pass rate, 4-week pilot
- Metrics: [Testing README](testing/README.md) - All constraints met ()

---

 By Technical Domain

 Electrical Engineering
1. [Hardware Design](design/architecture/hardware_design.md) - Schematic, PCB layout
2. [Power Budget](appendices/power_budget.md) - Power analysis, battery selection
3. [Test Plan](testing/test_plan.md) - Power consumption tests, EMC pre-compliance

 Computer Science / Embedded Systems
1. [Firmware Architecture](design/architecture/firmware_architecture.md) - RTOS, task scheduling
2. [OTA Updates](appendices/ota_updates.md) - Bootloader, cryptography (RSA-2048)
3. [Communications Design](design/architecture/communications_design.md) - BLE stack, protocols

 Cloud Computing / DevOps
1. [Cloud Architecture](design/architecture/cloud_architecture.md) - AWS services, serverless
2. [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - FinOps, scaling strategies
3. [MQTT Schema](appendices/mqtt_schema.md) - Pub/sub messaging, ACLs

 Software Engineering / Web Development
1. [Mobile App Design](design/architecture/mobile_app_design.md) - React, React Native, UX
2. [Test Plan](testing/test_plan.md) - UAT, accessibility (WCAG 2.1 AA)

 Cybersecurity
1. [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - Threat modeling
2. [OTA Updates](appendices/ota_updates.md) - Secure boot, signature verification
3. [MQTT Schema](appendices/mqtt_schema.md) - TLS 1.2, X.509 certificates, ACLs

 Environmental Science / Sustainability
1. [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - LCA, carbon footprint
2. [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - Energy efficiency, PUE

 Business / Project Management
1. [Use Case and Constraints](design/requirements/use_case_and_constraints.md) - ROI, stakeholders
2. [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - SaaS model, break-even (76 customers)
3. [Testing README](testing/README.md) - KPIs, pilot results

---

 Reading Orders by Role

 Academic Assessor
1. [Final Report](report/final_report.md) - 8 min 2. [Use Case and Constraints](design/requirements/use_case_and_constraints.md) - 12 min (validate requirements)
3. [Decision Matrices](design/requirements/decision_matrices.md) - 18 min (check research rigor)
4. [Testing README](testing/README.md) - 10 min (pilot results)
5. Any appendix for deep-dive validation (as needed)

 Hardware Engineer
1. [Hardware Design](design/architecture/hardware_design.md) - 15 min
2. [Power Budget](appendices/power_budget.md) - 75 min
3. [Test Plan](testing/test_plan.md) - Device hardware section (20 min)
4. [Decision Matrices](design/requirements/decision_matrices.md) - Component justifications (18 min)

 Firmware Engineer
1. [Firmware Architecture](design/architecture/firmware_architecture.md) - 15 min
2. [OTA Updates](appendices/ota_updates.md) - 60 min
3. [Communications Design](design/architecture/communications_design.md) - BLE protocol (15 min)
4. [Test Plan](testing/test_plan.md) - Firmware section (20 min)

 Cloud Architect
1. [Cloud Architecture](design/architecture/cloud_architecture.md) - 20 min
2. [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - 40 min
3. [MQTT Schema](appendices/mqtt_schema.md) - 50 min
4. [Test Plan](testing/test_plan.md) - Cloud section (15 min)

 DevOps / SRE
1. [Communications Design](design/architecture/communications_design.md) - Gateway setup (15 min)
2. [MQTT Schema](appendices/mqtt_schema.md) - Topics, ACLs, monitoring (50 min)
3. [Cloud Architecture](design/architecture/cloud_architecture.md) - AWS services (20 min)
4. [Test Plan](testing/test_plan.md) - Reliability tests (10 min)

 Frontend Developer
1. [Mobile App Design](design/architecture/mobile_app_design.md) - 18 min
2. [Cloud Architecture](design/architecture/cloud_architecture.md) - API Gateway section (10 min)
3. [Test Plan](testing/test_plan.md) - UAT section (15 min)

 Security Analyst
1. [Security Privacy Sustainability](design/implementation/security_privacy_sustainability.md) - 22 min
2. [OTA Updates](appendices/ota_updates.md) - Security controls (30 min)
3. [MQTT Schema](appendices/mqtt_schema.md) - ACLs, TLS config (25 min)
4. [Testing README](testing/README.md) - Security audit results (10 min)

 Product Manager
1. [Final Report](report/final_report.md) - Executive summary (8 min)
2. [Use Case and Constraints](design/requirements/use_case_and_constraints.md) - Business case (12 min)
3. [Cloud Cost Analysis](appendices/cloud_cost_analysis.md) - SaaS model (20 min)
4. [Testing README](testing/README.md) - KPIs, ROI (10 min)

---

 External References Index

 Standards & Specifications
- MQTT v5.0: https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html
- BLE 5.2: Bluetooth SIG Core Specification v5.2
- TLS 1.2: IETF RFC 5246
- GDPR: Regulation (EU) 2016/679
- ASHRAE 62.1: Ventilation for Acceptable Indoor Air Quality

 Datasheets
- STM32WB55: https://www.st.com/resource/en/datasheet/stm32wb55rg.pdf
- Sensirion SCD40: https://www.sensirion.com/media/documents/48C4B7FB/64C134E7/Sensirion_SCD4x_Datasheet.pdf
- Panasonic EKMB PIR: EKMB1101111 Datasheet
- TI TPS62840: SLVSEC3C Datasheet
- Energizer L91: Ultimate Lithium AA Technical Datasheet

 Cloud Documentation
- AWS IoT Core: https://docs.aws.amazon.com/iot/
- Amazon Timestream: https://docs.aws.amazon.com/timestream/
- AWS Lambda: https://docs.aws.amazon.com/lambda/
- Amazon API Gateway: https://docs.aws.amazon.com/apigateway/

 Academic Papers
- Allen et al., "Associations of cognitive function scores with carbon dioxide" (Harvard, 2016)
- ASHRAE Handbook: HVAC Applications, Chapter 49 (2023)

---

Last Updated: January 14, 2026  
Index Version: 1.0 (Post-Refactoring)  
Total Documents: 14 technical docs + 5 README guides + 5 root guides (QUICKSTART, INDEX, GLOSSARY, CHANGELOG, PROJECT_STRUCTURE) = 24 files  
Total Words: ~100,000 across all documents
