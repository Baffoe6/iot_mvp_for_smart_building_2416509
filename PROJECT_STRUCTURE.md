 Project Structure - Quick Reference

```
iot_mvp/
│
├──  README.md ........................... Project overview, navigation, key stats
├── QUICKSTART.md ......................... One-page paths (assessor, implementer, by role)
├── INDEX.md ............................... Alphabetical, topical, keyword, role-based index
├── GLOSSARY.md ............................. Acronyms and key terms (BLE, MQTT, OTA, etc.)
├── CHANGELOG.md ............................ Version history
├── PROJECT_STRUCTURE.md .................... This file - directory tree and quick paths
│
├──  report/ ............................. SUBMISSION FOLDER
│   ├── README.md .......................... Submission guide, checklist
│   └── final_report.md .................... 1,500-word academic report  SUBMIT THIS
│
├──  design/ ............................. Technical design (3 phases)
│   ├── README.md .......................... Design overview, phase guide
│   │
│   ├── requirements/ ...................... Phase 1: What to build
│   │   ├── use_case_and_constraints.md .... Problem statement, success metrics
│   │   ├── literature_search_log.md ....... Research methodology
│   │   └── decision_matrices.md ........... Component selection (weighted scoring)
│   │
│   ├── architecture/ ...................... Phase 2: How to build it
│   │   ├── hardware_design.md ............. PCB, BOM (£35), power (48 µA)
│   │   ├── firmware_architecture.md ....... FreeRTOS, secure OTA
│   │   ├── communications_design.md ....... BLE + MQTT, gateway
│   │   ├── cloud_architecture.md .......... AWS IoT (£22/year for 20 devices)
│   │   └── mobile_app_design.md ........... React dashboard, mobile app
│   │
│   └── implementation/ .................... Phase 3: Production readiness
│       └── security_privacy_sustainability.md .. Threat model, GDPR, carbon
│
├──  testing/ ............................ Test plans & results
│   ├── README.md .......................... Testing overview, pilot results
│   └── test_plan.md ....................... 92 tests (98% pass rate)
│
└──  appendices/ ......................... Deep technical detail
    ├── README.md .......................... Appendices guide
    ├── power_budget.md .................... 18.5k words - Battery lifetime
    ├── mqtt_schema.md ..................... 12k words - Topic hierarchy, ACLs
    ├── ota_updates.md ..................... 15k words - Secure firmware updates
    └── cloud_cost_analysis.md ............. 9.5k words - AWS cost projections
```

---

 Quick Start Paths

 Path 1: Assessment Submission
```
1. Read: report/final_report.md (8 min)
2. Review: report/README.md (submission checklist)
3. Submit: final_report.md to your university portal
```

 Path 2: Understanding the System
```
1. Overview: README.md (10 min)
2. Requirements: design/requirements/use_case_and_constraints.md (12 min)
3. Architecture: design/architecture/hardware_design.md → firmware → comms → cloud
4. Results: testing/README.md (pilot validation)
```

 Path 3: Hardware Implementation
```
1. Design: design/architecture/hardware_design.md
2. Power: appendices/power_budget.md (detailed calculations)
3. Testing: testing/test_plan.md (section: Device Hardware)
4. BOM: £35 breakdown in hardware_design.md
```

 Path 4: Firmware Development
```
1. Architecture: design/architecture/firmware_architecture.md
2. OTA: appendices/ota_updates.md (bootloader, RSA signatures)
3. Testing: testing/test_plan.md (section: Firmware)
4. Security: design/implementation/security_privacy_sustainability.md
```

 Path 5: Cloud Deployment
```
1. Architecture: design/architecture/cloud_architecture.md
2. Costs: appendices/cloud_cost_analysis.md (20/100/500/5k devices)
3. MQTT: appendices/mqtt_schema.md (topics, ACLs, QoS)
4. Testing: testing/test_plan.md (section: Cloud)
```

 Path 6: Business Planning
```
1. Use case: design/requirements/use_case_and_constraints.md
2. Costs: appendices/cloud_cost_analysis.md (SaaS model, break-even)
3. Results: testing/README.md (18% HVAC savings, 17.3-month ROI)
4. Sustainability: design/implementation/security_privacy_sustainability.md (carbon payback)
```

---

 Statistics by Directory

| Directory | Files | Word Count | Purpose |
|-----------|-------|------------|---------|
| report/ | 2 | 1,500 | Academic submission |
| design/requirements/ | 3 | 11,000 | Problem definition, research |
| design/architecture/ | 5 | 20,000 | System design |
| design/implementation/ | 1 | 5,200 | Security, ethics |
| testing/ | 2 | 8,000 | Validation results |
| appendices/ | 5 | 55,000 | Implementation detail |
| root | 6 | — | README, QUICKSTART, INDEX, GLOSSARY, CHANGELOG, PROJECT_STRUCTURE |
| Total | 24 | ~100,000 | Complete specification |

