 MVP Test Plan

 Overview

This test plan defines acceptance criteria and validation procedures for the IoT MVP across functional, non-functional, security, and user acceptance dimensions.

---

 1. Functional Tests

 1.1 Device Hardware Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| FT-DH-01 | CO₂ sensor accuracy | ±50 ppm vs. calibrated reference (Vaisala GMP252) | Lab test, controlled chamber |
| FT-DH-02 | Temperature sensor accuracy | ±0.5°C vs. NIST-traceable thermometer | Lab test, thermal chamber |
| FT-DH-03 | PIR motion detection range | Detect movement at 5 m, 95% success rate | Field test, 20 trials |
| FT-DH-04 | PIR false positive rate | <5% false positives (no motion detected when vacant) | 24-hour continuous monitoring |
| FT-DH-05 | Battery voltage measurement | ±50 mV vs. multimeter | Bench test |
| FT-DH-06 | Enclosure IP rating | IP30 (dust >2.5 mm, no water ingress) | Visual inspection, water spray test |

 1.2 Firmware Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| FT-FW-01 | Sensor sampling interval | 10-min interval ±5 s (99% of cycles) | Power analyzer log, 7-day test |
| FT-FW-02 | Adaptive sampling (occupied) | Switch to 10-min when PIR active | Simulate motion, verify sampling rate change |
| FT-FW-03 | Adaptive sampling (vacant) | Switch to 20-min when PIR idle >30 min | Simulate no motion, verify rate change |
| FT-FW-04 | Alert threshold detection | Trigger alert when CO₂ >1200 ppm within 30 s | Manual threshold crossing, measure latency |
| FT-FW-05 | Watchdog timer | System reset if firmware hangs (30 s timeout) | Inject infinite loop, verify reset |
| FT-FW-06 | RTC wakeup accuracy | Wakeup within ±2 s of scheduled time | 100 wakeup cycles, measure drift |
| FT-FW-07 | Backup SRAM persistence | State retained across Standby mode | Power cycle, verify calibration data intact |

 1.3 BLE Communication Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| FT-BLE-01 | Advertisement transmission | BLE advertisement every 10 s ±1 s | BLE sniffer (nRF52840 DK), 1-hour capture |
| FT-BLE-02 | Advertisement payload integrity | CRC16 validates, no corruption | Parse 1000 advertisements, verify CRC |
| FT-BLE-03 | BLE range (indoor) | >95% packet delivery at 30 m through 2 office partitions | Signal strength test, 10 locations |
| FT-BLE-04 | Connection establishment | Gateway connects within 5 s of request | Manual connection test, 20 trials |
| FT-BLE-05 | GATT data transfer | Transfer 24× 100-byte readings in <10 s | Bulk data pull test |
| FT-BLE-06 | Pairing and bonding | Device pairs with gateway, rejects unknown devices | Pairing test, rogue device test |

 1.4 Gateway Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| FT-GW-01 | BLE scanning | Detect all 20 devices within 1 min of gateway boot | Field test, 20-device deployment |
| FT-GW-02 | MQTT publish success rate | >99.5% messages successfully published (QoS 1) | 7-day test, log PUBACK rates |
| FT-GW-03 | MQTT reconnect | Reconnect within 60 s of network outage | Unplug ethernet, measure reconnect time |
| FT-GW-04 | Local buffering | Store 7 days of data during offline period | Simulate 24-hour offline, verify no data loss |
| FT-GW-05 | TLS certificate validation | Reject connections to rogue broker (invalid cert) | MITM test with self-signed cert |
| FT-GW-06 | Gateway uptime | >99% uptime (excludes planned reboots) | 30-day continuous operation |

 1.5 Cloud and API Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| FT-CL-01 | MQTT message ingestion | All messages arrive in Timestream within 5 s | End-to-end latency test, 1000 messages |
| FT-CL-02 | IoT Rules Engine | Alerts trigger Lambda within 10 s of message arrival | Inject alert message, measure Lambda invocation time |
| FT-CL-03 | Timestream query performance | Dashboard queries return within 3 s (95th percentile) | Load test with Grafana k6, 100 concurrent users |
| FT-CL-04 | API authentication | JWT-authenticated requests succeed, unauthenticated fail (401) | Postman test suite, valid/invalid tokens |
| FT-CL-05 | API authorization | User can only access their building data (403 if wrong building_id) | Postman test, cross-building request |
| FT-CL-06 | SNS notification delivery | Email/SMS alerts delivered within 60 s of trigger | Alert injection test, measure delivery time |

---

 2. Non-Functional Tests

 2.1 Power Consumption Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| NFT-PW-01 | Average device current | <50 µA average (meets 2-year battery target) | Otii Arc power analyzer, 24-hour measurement |
| NFT-PW-02 | Standby current | <1 µA in Standby mode (RTC + backup SRAM) | Power analyzer, 10-minute measurement |
| NFT-PW-03 | CO₂ measurement current | <20 mA during 5-second measurement | Oscilloscope, capture current spike |
| NFT-PW-04 | BLE advertisement current | <15 mA peak during 1 ms transmission | Oscilloscope, high-speed capture |
| NFT-PW-05 | Battery lifetime (projected) | >2 years at 10-min sampling (accelerated test) | 1 min = 1 day time scaling, project to 2 years |

 2.2 Performance Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| NFT-PF-01 | End-to-end latency (routine) | Sensor reading → dashboard display <30 s (95th %ile) | Synchronized clocks, 100 samples |
