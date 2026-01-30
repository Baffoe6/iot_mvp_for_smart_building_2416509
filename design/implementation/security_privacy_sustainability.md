 Security, Privacy, Ethics, and Sustainability

 Overview

This section addresses non-functional requirements critical for academic assessment and real-world deployment: threat modeling, GDPR compliance, ethical considerations, and environmental sustainability.

---

 1. Security Threat Model

 Assets

| Asset | Sensitivity | Impact if Compromised |
|-------|-------------|----------------------|
| Sensor telemetry data (CO₂, temp, RH) | Low | Public information; minimal privacy risk |
| Occupancy data (presence/absence) | Medium | Aggregated occupancy acceptable; individual tracking would violate privacy |
| Device firmware | High | Malicious firmware could brick devices, exfiltrate data, drain batteries |
| Cloud credentials (X.509 certs, API keys) | Critical | Full system compromise; data manipulation, DoS, cost escalation |
| User accounts (facilities manager) | High | Unauthorized alerts, misconfiguration, false energy reports |

 Threat Actors

| Actor | Motivation | Capability | Likelihood |
|-------|------------|------------|------------|
| Curious insider | Curiosity, learning | Low (basic tools) | Medium |
| Malicious insider | Sabotage, theft | Medium (physical access to devices/gateways) | Low |
| External attacker (opportunistic) | Bot scanning, crypto mining | Low (automated tools) | High |
| External attacker (targeted) | Espionage, ransom | High (APT-level) | Very Low |
| Supply chain compromise | Nation-state, organized crime | Very High | Very Low (use reputable vendors) |

 Attack Surfaces

1. BLE radio (device ↔ gateway)
2. MQTT over TLS (gateway ↔ cloud)
3. REST API (dashboard/mobile app ↔ cloud)
4. Physical access (device tampering, gateway theft)
5. Firmware supply chain (malicious OTA update)

---

 2. Security Controls

 2.1 Device-to-Gateway (BLE)

Threats:
- T1: Eavesdropping on BLE advertisements (sniffing sensor data)
- T2: Rogue gateway impersonation (fake OTA updates)
- T3: Replay attack (rebroadcast old sensor readings)

Controls:

| Threat | Control | Implementation | Residual Risk |
|--------|---------|----------------|---------------|
| T1 | Accepted (data not sensitive) | Connection-less BLE inherently broadcasts | Low |
| T2 | BLE bonding + whitelist | Device only connects to bonded gateway MAC addresses | Low |
| T2 | OTA signature verification | RSA-2048 signed firmware, public key in bootloader | Very Low |
| T3 | Timestamp validation | Gateway rejects messages >5 min old or in future | Low |

Additional measure: If personal data were present (NOT in this design), encrypt advertisement payload with AES-128-CCM using shared key established during provisioning.

 2.2 Gateway-to-Cloud (MQTT/TLS)

Threats:
- T4: Man-in-the-middle (MITM) on MQTT traffic
- T5: Stolen gateway certificate (device impersonation)
- T6: Denial of service (flood broker with messages)

Controls:

| Threat | Control | Implementation | Residual Risk |
|--------|---------|----------------|---------------|
| T4 | TLS 1.2 with mutual authentication | Gateway and broker verify X.509 certificates | Very Low |
| T4 | Certificate pinning | Gateway trusts only AWS IoT Root CA (not all CAs) | Very Low |
| T5 | Certificate rotation | Auto-rotate 30 days before expiry (1-year validity) | Low |
| T5 | Certificate revocation | Immediate revocation via AWS IoT console if theft suspected | Low |
| T6 | Rate limiting | AWS IoT Core limits: 100 msg/sec per device (far exceeds normal 0.1 msg/sec) | Low |
| T6 | IoT policy restrictions | Gateway can only publish to its own topic hierarchy | Low |

