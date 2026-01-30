 Glossary

Definitions and acronyms used across the IoT MVP documentation. Use this page for quick lookup; design docs give full context.

---

 Acronyms

| Term | Meaning | Where used |
|------|---------|------------|
| ACL | Access Control List | MQTT topics, AWS IoT Core policies |
| ASC | Automatic Self-Calibration | Sensirion SCD40 CO₂ sensor |
| BACnet | Building Automation and Control Networks | Future work: BMS integration |
| BLE | Bluetooth Low Energy | Device–gateway communication (BLE 5.2) |
| BOM | Bill of Materials | Device cost (£35 target &lt; £50) |
| BMS | Building Management System | HVAC, lighting, access control |
| CO₂ | Carbon dioxide | Primary IAQ metric (ppm) |
| CSRF | Cross-Site Request Forgery | Security testing (OWASP) |
| DPIA | Data Protection Impact Assessment | GDPR, privacy |
| E2E | End-to-end | Latency, testing |
| EMC | Electromagnetic Compatibility | CE marking, pre-compliance |
| GDPR | General Data Protection Regulation (EU 2016/679) | Privacy, data minimization |
| GATT | Generic Attribute Profile | BLE services/characteristics |
| HVAC | Heating, Ventilation, and Air Conditioning | Energy savings, ROI |
| IAQ | Indoor Air Quality | CO₂, ASHRAE 62.1 |
| IoT | Internet of Things | System domain |
| MCU | Microcontroller Unit | STM32WB55 |
| MITM | Man-in-the-Middle | Security (TLS mitigates) |
| MQTT | Message Queuing Telemetry Transport (OASIS v5.0) | Gateway–cloud messaging |
| NDIR | Non-Dispersive Infrared | CO₂ sensing (SCD40) |
| OTA | Over-The-Air | Firmware updates (dual-bank, RSA-2048) |
| OTP | One-Time Programmable | Fuses (anti-rollback) |
| OWASP | Open Web Application Security Project | Penetration testing (Top 10) |
| PIR | Passive Infrared | Occupancy (Panasonic EKMB) |
| PUE | Power Usage Effectiveness | Data centre efficiency (AWS) |
| QoS | Quality of Service | MQTT (0, 1, 2) |
| RED | Radio Equipment Directive | CE, wireless compliance |
| ROI | Return on Investment | Payback (17.3 months) |
| RTC | Real-Time Clock | Wake scheduling |
| SLA | Service Level Agreement | AWS 99.9% |
| SUS | System Usability Scale | User satisfaction (72) |
| TCO | Total Cost of Ownership | Cloud vs on-premise |
| TLS | Transport Layer Security | TLS 1.2 (gateway–cloud) |
| UAT | User Acceptance Testing | Facilities manager acceptance |
| WEEE | Waste Electrical and Electronic Equipment | Recycling, 70% by weight |
| WCAG | Web Content Accessibility Guidelines | 2.1 AA (dashboard/mobile) |
| XSS | Cross-Site Scripting | Security testing (OWASP) |

---

 Key Terms

| Term | Definition | Reference doc |
|------|------------|---------------|
| Adaptive sampling | 10 min (occupied) / 20–25 min (vacant) measurement interval to save battery | [Hardware Design](design/architecture/hardware_design.md), [Power Budget](appendices/power_budget.md) |
| Carbon payback | Time until operational carbon saved exceeds embodied carbon (6 months) | [Security & Sustainability](design/implementation/security_privacy_sustainability.md) |
| Dual-bank flash | MCU flash split into Bank A (active) and Bank B (staging) for safe OTA | [Firmware Architecture](design/architecture/firmware_architecture.md), [OTA Updates](appendices/ota_updates.md) |
| Connection-less BLE | Advertisements only (no persistent connection); ~10 µJ/msg | [Communications Design](design/architecture/communications_design.md) |
| Gateway | Raspberry Pi 4: BLE scanner → MQTT publisher, 7-day SQLite buffer | [Communications Design](design/architecture/communications_design.md) |
| MVP | Minimum Viable Product – scope for university assessment and pilot | [Use Case](design/requirements/use_case_and_constraints.md) |
| Telemetry | Sensor payload: CO₂, temperature, humidity, occupancy, battery | [MQTT Schema](appendices/mqtt_schema.md) |
| Threat model | 14 threats across BLE, MQTT, API, physical; controls and residual risk | [Security & Sustainability](design/implementation/security_privacy_sustainability.md) |

---

 Standards & Specifications

| Standard | Scope | Use in project |
|----------|--------|-----------------|
| ASHRAE 62.1 | Ventilation and IAQ | CO₂ &lt;1000 ppm during occupied hours |
| BLE 5.2 | Bluetooth SIG Core Specification | Device–gateway radio |
| GDPR Art. 25 | Data protection by design | No personal data from sensors |
| MQTT v5.0 | OASIS | Gateway–cloud messaging |
| TLS 1.2 | IETF RFC 5246 | Encryption (gateway–cloud) |
| WCAG 2.1 AA | Accessibility | Dashboard and mobile (4.5:1 contrast, 44×44 px targets) |

---

 Document References

- Requirements: [design/requirements/](design/requirements/)
- Architecture: [design/architecture/](design/architecture/)
- Implementation: [design/implementation/](design/implementation/)
- Testing: [testing/](testing/)
- Appendices: [appendices/](appendices/)
- Full index: [INDEX.md](INDEX.md)

---

Last updated: January 2026 · Part of IoT MVP documentation v1.1