| NFT-PF-02 | End-to-end latency (alert) | Alert event → mobile push notification <60 s (95th %ile) | Alert injection, measure to notification |
| NFT-PF-03 | Dashboard load time | Home screen loads in <5 s on 10 Mbps connection | Chrome DevTools, 10 trials |
| NFT-PF-04 | Mobile app responsiveness | Screen transitions <300 ms, no jank | React Native Performance Monitor |
| NFT-PF-05 | Concurrent user capacity | 50 concurrent dashboard users, API response <3 s | Load test (Grafana k6), ramp-up to 50 users |

 2.3 Reliability and Availability Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| NFT-RL-01 | Device MTBF | >2 years continuous operation without hardware failure | Pilot deployment, 10 devices × 4 weeks extrapolated |
| NFT-RL-02 | Gateway MTBF | >1 year continuous operation | 30-day test, no crashes or hangs |
| NFT-RL-03 | Cloud service availability | >99.5% uptime (AWS SLA) | Monitor AWS Health Dashboard, 30 days |
| NFT-RL-04 | Data loss rate | <0.1% messages lost (network issues, gateway offline) | Compare sent vs. received messages, 7-day test |
| NFT-RL-05 | OTA update success rate | >95% devices successfully update on first attempt | OTA test with 20 devices, measure success |

---

 3. Security Tests

 3.1 Device Security Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| ST-DV-01 | BLE eavesdropping | Attacker cannot decrypt sensor data (acceptable: plaintext, not sensitive) | BLE sniffer, parse advertisements |
| ST-DV-02 | Rogue gateway rejection | Device rejects connection from unpaired gateway | Attempt connection with unknown MAC address |
| ST-DV-03 | Firmware signature verification | Device rejects unsigned firmware (bootloader blocks flash) | Attempt OTA with unsigned binary |
| ST-DV-04 | Firmware rollback | Device auto-reverts to old firmware if new firmware fails self-test | Inject deliberately broken firmware, verify rollback |
| ST-DV-05 | Watchdog reset protection | Device resets after 30 s hang (no infinite loops) | Inject firmware hang, verify reset |

 3.2 Network Security Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| ST-NW-01 | MQTT TLS validation | Gateway rejects broker with invalid certificate | MITM attack with self-signed cert (should fail) |
| ST-NW-02 | MQTT authentication | Broker rejects connections without valid X.509 cert | Attempt connection without cert |
| ST-NW-03 | MQTT authorization (publish) | Gateway cannot publish to other gateways' topics | Attempt publish to `/building/BuildingB/...` (should fail with PUBACK error) |
| ST-NW-04 | API authentication bypass | Unauthenticated API requests return 401 Unauthorized | `curl` without JWT token |
| ST-NW-05 | API authorization bypass | User cannot access other buildings' data (403 Forbidden) | JWT with `building_id=BuildingA`, request `/buildings/BuildingB/rooms` |

 3.3 Penetration Testing

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| ST-PT-01 | SQL injection | API resistant to SQL injection in query parameters | OWASP ZAP scan, manual injection (`' OR '1'='1`) |
| ST-PT-02 | XSS (cross-site scripting) | Dashboard sanitizes user input (alert names, room names) | Inject `<script>alert('XSS')</script>` in config |
| ST-PT-03 | CSRF (cross-site request forgery) | API uses JWT (not cookies), immune to CSRF | Attempt CSRF attack from malicious site |
| ST-PT-04 | Rate limiting bypass | API rate limits enforced (1000 req/min per user) | Flood API with requests, verify 429 Too Many Requests |
| ST-PT-05 | Brute-force password attack | Cognito enforces account lockout after 5 failed logins | Attempt 10 failed logins, verify lockout |

---

 4. User Acceptance Tests (UAT)

 4.1 Facilities Manager (Primary User)

| Test ID | User Story | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| UAT-FM-01 | "As a facilities manager, I want to see all rooms at a glance" | Dashboard shows all 20 rooms with color-coded status within 5 s | User observation, 5 participants |
| UAT-FM-02 | "I want to drill down into a specific room's details" | Click room → Room Details page loads in <3 s | Task completion test |
| UAT-FM-03 | "I want to receive alerts when CO₂ is high" | Push notification arrives within 60 s of threshold crossing | Simulated alert, user confirms receipt |
| UAT-FM-04 | "I want to acknowledge an alert after taking action" | Click "Acknowledge" → Alert moves to "Resolved" section | Task completion test |
| UAT-FM-05 | "I want to see energy savings reports monthly" | Navigate to Energy tab → See £126 saved this month | User observation, verify comprehension |
| UAT-FM-06 | "I want to configure alert thresholds per room" | Click "Configure Thresholds" → Modal opens, adjust CO₂ limit, save → Device receives new config within 5 min | End-to-end config test |

 4.2 Usability Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| UAT-UX-01 | Dashboard navigation (first-time user) | User finds Room Details without assistance within 60 s | Moderated usability test, 5 participants |
