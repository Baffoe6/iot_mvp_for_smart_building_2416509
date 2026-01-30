 Design Documentation

This directory contains all technical design documentation organized in three phases:

 Phase 1: Requirements Analysis ([requirements/](requirements/))

Foundational documents defining what needs to be built and why.

- [use_case_and_constraints.md](requirements/use_case_and_constraints.md) - Core problem statement, stakeholder needs, quantified constraints
- [literature_search_log.md](requirements/literature_search_log.md) - Systematic literature review methodology
- [decision_matrices.md](requirements/decision_matrices.md) - Evidence-based component selection with weighted scoring

Start here to understand project requirements and component selection rationale.

---

 Phase 2: System Architecture ([architecture/](architecture/))

Detailed architectural design for each system layer.

 Device Layer
- [hardware_design.md](architecture/hardware_design.md) - PCB schematic, BOM (£35), power budget (48 µA avg → 2.4yr lifetime)

 Embedded Software
- [firmware_architecture.md](architecture/firmware_architecture.md) - FreeRTOS tasks, secure OTA with dual-bank flash

 Communications
- [communications_design.md](architecture/communications_design.md) - BLE 5.2 advertisements, MQTT/TLS, Raspberry Pi gateway

 Cloud Platform
- [cloud_architecture.md](architecture/cloud_architecture.md) - AWS IoT Core, Timestream, Lambda, API Gateway (£22/year for 20 devices)

 User Interface
- [mobile_app_design.md](architecture/mobile_app_design.md) - React web dashboard, React Native mobile app, WCAG 2.1 AA

Read in order (hardware → firmware → comms → cloud → UI) to understand end-to-end data flow.

---

 Phase 3: Implementation Details ([implementation/](implementation/))

Cross-cutting concerns for production readiness.

- [security_privacy_sustainability.md](implementation/security_privacy_sustainability.md) 
  - Threat model (14 threats, controls, residual risks)
  - GDPR compliance (no personal data collected)
  - Carbon footprint (1.9 kg embodied, 7.17 kg avoided, 6-month payback)

Essential reading for security audit, ethics approval, and sustainability reporting.

---

 Navigation

- ← Back: [Project Root](../README.md)
- → Testing: [../testing/](../testing/)
- → Appendices: [../appendices/](../appendices/)
- → Final Report: [../report/final_report.md](../report/final_report.md)

---

 Quick Stats

| Phase | Documents | Word Count | Coverage |
|-------|-----------|------------|----------|
| Requirements | 3 | ~11,000 | Use case → Literature → Decisions |
| Architecture | 5 | ~20,000 | Hardware → Cloud → UI |
| Implementation | 1 | ~5,200 | Security, Privacy, Sustainability |
| Total | 9 | ~36,200 | Complete system specification |

---

Last Updated: January 14, 2026  
Status:  All sections validated in 4-week pilot deployment
