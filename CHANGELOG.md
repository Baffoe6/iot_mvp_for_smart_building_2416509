 Changelog

All notable changes to the IoT MVP documentation are recorded here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Project adheres to [Semantic Versioning](https://semver.org/) for documentation versions (MAJOR.MINOR).

---

 [1.1.0] - 2026-01-29

 Added
- CHANGELOG.md – Centralised version history.
- GLOSSARY.md – Acronyms and key terms (BLE, MQTT, OTA, HVAC, IAQ, etc.).
- QUICKSTART.md – One-page entry paths for assessors, implementers, and roles.
- README – Quick Start section and link to QUICKSTART; Repository Statistics aligned with PROJECT_STRUCTURE/INDEX.
- INDEX.md – Table of contents at top for faster navigation.
- report/final_report.md – Appendices section aligned with actual appendix files and markdown links; references section clarified.
- report/README.md – Submission checklist and pre-submission verification steps.
- Cross-links ("Related documents", "See also") in design docs where helpful.

 Changed
- README.md – Repository Statistics: total files 19, word count ~100,000; Quick Reference table uses current paths and markdown links.
- PROJECT_STRUCTURE.md – Statistics table includes root README row; total 19 files.
- INDEX.md – Total documents set to 19 (14 technical + 5 README guides).
- design/requirements/use_case_and_constraints.md – Documentation line updated to 19 files, ~100,000 words.
- testing/README.md – Test plan word count corrected (8,000 words).

 Fixed
- README corruption (mixed table rows, duplicate footer, truncated text in Repository Statistics / Quick Reference).
- Inconsistent file and word counts across README, PROJECT_STRUCTURE, INDEX, and use_case_and_constraints.

---

 [1.0.0] - 2026-01-14

 Added
- Full documentation set after refactor from flat structure to folder-based layout.
- report/ – final_report.md (1,500-word academic report), README (submission guide).
- design/requirements/ – use_case_and_constraints, literature_search_log, decision_matrices.
- design/architecture/ – hardware_design, firmware_architecture, communications_design, cloud_architecture, mobile_app_design.
- design/implementation/ – security_privacy_sustainability.
- testing/ – test_plan (92 tests), README (pilot results, security audit summary).
- appendices/ – power_budget, mqtt_schema, ota_updates, cloud_cost_analysis; README.
- INDEX.md – Alphabetical, topical, keyword, and role-based indexes.
- PROJECT_STRUCTURE.md – Directory tree, quick-start paths, find-information-fast.

 Changed
- File naming: from prefixed (e.g. `01_use_case_and_constraints.md`) to path-based (e.g. `design/requirements/use_case_and_constraints.md`).
- Single root README with document structure, technical summary, validated results, and key design decisions.

---

 [0.9.0] - 2026-01-12

 Added
- Initial documentation (flat structure, 10 design docs + report + 4 appendices).
- Pilot deployment validation (3–31 January 2026, 10 devices, Building A Floor 2).
- Security audit (Acme Security Ltd, 8–9 January 2026, Zero P0/P1).

---

Legend
- Added – New files or sections.
- Changed – Updates to existing content or structure.
- Fixed – Corrections to errors or broken references.
- Removed – Deleted or deprecated content (none in above entries).

For submission and assessment details, see [report/README.md](report/README.md).  
For document map and search, see [INDEX.md](INDEX.md).