| UAT-UX-02 | Mobile app alert response | User taps push notification → Room Details loads within 5 s | Task completion, 5 participants |
| UAT-UX-03 | Color-blind accessibility | Users with color blindness can distinguish room statuses (icons + text, not color alone) | Test with Chromatic Vision Simulator |
| UAT-UX-04 | Screen reader compatibility | VoiceOver (iOS) / TalkBack (Android) users can navigate mobile app | Assistive technology test, 2 participants |
| UAT-UX-05 | Error recovery | User receives helpful error message if API unavailable ("Service temporarily unavailable, try again in 1 minute") | Simulate API 503 error, user feedback |

---

 5. Environmental and Compliance Tests

 5.1 Environmental Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| ENV-01 | Operating temperature range | Device functions correctly at 15-25°C | Thermal chamber, 3-hour soak at each temperature |
| ENV-02 | Storage temperature range | No damage after storage at -10 to +50°C | Thermal cycling, visual inspection + functional test |
| ENV-03 | Humidity tolerance | Device functions at 60% RH (non-condensing) | Humidity chamber, 24-hour test |
| ENV-04 | Drop test | Device survives 1 m drop onto concrete (5 samples, 3 orientations each) | Drop test jig, functional test after |
| ENV-05 | Vibration test | Device survives 30 min @ 5 Hz, 1 G (shipping vibration) | Vibration table, IEC 60068-2-6 |

 5.2 Compliance Tests

| Test ID | Test Case | Acceptance Criteria | Method |
|---------|-----------|---------------------|--------|
| CMP-01 | CE marking (RED 2014/53/EU) | BLE module pre-certified; system-level EMC test pass | EMC lab test (radiated emissions, immunity) |
| CMP-02 | RoHS compliance | No lead, mercury, cadmium above limits | X-ray fluorescence (XRF) scan of PCB |
| CMP-03 | WEEE compliance | Device labeled with "crossed-out wheeled bin" symbol | Visual inspection |
| CMP-04 | Battery safety | No overcharge, overcurrent, or thermal runaway | Abuse testing (short circuit, overcharge) |
| CMP-05 | GDPR compliance | Privacy notice displayed, no personal data collected from sensors | Legal review, data flow audit |

---

 6. Test Execution Summary

 Test Phases

| Phase | Duration | Participants | Location | Success Criteria |
|-------|----------|--------------|----------|------------------|
| Phase 1: Lab tests | 2 weeks | Engineering team (3) | University lab | All FT-DH, FT-FW, NFT-PW tests pass |
| Phase 2: Integration tests | 1 week | Engineering + IT (5) | Test network | All FT-BLE, FT-GW, FT-CL tests pass |
| Phase 3: Field pilot | 4 weeks | Facilities manager + 10 office workers | Building A, Floor 2 | All UAT tests pass, <5 critical bugs |
| Phase 4: Security audit | 1 week | External pen-test firm | Remote | All ST tests pass, no P1/P2 vulnerabilities |
| Phase 5: UAT and signoff | 1 week | Facilities manager + building owner | Building A | User satisfaction >4/5, energy savings target met |

 Bug Severity Classification

| Severity | Definition | Example | Response Time |
|----------|------------|---------|---------------|
| P0 (Critical) | System unusable, data loss, security breach | Gateway loses all buffered data after power cycle | <4 hours |
| P1 (High) | Major feature broken, no workaround | Dashboard does not load alerts | <1 day |
| P2 (Medium) | Feature impaired, workaround exists | Chart Y-axis scale incorrect (data still visible) | <1 week |
| P3 (Low) | Minor issue, cosmetic | Button color contrast slightly low (still readable) | Backlog |

 Acceptance Criteria (Overall MVP)

 Functional: All P0 and P1 bugs resolved; <3 P2 bugs remaining
 Performance: 95th percentile end-to-end latency <30 s; dashboard loads <5 s
 Power: Average device current <50 µA; projected battery life >2 years
 Reliability: >99% message delivery; >99.5% gateway uptime
 Security: No critical or high vulnerabilities; TLS enforced; firmware signatures verified
 Usability: >4/5 user satisfaction (SUS score >68); no accessibility blockers
 Business: Demonstrate 15% HVAC energy savings in 4-week pilot; ROI <18 months

---

 7. Test Deliverables

1. Test report (this document + results)
2. Bug tracking sheet (JIRA or Excel with P0-P3 bugs, status, assignee)
3. Power consumption data (Otii Arc logs, CSV export)
4. Security audit report (pen-test findings, remediation plan)
5. User feedback summary (UAT session notes, satisfaction scores, quotes)
6. Pilot deployment report (4-week summary: uptime, energy savings, alert counts)

---

 Next Steps

See:
- `11_report_introduction.md` for report-ready prose (Introduction section)
- `12_report_literature_review.md` for report-ready prose (Literature Review section)
- `13_report_design.md` for report-ready prose (Design section, 1,500 words)
