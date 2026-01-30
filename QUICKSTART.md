 Quick Start

Choose your path to get the most from the IoT MVP documentation in under 15 minutes.

---

 I need to…

 Submit the assessment
1. Read [report/final_report.md](report/final_report.md) (≈8 min) – main submission.
2. Check [report/README.md](report/README.md) – submission checklist and criteria mapping.
3. Convert to PDF if required; keep the full `iot_mvp` folder for viva/supporting evidence.

 Understand the system in one pass
1. [README.md](README.md) – overview, specs, validated results (≈10 min).
2. [design/requirements/use_case_and_constraints.md](design/requirements/use_case_and_constraints.md) – problem, constraints, success metrics (≈12 min).
3. [design/architecture/hardware_design.md](design/architecture/hardware_design.md) → [communications_design.md](design/architecture/communications_design.md) → [cloud_architecture.md](design/architecture/cloud_architecture.md) – data flow (≈30 min).
4. [testing/README.md](testing/README.md) – pilot results and security audit (≈10 min).

 Implement hardware
1. [design/architecture/hardware_design.md](design/architecture/hardware_design.md) – schematic, BOM (£35), power budget.
2. [appendices/power_budget.md](appendices/power_budget.md) – detailed power calculations and validation.
3. [testing/test_plan.md](testing/test_plan.md) – Device Hardware and Power sections.

 Implement firmware
1. [design/architecture/firmware_architecture.md](design/architecture/firmware_architecture.md) – FreeRTOS tasks, OTA overview.
2. [appendices/ota_updates.md](appendices/ota_updates.md) – OTA flow, dual-bank, RSA-2048.
3. [design/architecture/communications_design.md](design/architecture/communications_design.md) – BLE and gateway interface.

 Implement gateway or cloud
1. [design/architecture/communications_design.md](design/architecture/communications_design.md) – BLE scanning, MQTT, 7-day buffer.
2. [appendices/mqtt_schema.md](appendices/mqtt_schema.md) – topics, payloads, ACLs.
3. [design/architecture/cloud_architecture.md](design/architecture/cloud_architecture.md) – AWS services.
4. [appendices/cloud_cost_analysis.md](appendices/cloud_cost_analysis.md) – costs and scaling.

 Check security or compliance
1. [design/implementation/security_privacy_sustainability.md](design/implementation/security_privacy_sustainability.md) – threats, GDPR, sustainability.
2. [testing/README.md](testing/README.md) – security audit (Zero P0/P1) and test summary.

 Find something by topic
Use [INDEX.md](INDEX.md) – alphabetical list, topical index, keyword search, and role-based reading orders.

 Look up an acronym or term
Use [GLOSSARY.md](GLOSSARY.md) – BLE, MQTT, OTA, HVAC, IAQ, GDPR, etc.

---

 By role (≈15 min each)

| Role | Path |
|------|------|
| Assessor | [report/final_report.md](report/final_report.md) → [report/README.md](report/README.md) → [design/requirements/decision_matrices.md](design/requirements/decision_matrices.md) → [testing/README.md](testing/README.md) |
| Hardware | [hardware_design](design/architecture/hardware_design.md) → [power_budget](appendices/power_budget.md) → [test_plan (hardware)](testing/test_plan.md) |
| Firmware | [firmware_architecture](design/architecture/firmware_architecture.md) → [ota_updates](appendices/ota_updates.md) → [communications_design](design/architecture/communications_design.md) |
| Cloud | [cloud_architecture](design/architecture/cloud_architecture.md) → [cloud_cost_analysis](appendices/cloud_cost_analysis.md) → [mqtt_schema](appendices/mqtt_schema.md) |
| Security | [security_privacy_sustainability](design/implementation/security_privacy_sustainability.md) → [ota_updates](appendices/ota_updates.md) → [testing/README](testing/README.md) |
| Product / PM | [README](README.md) → [use_case_and_constraints](design/requirements/use_case_and_constraints.md) → [cloud_cost_analysis](appendices/cloud_cost_analysis.md) → [testing/README](testing/README.md) |

---

 One-page stats

| Item | Value |
|------|--------|
| Documents | 24 files (~100,000 words) |
| Submission | [report/final_report.md](report/final_report.md) (1,500 words) |
| Pilot | 4 weeks, 10 devices, 98% test pass, 18.2% HVAC savings |
| Battery | 2.4 years (3× AA lithium), 48 µA average |
| BOM | £35 (target &lt; £50) |
| Cloud | £22/year for 20 devices (AWS eu-west-1) |

---

Next: [Full document index (INDEX.md)](INDEX.md) · [Project structure (PROJECT_STRUCTURE.md)](PROJECT_STRUCTURE.md) · [Changelog (CHANGELOG.md)](CHANGELOG.md)
