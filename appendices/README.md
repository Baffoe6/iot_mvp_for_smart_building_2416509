 Appendices - Deep Technical Detail

This directory contains comprehensive technical appendices that provide implementation-level detail for critical system components.

---

 Available Appendices

 [power_budget.md](power_budget.md) (18,500 words)
Complete power analysis and battery lifetime validation

Contents:
- Component-level power consumption tables (STM32WB55, SCD40, PIR, TPS62840)
- Cycle-by-cycle energy calculations (occupied 10 min, vacant 25 min)
- Battery lifetime optimization iterations:
  - 2× AA + 10 min fixed → 1.03 years   - 2× AA + 15 min fixed → 1.54 years   - 2× AA + 10/20 min adaptive → 1.23 years   - 3× AA + 10/25 min optimized → 2.4 years - Temperature derating analysis (15-25°C range)
- Field validation protocols (Keysight power analyzer, thermal chamber)
- Sensitivity analysis (sampling interval impact)
- Excel formulas for custom calculations

Use when: Designing hardware, optimizing power consumption, validating battery lifetime

---

 [mqtt_schema.md](mqtt_schema.md) (12,000 words)
Complete MQTT v5.0 topic hierarchy and access control

Contents:
- Topic hierarchy: `{tenant}/building/{id}/gateway/{id}/device/{id}/{type}`
- Uplink topics: telemetry (QoS 1), alerts (QoS 1), status (QoS 0)
- Downlink topics: config, OTA, commands
- JSON payload schemas with versioning
- AWS IoT Core ACL policies (gateway, dashboard user, admin roles)
- Message ordering and deduplication strategies
- Retained messages and Last Will Testament configuration
- Scaling analysis (supports 50,000+ topics)
- Performance benchmarks (42 ms publish latency, 1.2s E2E)

Use when: Implementing gateway, configuring AWS IoT Core, designing multi-tenant ACLs

---

 [ota_updates.md](ota_updates.md) (15,000 words)
Secure over-the-air firmware update specification

Contents:
- 5-phase OTA flow with sequence diagrams:
  1. Campaign initiation (cloud)
  2. Notification (cloud → gateway → device)
  3. Firmware transfer (BLE, 4 KB chunks)
  4. Bank swap and validation (bootloader)
  5. Status reporting (device → cloud)
- Dual-bank Flash architecture (Bank A active, Bank B staged)
- RSA-2048 signature verification (mbedTLS implementation)
- Anti-rollback protection (OTP fuse-based version check)
- Self-test timeout and automatic rollback
- 6 comprehensive test cases:
  - Normal update (happy path)
  - Rollback on self-test failure
  - Invalid signature rejection
  - Battery low deferral
  - Gateway offline resilience
  - Concurrent multi-device rollout
- Energy impact: 0.9 mWh per OTA (3% annual battery reduction)

Use when: Implementing bootloader, designing OTA campaigns, testing firmware updates

---

 [cloud_cost_analysis.md](cloud_cost_analysis.md) (9,500 words)
Detailed AWS cost breakdowns and scaling projections

Contents:
- Service-by-service pricing (IoT Core, Timestream, Lambda, API Gateway, S3, SNS, CloudWatch, DynamoDB)
- Cost models for 4 deployment scales:
  - 20 devices: £22/year (£1.10/device/year)
  - 100 devices: £109/year (£1.09/device/year)
  - 500 devices: £540/year (£1.08/device/year)
  - 5,000 devices: £5,452/year (£1.09/device/year)
- 5 optimization strategies:
  - Timestream Reserved Capacity (20% discount, £888/year savings)
  - Data retention tuning (90d → 30d hot, 54% cost reduction)
  - Query caching (ElastiCache Redis, 80% cache hit rate)
  - DynamoDB vs. Aurora comparison
  - S3 Intelligent-Tiering
- SaaS business model:
  - Revenue tiers (Starter £1.5k, Professional £5k, Enterprise £15k)
  - Break-even: 76 customers (£5k/year tier, 66% gross margin)
- Cloud vs. on-premise TCO (£12.4k vs. £11.3k over 5 years)
- Data transfer cost analysis (negligible at current scale)

Use when: Budget planning, pitch deck preparation, scaling cost projections

---

 Usage Guide

 For Hardware Engineers
1. Start: [power_budget.md](power_budget.md) - Component selection, power optimization
2. Validate: Field measurement protocols (Keysight N6705C setup)

 For Firmware Engineers
1. Start: [ota_updates.md](ota_updates.md) - Bootloader design, RSA verification
2. Reference: [mqtt_schema.md](mqtt_schema.md) - Payload formats, topic structure

 For Cloud Architects
1. Start: [cloud_cost_analysis.md](cloud_cost_analysis.md) - AWS service sizing
2. Reference: [mqtt_schema.md](mqtt_schema.md) - IoT Core ACL policies, scaling limits

 For Project Managers
1. Start: [cloud_cost_analysis.md](cloud_cost_analysis.md) - Budget planning, SaaS model
2. Reference: All appendices for technical feasibility validation

---

 Cross-References

Each appendix links back to corresponding design documents:

- [power_budget.md](power_budget.md) ↔ [design/architecture/hardware_design.md](../design/architecture/hardware_design.md)
- [mqtt_schema.md](mqtt_schema.md) ↔ [design/architecture/communications_design.md](../design/architecture/communications_design.md)
- [ota_updates.md](ota_updates.md) ↔ [design/architecture/firmware_architecture.md](../design/architecture/firmware_architecture.md)
- [cloud_cost_analysis.md](cloud_cost_analysis.md) ↔ [design/architecture/cloud_architecture.md](../design/architecture/cloud_architecture.md)

---

 Navigation

- ← Back: [Project Root](../README.md)
- → Design: [../design/](../design/)
- → Testing: [../testing/](../testing/)
- → Final Report: [../report/final_report.md](../report/final_report.md)

---

 Statistics

| Appendix | Word Count | Read Time | Implementation Depth |
|----------|------------|-----------|---------------------|
| Power Budget | 18,500 | 75 min | Production-ready formulas |
| MQTT Schema | 12,000 | 50 min | Complete ACL policies |
| OTA Updates | 15,000 | 60 min | Full bootloader spec |
| Cloud Costs | 9,500 | 40 min | 4-scale projections |
| Total | 55,000 | ~4 hrs | Implementation-ready |

---

Last Updated: January 14, 2026  
Status:  All calculations validated in pilot deployment  
Audience: Implementation teams (hardware, firmware, cloud, PM)