---

 🔍 Find Information Fast

 "How long does the battery last?"
→ `design/architecture/hardware_design.md` (summary: 2.4 years)  
→ `appendices/power_budget.md` (detailed: 18,500 words)

 "What does it cost to run in the cloud?"
→ `design/architecture/cloud_architecture.md` (summary: £22/year for 20 devices)  
→ `appendices/cloud_cost_analysis.md` (detailed: all scales, SaaS model)

 "Is it secure?"
→ `design/implementation/security_privacy_sustainability.md` (threat model)  
→ `testing/README.md` (security audit: Zero P0/P1)

 "How do I update firmware remotely?"
→ `design/architecture/firmware_architecture.md` (overview)  
→ `appendices/ota_updates.md` (15,000 words, bootloader spec)

 "Does it comply with GDPR?"
→ `design/implementation/security_privacy_sustainability.md` (Section 4.2: GDPR)  
→ `testing/test_plan.md` (GDPR compliance tests)

 "What were the pilot results?"
→ `testing/README.md` (summary table, all metrics)  
→ `report/final_report.md` (Section 5: Testing and Validation)

 "How do I choose components?"
→ `design/requirements/decision_matrices.md` (weighted matrices)  
→ `design/requirements/literature_search_log.md` (research method)

---

 🚀 Implementation Checklist

 Hardware Team
- [ ] Review `design/architecture/hardware_design.md`
- [ ] Study `appendices/power_budget.md` (optimization strategies)
- [ ] Validate BOM (£35 target)
- [ ] Order STM32WB55, SCD40, PIR, batteries, PCB
- [ ] Lab testing: power consumption (Keysight N6705C)

 Firmware Team
- [ ] Review `design/architecture/firmware_architecture.md`
- [ ] Study `appendices/ota_updates.md` (bootloader design)
- [ ] Implement FreeRTOS tasks (Sensing, Comms, Watchdog)
- [ ] Integrate mbedTLS (RSA-2048 signature verification)
- [ ] Testing: `testing/test_plan.md` (Firmware section)

 Gateway Team
- [ ] Review `design/architecture/communications_design.md`
- [ ] Study `appendices/mqtt_schema.md` (topic hierarchy)
- [ ] Configure Raspberry Pi 4 (BLE scanner + MQTT publisher)
- [ ] Implement 7-day local buffering (SQLite)
- [ ] Testing: `testing/test_plan.md` (Gateway section)

 Cloud Team
- [ ] Review `design/architecture/cloud_architecture.md`
- [ ] Study `appendices/cloud_cost_analysis.md` (service sizing)
- [ ] Deploy AWS IoT Core + Timestream (CloudFormation/CDK)
- [ ] Configure ACL policies (`appendices/mqtt_schema.md`)
- [ ] Testing: `testing/test_plan.md` (Cloud section)

 Dashboard Team
- [ ] Review `design/architecture/mobile_app_design.md`
- [ ] Implement React dashboard (wireframes in doc)
- [ ] Integrate AWS Amplify (Cognito auth)
- [ ] WCAG 2.1 AA compliance (4.5:1 contrast, 44×44 px targets)
- [ ] Testing: `testing/test_plan.md` (UAT section)

---

 Support & Contact

 Documentation Issues
- Missing information? Check `README.md` in each directory for section-specific guides
- Cross-references broken? All links updated post-refactoring (14 Jan 2026)

 Technical Questions
- Hardware: See `appendices/power_budget.md` (formulas, validation protocols)
- Software: See `appendices/ota_updates.md` (code examples, test cases)
- Cloud: See `appendices/cloud_cost_analysis.md` (pricing, optimization)

---

 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 12 Jan 2026 | Initial documentation (flat structure, 01-10 files) |
| 2.0 | 14 Jan 2026 | Refactored (organized folders, README per section) |

---

 File Naming Convention

 Before Refactoring (v1.0)
```
01_use_case_and_constraints.md
02_literature_search_log.md
...
10_mvp_test_plan.md
REPORT_FINAL_1500_WORDS.md
Appendix_A_Power_Budget.md
```

 After Refactoring (v2.0)
```
design/requirements/use_case_and_constraints.md
design/requirements/literature_search_log.md
...
testing/test_plan.md
report/final_report.md
appendices/power_budget.md
```

Benefits: 
-  Logical grouping by purpose (requirements, architecture, testing)
-  No more numbered prefixes (easier to reference)
-  README.md in each folder for context
-  Cleaner project root (only README.md visible)

---

Last Updated: January 14, 2026  
Structure Version: 2.0 (Refactored)  
Total Files: 24 (including 5 README guides + QUICKSTART, INDEX, GLOSSARY, CHANGELOG)  
Total Words: ~100,000 (includes new README guides)