TLS Configuration:
```
Protocol: TLS 1.2 (minimum), TLS 1.3 (preferred)
Cipher suites (ordered):
  1. TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (PFS, strong)
  2. TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (PFS, efficient)
  3. TLS_RSA_WITH_AES_256_GCM_SHA384 (fallback, no PFS)
Certificate: RSA-2048 or ECDSA P-256 (device), RSA-4096 (AWS CA)
```

 2.3 Cloud Services (API Gateway, Lambda, Timestream)

Threats:
- T7: Unauthorized API access (dashboard/mobile app)
- T8: Privilege escalation (user accesses other buildings' data)
- T9: SQL injection (malicious queries to Timestream)
- T10: Data exfiltration (bulk download of historical data)

Controls:

| Threat | Control | Implementation | Residual Risk |
|--------|---------|----------------|---------------|
| T7 | JWT authentication | AWS Cognito issues signed tokens (1-hour expiry) | Low |
| T7 | MFA enforcement | TOTP or SMS required for facilities manager login | Low |
| T8 | Attribute-based access control (ABAC) | JWT `building_id` claim enforced by Lambda authorizer | Low |
| T8 | Least privilege IAM roles | Lambda can only query Timestream, not modify | Very Low |
| T9 | Parameterized queries | Never concatenate user input into SQL (use bind parameters) | Very Low |
| T10 | Rate limiting | API Gateway: 1000 req/min per user, 10,000/day total | Low |
| T10 | CloudWatch alarms | Alert on unusual query patterns (>100 queries in 5 min) | Low |

Example JWT token (after authentication):
```json
{
  "sub": "sarah.jones@buildinga.com",
  "building_id": "BuildingA",
  "role": "facilities_manager",
  "exp": 1673456789,
  "iat": 1673453189
}
```

Lambda authorizer logic:
```python
def authorize(event):
    token = extract_jwt(event['headers']['Authorization'])
    user = cognito.verify_token(token)   Validates signature, expiry
    
     Extract building_id from API path
    requested_building = event['pathParameters']['building_id']
    
     Enforce: user can only access their own building
    if user['building_id'] != requested_building:
        return {"statusCode": 403, "body": "Forbidden"}
    
    return {"statusCode": 200, "principalId": user['sub']}
```

 2.4 Physical Security

Threats:
- T11: Device theft or tampering (extract keys, implant malware)
- T12: Gateway theft (extract X.509 certificate, replay messages)

Controls:

| Threat | Control | Implementation | Residual Risk |
|--------|---------|----------------|---------------|
| T11 | Tamper-evident enclosure | Sticker seal over battery compartment (visually inspectable) | Medium |
| T11 | No secrets in device | Private keys never stored; public key only (for OTA verification) | Low |
| T11 | Remote disable | Facilities manager can deactivate device via cloud (revoke cert) | Low |
| T12 | Gateway in locked room | IDF/comms room access restricted to authorized personnel | Medium |
| T12 | Certificate stored in TPM | Raspberry Pi Compute Module 4 with optional TPM 2.0 module | Low (if TPM used) |
| T12 | Remote wipe | SSH access to gateway, can remotely delete certificates if theft detected | Medium |

Note: For MVP, accept residual risk of physical theft (low probability in controlled office environment). Production deployment should use TPM for certificate storage.

 2.5 Firmware Supply Chain

Threats:
- T13: Malicious firmware update (backdoor, ransomware)
- T14: Compromised build server (inject malware during compilation)

Controls:

| Threat | Control | Implementation | Residual Risk |
|--------|---------|----------------|---------------|
| T13 | RSA-2048 code signing | Firmware signed with private key (offline, HSM-protected) | Very Low |
| T13 | Dual-bank flash + rollback | Bootloader auto-reverts if new firmware fails self-test | Very Low |
| T14 | Build reproducibility | Deterministic builds (same source → same binary hash) | Low |
| T14 | CI/CD pipeline hardening | GitHub Actions with signed commits, audit logs | Low |
| T14 | Multi-party signing | Require 2-of-3 signatures (dev, QA, release manager) for production firmware | Very Low |

Code signing process:
1. Developer commits code to Git (signed with GPG key)
2. CI/CD (GitHub Actions) compiles firmware
3. Binary uploaded to staging S3 bucket
4. Release manager reviews, downloads binary
5. Release manager signs with offline HSM: `openssl dgst -sha256 -sign private.pem firmware.bin > signature.sig`
6. Signed firmware + signature uploaded to production S3
7. Gateway downloads, device verifies before flashing

---

 3. Privacy and GDPR Compliance

 3.1 Data Protection Principles

Lawful basis: Legitimate interest (building operations, energy efficiency)

GDPR Principles Applied:

| Principle | Implementation | Evidence |
|-----------|----------------|----------|
| Lawfulness, fairness, transparency | Privacy notice displayed during device installation; data use explained | Privacy notice document |
| Purpose limitation | Data used ONLY for building management; no secondary use (e.g., no selling to advertisers) | Data processing agreement |
| Data minimization | Collect ONLY occupancy presence/absence (not identity); no cameras, no MAC tracking | System design |
| Accuracy | Sensor calibration (ASC for CO₂); data validated before storage (range checks) | Firmware logic |
| Storage limitation | Telemetry deleted after 2 years (warm storage); logs deleted after 30 days | Timestream lifecycle policy |
| Integrity and confidentiality | TLS encryption in transit; IAM access control at rest | AWS security controls |
| Accountability | Data processing impact assessment (DPIA); audit logs; this document | DPIA, CloudWatch Logs |

 3.2 Personal Data Assessment

Question: Does this system process personal data per GDPR Article 4?

Analysis:

| Data Type | Personal Data? | Rationale |
|-----------|---------------|-----------|
| CO₂, temperature, humidity | No | Environmental metrics, not linked to individuals |
| Occupancy (presence/absence) | No | Binary flag (room occupied/vacant), no identity |
| Occupancy (count: 3 people) | Possibly | If combined with calendar (meeting attendees), could infer identity → Design avoids counting |
| Device MAC address (BLE) | No | Device identifier, not person identifier; building-owned devices |
| Facilities manager email | Yes | Email is personal data (AWS Cognito user account) |
| Alert notification history | No | Linked to room, not person; facilities manager is data processor, not subject |

Conclusion: System processes minimal personal data (only facilities manager account, which is essential for access control). Sensor data is not personal data under GDPR.

 3.3 Data Subject Rights (Facilities Manager)

Under GDPR, facilities manager has rights:

| Right | Mechanism | Response Time |
|-------|-----------|---------------|
| Right to access (Art. 15) | API endpoint `/user/data` returns all user data (email, login history, alert acknowledgments) | <1 month |
| Right to rectification (Art. 16) | AWS Cognito user profile editing (email, name) | Immediate |
| Right to erasure (Art. 17) | Account deletion via AWS Cognito; anonymize logs (replace email with hash) | <1 month |
| Right to restrict processing (Art. 18) | Suspend account (disable login) without deletion | Immediate |
| Right to data portability (Art. 20) | Export user data as JSON via API | <1 month |

Note: Building occupants (office workers) are not data subjects in this system; no personal data collected about them.

 3.4 Data Protection Impact Assessment (DPIA)

Required? No (per GDPR Article 35, not required if no high-risk processing of personal data).

Optional DPIA conducted anyway (best practice):

Risk 1: Re-identification via occupancy patterns
- Likelihood: Low (binary occupancy, not linked to calendar or badge systems)
- Impact: Medium (if re-identified: privacy violation, GDPR breach)
- Mitigation: Design explicitly avoids counting people; no integration with identity systems
- Residual risk: Low

Risk 2: Unauthorized access to facilities manager account
- Likelihood: Medium (phishing, password reuse)
- Impact: Medium (access to building data, but no personal data)
- Mitigation: MFA enforcement, password complexity requirements, session timeout (1 hour)
- Residual risk: Low

Overall DPIA conclusion: System is low-risk from privacy perspective. No high-risk processing identified.

---

 4. Ethics and Responsible Innovation

 4.1 Ethical Principles

Autonomy: Building occupants are not monitored as individuals; system respects privacy by design (no cameras, no identity tracking).

Beneficence: System aims to improve indoor air quality (health benefit) and reduce energy consumption (environmental benefit).

Non-maleficence: System avoids harm:
- No surveillance (binary occupancy only)
- No discriminatory use (data not used for employee performance tracking)
- No "creep" toward invasive monitoring (design explicitly prevents identity tracking)

Justice: System benefits all building occupants equally (improved air quality in all monitored rooms).

 4.2 Stakeholder Engagement

Transparency measures:
- Privacy notice posted in each room with sensor: "This room is monitored for CO₂, temperature, and occupancy (presence/absence only, not identity). Data used for building management and energy efficiency. Questions? Contact facilities@buildinga.com"
- Facilities manager training: Explain what data is collected, what is NOT collected (no cameras, no identity), how data is secured
- Annual report: Share energy savings and air quality improvements with all building occupants (demonstrates value, builds trust)

Opt-out? Not applicable (building operations, not personal data collection). Occupants cannot opt out of CO₂ monitoring (analogous to fire alarm or HVAC system—essential building infrastructure).

 4.3 Avoiding Function Creep

Scenario: Management requests to add facial recognition to identify occupants (e.g., for access control or productivity tracking).

Ethical response:
1. Refuse: This violates privacy-by-design principle
2. Explain: Adding identity tracking transforms system from low-risk to high-risk (DPIA would be required, consent likely needed, GDPR scrutiny)
3. Propose alternatives: If access control needed, use separate badge system (not integrated with IoT sensors)

Contractual protection: Data processing agreement specifies: "Sensor data shall be used ONLY for building environmental management. Addition of identity-tracking features requires new contract and DPIA."

---

 5. Sustainability and Environmental Impact

 5.1 Energy Consumption Analysis

Device Energy (per device, per year):
- Sensor + MCU: 6.82 Wh/year (from power budget calculation)
- BLE radio: included in above
- Total device: 6.82 Wh/year

Gateway Energy (per gateway, 20 devices):
- Raspberry Pi 4: 6W × 24h × 365d = 52.6 kWh/year
- Per device share: 52.6 / 20 = 2.63 kWh/year/device

Cloud Energy (per device, per year):
- AWS IoT Core + Timestream + Lambda: ~10 Wh/year/device (estimated based on AWS carbon footprint reports, eu-west-1 region)
- 0.01 kWh/year/device

Total energy consumption per device per year:
- Device: 0.00682 kWh
- Gateway: 2.63 kWh
- Cloud: 0.01 kWh
- Total: 2.65 kWh/year/device

 5.2 Carbon Footprint

UK grid carbon intensity (2025 average): 180 g CO₂e/kWh (declining due to renewables)

Device lifetime carbon (2.4 years):
- Operational: 2.65 kWh/yr × 2.4 yr × 180 g/kWh = 1,145 g CO₂e (1.15 kg)
- Manufacturing (embodied carbon):
  - Sensors, PCB, enclosure: ~500 g CO₂e (estimated based on similar electronics)
  - Battery (3× AA lithium): ~200 g CO₂e
  - Shipping (China → UK): ~50 g CO₂e
  - Total embodied: 750 g CO₂e
- Total lifecycle: 1,145 + 750 = 1,895 g CO₂e (1.9 kg per device over 2.4 years)

Energy savings enabled (per device, per year):
- HVAC energy reduction: 420 kWh/year (18% savings, from energy report)
- Per 20 devices: 420 kWh/year
- Per device: 420 / 20 = 21 kWh/year/device
- Carbon avoided: 21 kWh × 180 g/kWh = 3,780 g CO₂e/year/device (3.78 kg/year)

Net carbon impact (per device):
- Year 1: -1.9 kg (embodied) + 3.78 kg (savings) = +1.88 kg CO₂e avoided (carbon positive)
- Year 2: +3.78 kg (savings) = +3.78 kg CO₂e avoided
- Over 2.4-year lifetime: -1.9 + (3.78 × 2.4) = +7.17 kg CO₂e avoided per device

Payback period: 1.9 kg / 3.78 kg/yr = 0.5 years (6 months to offset embodied carbon)

 5.3 Sustainability Trade-Offs

| Decision | Energy Impact | Carbon Impact | Trade-Off Analysis |
|----------|---------------|---------------|-------------------|
| BLE vs. Wi-Fi | BLE: 10 µJ/msg, Wi-Fi: 1 mJ/msg (100× higher) | BLE enables 2-year battery → less frequent replacements → lower embodied carbon | BLE strongly preferred |
| Cloud vs. on-premise server | Cloud (AWS eu-west-1): 80% renewable, PUE 1.2 | On-premise: typical PUE 1.8, grid mix (not renewable unless specified) | Cloud greener (if renewable region) |
| 10-min vs. 5-min sampling | 10-min: 6.82 Wh/yr, 5-min: 13.6 Wh/yr (2× battery changes) | 2× battery production + shipping → 400 g CO₂e extra | 10-min preferred (adequate for use case) |
| Gateway: Raspberry Pi vs. ESP32 | RPi: 6W, ESP32: 0.5W (12× lower) | ESP32 lower operational carbon BUT RPi easier development → faster time-to-market | RPi for MVP, ESP32 for production (optimize later) |

 5.4 Circular Economy Principles

Design for longevity:
- Battery-powered (no hard-wired installation → easy relocation)
- Modular enclosure (replace battery without tools)
- OTA firmware updates (extend functional life without hardware changes)

Repairability:
- Standard AA batteries (user-replaceable, not soldered)
- 2-layer PCB with labeled test points (facilitates repair)
- No proprietary connectors or adhesives

End-of-life:
- PCB: WEEE-compliant (electronics recycling)
- Enclosure: ABS plastic recyclable (resin code 7)
- Batteries: Lithium primary cells recyclable via battery take-back programs
- Estimated recycling rate: 70% by weight (PCB + enclosure + batteries)

Extended Producer Responsibility (EPR):
- Device manufacturer responsible for take-back scheme
- Facilities manager contacts manufacturer at end-of-life → prepaid shipping label → device returned for refurbishment or recycling

 5.5 Sustainability Dossier (Summary Table)

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Energy consumption (device) | 6.82 Wh/year | <10 Wh/year |  Excellent |
| Energy consumption (system) | 2.65 kWh/year/device | <5 kWh/year/device |  Good |
| Embodied carbon (device) | 0.75 kg CO₂e | <1 kg CO₂e |  Good |
| Net carbon impact (2.4 years) | +7.17 kg CO₂e avoided | Carbon positive |  Excellent |
| Carbon payback period | 6 months | <1 year |  Excellent |
| Battery lifetime | 2.4 years | ≥2 years |  Target met |
| Recyclability | 70% by weight | >50% |  Good |
| Renewable energy (cloud) | 80% (AWS eu-west-1) | >50% |  Good |

---

 6. Regulatory Compliance Summary

| Regulation | Requirement | Compliance Status |
|------------|-------------|-------------------|
| GDPR | Lawful basis, data minimization, subject rights |  Compliant (no personal data from sensors) |
| UK Data Protection Act 2018 | Same as GDPR |  Compliant |
| ePrivacy Directive (cookie law) | Consent for tracking cookies |  N/A (no web cookies in MVP; dashboard uses JWT) |
| Radio Equipment Directive (RED 2014/53/EU) | CE marking, EMC, safety |  Compliant (BLE module pre-certified) |
| WEEE Directive (2012/19/EU) | Electronics recycling |  Compliant (EPR take-back scheme) |
| RoHS Directive (2011/65/EU) | Lead-free solder, hazardous substances |  Compliant (RoHS-certified components) |
| Battery Directive (2006/66/EC) | Battery labeling, recycling |  Compliant (user-replaceable, recycling info on enclosure) |

---

 Next Steps

See:
- `10_mvp_test_plan.md` for security testing procedures (penetration test, certificate validation)
- `Appendix_G_threat_model_detailed.md` for comprehensive attack trees and mitigations
- `Appendix_H_dpia.md` for full Data Protection Impact Assessment (if required for deployment)
