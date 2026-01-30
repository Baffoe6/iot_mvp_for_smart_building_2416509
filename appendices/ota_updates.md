 Appendix C: Secure Over-The-Air (OTA) Firmware Update Specification

 Overview

This appendix provides detailed specifications for the secure OTA firmware update mechanism, including sequence diagrams, security controls, rollback procedures, and test cases. The design prioritizes security (prevent unauthorized firmware), reliability (prevent bricking), and efficiency (minimize bandwidth and energy).

---

 Architecture Overview

 Components

1. AWS S3 Firmware Repository: Stores signed firmware binaries (versioned, immutable)
2. AWS Lambda OTA Orchestrator: Manages update campaigns, tracks device states
3. AWS IoT Core: MQTT transport for update notifications and status reports
4. Raspberry Pi 4 Gateway: Downloads firmware from S3, caches locally, streams to devices over BLE
5. STM32WB55 Device: Receives firmware chunks, validates signature, flashes dual-bank memory
6. Bootloader: RSA-2048 signature verification, bank swap, self-test, automatic rollback

 Dual-Bank Flash Architecture

STM32WB55 Flash Layout (1 MB total):

| Address Range | Bank | Purpose | Size |
|---------------|------|---------|------|
| 0x0800 0000 - 0x0800 7FFF | Boot | Bootloader (immutable) | 32 KB |
| 0x0800 8000 - 0x0805 FFFF | A | Active Firmware | 352 KB |
| 0x0806 0000 - 0x080B 7FFF | A | Application Data / Logs | 352 KB |
| 0x080B 8000 - 0x080F FFFF | B | Staged Firmware (OTA target) | 288 KB |
| 0x0810 0000 - 0x081F FFFF | Reserved | BLE Stack (read-only) | 1 MB (external) |

Key Features:
- Bootloader in separate protected sector: Cannot be overwritten by OTA
- Dual-bank support: Bank A active, Bank B stages update, atomic swap
- Bank swap instruction: `FLASH_OB_Launch()` hardware-enforced swap, no software bugs can corrupt
- Rollback mechanism: If new firmware fails self-test, bootloader swaps back to Bank A

---

 OTA Update Flow: Step-by-Step Sequence

 Phase 1: Campaign Initiation (Cloud)

```
┌──────────────┐         ┌────────────────┐         ┌──────────────┐
│  Admin User  │         │  AWS Lambda    │         │  AWS S3      │
│  (Dashboard) │         │  OTA Orchestr. │         │  Firmware    │
└──────┬───────┘         └───────┬────────┘         └──────┬───────┘
       │                         │                         │
       │ 1. Upload firmware.bin  │                         │
       │────────────────────────>│ 2. Sign with RSA-2048   │
       │                         │─────────────────────────>│
       │                         │ 3. Store signed binary  │
       │                         │<─────────────────────────│
       │                         │                         │
       │ 4. Create campaign      │                         │
       │    (target: BuildingA,  │                         │
       │     version: v1.3.0)    │                         │
       │────────────────────────>│                         │
       │                         │ 5. Query device registry│
       │                         │    (DynamoDB: get devices│
       │                         │     in BuildingA with    │
       │                         │     version < v1.3.0)    │
       │                         │                         │
       │ 6. Return campaign ID   │                         │
       │<────────────────────────│                         │
       │    (campaign-20260112-01)│                         │
       │                         │                         │
```

Campaign Parameters:
```json
{
  "campaign_id": "campaign-20260112-01",
  "firmware_version": "v1.3.0",
  "target_filter": {
    "building_id": ["BuildingA", "BuildingB"],
    "current_version_lt": "v1.3.0",
    "device_ids": []  // Empty = all matching filter
  },
  "rollout_strategy": "phased",
  "phases": [
    {"percentage": 10, "start_at": "2026-01-12T22:00:00Z"},  // 10% pilot
    {"percentage": 50, "start_at": "2026-01-13T02:00:00Z"},  // 50% if no errors
    {"percentage": 100, "start_at": "2026-01-13T10:00:00Z"}  // Full rollout
  ],
  "mandatory": false,
  "deadline": "2026-01-20T00:00:00Z"
}
```

 Phase 2: Notification (Cloud → Gateway → Device)

```
┌────────────────┐         ┌──────────────┐         ┌────────────────┐
│  AWS IoT Core  │         │  Gateway     │         │  Device        │
│  (MQTT Broker) │         │  (RPi4)      │         │  (STM32WB55)   │
└───────┬────────┘         └──────┬───────┘         └───────┬────────┘
        │                         │                         │
        │ 7. Publish OTA notif.   │                         │
        │    (MQTT QoS 1)         │                         │
        │────────────────────────>│                         │
        │                         │                         │
        │                         │ 8. Download firmware    │
        │                         │    from S3 (HTTPS)      │
        │                         │    - URL from message   │
        │                         │    - Validate SHA-256   │
        │                         │    - Cache to /tmp/ota/ │
        │                         │                         │
        │                         │ 9. Wait for device wake │
        │                         │    (next scheduled      │
        │                         │     telemetry cycle)    │
        │                         │                         │
        │                         │<───── BLE Advertisement │
        │                         │       (telemetry data)  │
        │                         │                         │
        │                         │ 10. BLE GATT write:     │
        │                         │     OTA_AVAILABLE flag  │
        │                         │────────────────────────>│
        │                         │                         │
        │                         │<──────────────────────── │
        │                         │  11. ACK (ready to rx)  │
        │                         │                         │
```

OTA Notification Payload (MQTT):
```json
{
  "version": "1.0",
  "timestamp": "2026-01-12T22:00:15.456Z",
  "campaign_id": "campaign-20260112-01",
  "device_id": "stm32wb-a4c138f06e92",
  "firmware_version": "v1.3.0",
  "firmware_url": "https://s3.eu-west-1.amazonaws.com/iot-firmware-prod/stm32wb55/v1.3.0/firmware.bin",
  "firmware_size_bytes": 245760,
  "firmware_sha256": "a3f5e9c8b2d1f4e6a7c8b9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",
  "signature": "BASE64_ENCODED_RSA2048_SIGNATURE_OF_FIRMWARE_HASH",
  "mandatory": false,
  "deadline": "2026-01-20T00:00:00Z"
}
```

 Phase 3: Firmware Transfer (Gateway → Device via BLE)

```
┌──────────────┐                                    ┌────────────────┐
│  Gateway     │                                    │  Device        │
│  (RPi4)      │                                    │  (STM32WB55)   │
└──────┬───────┘                                    └───────┬────────┘
       │                                                    │
       │ 12. BLE GATT Service: OTA_SERVICE                 │
       │     UUID: 0000FE10-0000-1000-8000-00805F9B34FB    │
       │                                                    │
       │     Characteristic: OTA_CONTROL                    │
       │     UUID: 0000FE11-... (Write)                     │
       │         - Payload: {version, size, sha256, sig}    │
       │────────────────────────────────────────────────────>│
       │                                                    │
       │                                              13. Device validates│
       │                                                  signature with  │
       │                                                  public key (ROM)│
       │                                                  - RSA-2048 verify│
       │                                                  - If invalid:    │
       │<────────────────────────────────────────────────   REJECT        │
       │                                                                   │
       │     Characteristic: OTA_DATA                                      │
       │     UUID: 0000FE12-... (Write, max 512 bytes)                    │
       │                                                                   │
       │ 14. Stream firmware in 4 KB chunks                               │
       │     (8× 512-byte BLE writes per chunk)                           │
       │     Chunk 0 (0-4095 bytes) ──────────────────────────────────────>│
       │                                                  15. Write to Bank B│
       │                                                      Flash addr:   │
       │                                                      0x080B8000    │
       │                                                  16. Verify CRC32  │
       │<─────────────────────────────────────────────────  ACK chunk 0    │
       │                                                                   │
       │     Chunk 1 (4096-8191 bytes) ───────────────────────────────────>│
       │                                                  17. Write + CRC   │
       │<─────────────────────────────────────────────────  ACK chunk 1    │
       │                                                                   │
       │     ... (repeat for 60 chunks, 245760 bytes total)                │
       │                                                                   │
       │     Chunk 59 (241664-245759 bytes) ──────────────────────────────>│
       │                                                  18. Write + CRC   │
       │<─────────────────────────────────────────────────  ACK chunk 59   │
       │                                                                   │
       │ 19. BLE GATT Write: OTA_FINALIZE                                  │
       │     Payload: {full_sha256}                                        │
       │────────────────────────────────────────────────────>│
       │                                              20. Compute SHA-256 of│
       │                                                  Bank B (245760 B) │
       │                                                  Compare to provided│
       │                                                  If mismatch: ABORT │
       │<────────────────────────────────────────────────  21. SUCCESS      │
       │                                                                   │
```

Energy Impact of Transfer:
- Total data: 245,760 bytes (240 KB firmware)
- BLE overhead: 512-byte MTU → 480 chunks (including headers/ACKs)
- Transfer time: 480 chunks × 50 ms/chunk = 24 seconds (BLE 2 Mbps PHY)
- Energy consumption: 10 mA × 24 s × 3.3 V = 0.22 mWh (0.05% of annual budget, negligible)

 Phase 4: Bank Swap and Validation (Device Bootloader)

```
┌────────────────┐
│  Device        │
│  (STM32WB55)   │
└───────┬────────┘
        │
        │ 22. Set BOOT flag in Option Bytes:
        │     BFB2 = 1 (boot from Bank B on next reset)
        │     Write to Flash Option Bytes register
        │
        │ 23. Trigger system reset
        │     NVIC_SystemReset()
        │
        ▼
 ┌─────────────────────────────┐
 │  BOOTLOADER (0x08000000)    │
 └──────────────┬──────────────┘
                │
                │ 24. Power-on self-test (POST)
                │     - Check reset reason (software reset)
                │     - Read BFB2 flag (Bank B active)
                │     - Log: "Booting from Bank B (OTA)"
                │
                │ 25. Verify Bank B signature
                │     - Read firmware from 0x080B8000
                │     - Compute SHA-256 hash
                │     - RSA-2048 verify with public key (ROM)
                │     - If invalid: ABORT, swap to Bank A
                │
                │ 26. Jump to Bank B application
                │     - Set SP (stack pointer) = Bank B vector table
                │     - Set PC (program counter) = Bank B reset handler
                │     - Start application
                │
                ▼
         ┌────────────────────┐
         │  APPLICATION (v1.3.0)│
         │  (Bank B)           │
         └──────────┬──────────┘
                    │
                    │ 27. Self-test (first 5 minutes)
                    │     - Initialize hardware (I²C, BLE, RTC)
                    │     - Read CO₂ sensor (verify communication)
                    │     - Perform BLE advertisement (verify radio)
                    │     - Set SELF_TEST_PASSED flag in backup SRAM
                    │
                    │ 28. If self-test passes:
                    │     - Commit Bank B as permanent (clear rollback flag)
                    │     - Publish OTA status: SUCCESS
                    │
                    │ 29. If self-test fails (timeout 5 min):
                    │     - Watchdog triggers reset
                    │     - Bootloader detects SELF_TEST_PASSED = 0
                    │     - Auto-rollback to Bank A
                    │
                    ▼
```

Rollback Scenario:
```
 ┌─────────────────────────────┐
 │  BOOTLOADER (POST-RESET)    │
 └──────────────┬──────────────┘
                │
                │ 30. Check backup SRAM flag:
                │     SELF_TEST_PASSED = 0 (not set within 5 min)
                │
                │ 31. Swap back to Bank A
                │     - Set BFB2 = 0 (boot from Bank A)
                │     - Write to Flash Option Bytes
                │     - Trigger reset
                │
                ▼
         ┌────────────────────┐
         │  APPLICATION (v1.2.3)│
         │  (Bank A - restored)│
         └──────────┬──────────┘
                    │
                    │ 32. Publish OTA status: ROLLBACK
                    │     Reason: "Self-test timeout"
                    │
                    ▼
```

 Phase 5: Status Reporting (Device → Cloud)

```
┌────────────────┐         ┌──────────────┐         ┌────────────────┐
│  Device        │         │  Gateway     │         │  AWS Lambda    │
│  (STM32WB55)   │         │  (RPi4)      │         │  OTA Orchestr. │
└───────┬────────┘         └──────┬───────┘         └───────┬────────┘
        │                         │                         │
        │ 33. Publish OTA status  │                         │
        │    (MQTT topic:         │                         │
        │     .../device/{id}/ota/status)                   │
        │────────────────────────>│                         │
        │                         │ 34. Forward to cloud    │
        │                         │────────────────────────>│
        │                         │                         │
        │                         │                    35. Update campaign│
        │                         │                        state (DynamoDB)│
        │                         │                        - device_id: SUCCESS│
        │                         │                        - version: v1.3.0│
        │                         │                        - timestamp     │
        │                         │                         │
        │                         │<───────────────────────── │
        │                         │  36. ACK                │
        │<────────────────────────│                         │
        │                         │                         │
```

OTA Status Payload (MQTT):
```json
{
  "version": "1.0",
  "timestamp": "2026-01-12T22:12:45.789Z",
  "campaign_id": "campaign-20260112-01",
  "device_id": "stm32wb-a4c138f06e92",
  "status": "success",
  "previous_version": "v1.2.3",
  "new_version": "v1.3.0",
  "duration_seconds": 142,
  "details": {
    "download_time_s": 24,
    "flash_time_s": 8,
    "verification_time_s": 3,
    "self_test_time_s": 107
  }
}
```

Possible Status Values:
- `pending`: Device acknowledged OTA notification, download not started
- `downloading`: Firmware transfer in progress
- `verifying`: SHA-256 hash validation
- `flashing`: Writing to Bank B Flash
- `testing`: Self-test in progress (5-minute window)
- `success`: OTA complete, new firmware operational
- `rollback`: Self-test failed, reverted to previous version
- `failed`: Error during download/flash (details in `error_code` field)

---

 Security Controls

 1. Firmware Signing (RSA-2048)

Signing Process (offline, air-gapped build server):
```bash
 Step 1: Compile firmware
arm-none-eabi-gcc -o firmware.elf <sources>
arm-none-eabi-objcopy -O binary firmware.elf firmware.bin

 Step 2: Compute SHA-256 hash
sha256sum firmware.bin > firmware.sha256

 Step 3: Sign hash with RSA-2048 private key (HSM-protected)
openssl dgst -sha256 -sign private_key_rsa2048.pem -out firmware.sig firmware.bin

 Step 4: Package signed firmware
cat firmware.bin firmware.sig > firmware_signed.bin
```

Public Key Embedding (device bootloader, read-only Flash):
```c
// bootloader/keys.c (compiled into bootloader, separate from app)
const uint8_t rsa_public_key_n[256] = {
    0xC4, 0x7A, 0x3B, 0x9F, ... // RSA modulus (2048-bit)
};
const uint32_t rsa_public_key_e = 65537;  // Public exponent
```

Verification (device bootloader):
```c
include "mbedtls/rsa.h"

bool verify_firmware_signature(uint8_t firmware, uint32_t size, uint8_t signature) {
    mbedtls_rsa_context rsa;
    mbedtls_rsa_init(&rsa, MBEDTLS_RSA_PKCS_V21, MBEDTLS_MD_SHA256);
    
    // Load public key
    mbedtls_mpi_read_binary(&rsa.N, rsa_public_key_n, 256);
    mbedtls_mpi_lset(&rsa.E, rsa_public_key_e);
    rsa.len = 256;
    
    // Compute SHA-256 hash of firmware
    uint8_t hash[32];
    mbedtls_sha256(firmware, size, hash, 0);
    
    // Verify RSA-2048 signature
    int ret = mbedtls_rsa_pkcs1_verify(&rsa, NULL, NULL, MBEDTLS_RSA_PUBLIC,
                                       MBEDTLS_MD_SHA256, 32, hash, signature);
    
    mbedtls_rsa_free(&rsa);
    return (ret == 0);  // 0 = success
}
```

Attack Mitigation:
- Man-in-the-middle: Attacker cannot inject malicious firmware (no private key)
- Replay attack: Firmware version checked by bootloader (downgrade prevention via monotonic counter in OTP fuses)
- Key extraction: Private key never leaves HSM; public key alone cannot forge signatures

 2. Anti-Rollback Protection

Challenge: Attacker replays old signed firmware with known vulnerabilities.

Solution: Monotonic version counter in One-Time Programmable (OTP) fuses.

```c
// bootloader/version_check.c
define OTP_VERSION_ADDRESS  0x1FFF7800  // STM32WB55 OTP area

uint32_t get_min_allowed_version(void) {
    return (volatile uint32_t )OTP_VERSION_ADDRESS;
}

bool is_firmware_version_valid(uint32_t fw_version) {
    uint32_t min_version = get_min_allowed_version();
    return (fw_version >= min_version);
}

void commit_firmware_version(uint32_t fw_version) {
    // Burn OTP fuse to new version (irreversible, one-time write)
    // Only allowed after successful self-test
    HAL_FLASH_OB_Unlock();
    HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, OTP_VERSION_ADDRESS, fw_version);
    HAL_FLASH_OB_Lock();
}
```

Version Format: 32-bit integer, e.g., v1.2.3 → `0x00010203`

Enforcement:
1. Device ships with OTP version `0x00010200` (v1.2.0)
2. OTA pushes v1.3.0 → bootloader checks `0x00010300 >= 0x00010200` → ALLOW
3. After successful self-test, OTP burned to `0x00010300`
4. Attacker tries to downgrade to v1.2.0 → bootloader checks `0x00010200 < 0x00010300` → REJECT

Trade-off: Limited OTP writes (typically 1024 cycles on STM32WB55), but sufficient for ~50 years at 1 update/month.

 3. Secure Boot Chain

Boot Flow:
```
Power-On → ROM Bootloader (ST factory, immutable) → 
          → Custom Bootloader (signature verification) → 
          → Application Firmware (Bank A or B)
```

ROM Bootloader (STM32WB55 built-in):
- Verifies custom bootloader signature (optional, requires RDP Level 2)
- Sets read protection to prevent Flash dumps via JTAG/SWD

Custom Bootloader Responsibilities:
- Verify application firmware signature (RSA-2048)
- Check version against OTP (anti-rollback)
- Manage bank swap logic
- Implement self-test timeout and rollback

Attack Surface Reduction:
- JTAG/SWD disabled in production: RDP Level 1 (read protection, debug disabled)
- Bootloader write-protected: Flash sector 0 marked read-only via option bytes
- No UART/USB bootloader: Disable ST default DFU mode (prevent unauthorized firmware upload)

---

 Error Handling and Recovery

 Failure Scenarios

| Failure Mode | Detection | Recovery Action | User Impact |
|--------------|-----------|-----------------|-------------|
| Download timeout | Gateway: S3 GET fails after 3 retries | Retry download after 1 hour | Delayed update (non-critical) |
| Invalid signature | Device: RSA verify returns error | Reject update, publish FAILED status | Device continues on old firmware |
| Flash write error | Device: HAL_FLASH_Program() returns error | Abort OTA, publish FAILED status | Device continues on old firmware |
| SHA-256 mismatch | Device: Final hash ≠ expected hash | Abort OTA, erase Bank B, publish FAILED | Device continues on old firmware |
| Self-test timeout | Watchdog: 5-min timeout, flag not set | Bootloader auto-rollback to Bank A | 5-minute downtime, then restored |
| Gateway offline | Cloud: LWT triggers "offline" status | Queue OTA notification, deliver when online | Delayed update |
| Battery too low | Device: Voltage < 3.0 V during OTA | Defer update until battery replaced | Update postponed (safety measure) |

 Logging and Diagnostics

Bootloader Persistent Log (retained across resets, stored in backup SRAM):
```c
typedef struct {
    uint32_t boot_count;
    uint32_t last_reset_reason;  // Watchdog, software, power-on
    uint32_t ota_attempt_count;
    uint32_t ota_success_count;
    uint32_t ota_rollback_count;
    char last_error[64];
} BootLog_t;
```

Published to Cloud (daily status report):
```json
{
  "boot_log": {
    "boot_count": 1245,
    "last_reset_reason": "software_reset",
    "ota_history": {
      "attempts": 3,
      "successes": 2,
      "rollbacks": 1
    },
    "last_error": "v1.2.5: self-test timeout (I2C SCD40 NACK)"
  }
}
```

---

 Performance and Resource Requirements

 Flash Memory

| Component | Size | Location |
|-----------|------|----------|
| Bootloader | 32 KB | 0x08000000 - 0x08007FFF |
| Application (Bank A) | 352 KB | 0x08008000 - 0x0805FFFF |
| Application (Bank B) | 288 KB | 0x080B8000 - 0x080FFFFF |
| Total used | 672 KB | 67% of 1 MB |

 RAM

| Component | Size | Notes |
|-----------|------|-------|
| Bootloader stack | 2 KB | Minimal (no RTOS) |
| OTA buffer (1 chunk) | 4 KB | Temporary Flash write buffer |
| mbedTLS RSA context | 1.2 KB | Signature verification |
| Peak RAM usage | 7.2 KB | 11% of 64 KB SRAM1 |

 Energy Budget

| Phase | Duration | Current | Energy |
|-------|----------|---------|--------|
| Download (BLE Rx) | 24 s | 10 mA | 0.22 mWh |
| Flash write (60 chunks) | 8 s | 20 mA | 0.15 mWh |
| Signature verification | 3 s | 15 mA | 0.041 mWh |
| Self-test | 107 s | 5 mA | 0.49 mWh |
| Total OTA energy | 142 s | avg 6.1 mA | 0.90 mWh |

Impact on battery life: 0.90 mWh / 12.95 mWh per day = 0.07 days (1.6 hours) per OTA update.  
Annual impact: 2 updates/year × 0.07 days = 0.14 days (3% reduction in lifetime, acceptable).

---

 Testing and Validation

 OTA Test Plan

 Test 1: Normal Update (Happy Path)

Preconditions:
- Device running v1.2.0
- Gateway online, internet connected
- S3 firmware repository contains v1.3.0

Steps:
1. Initiate campaign via dashboard (target: single device)
2. Verify device receives OTA notification within 15 minutes (next telemetry cycle)
3. Monitor BLE GATT transfer (confirm 60 chunks, all ACKed)
4. Observe device reset (LED indicator flashes during bootloader)
5. Wait 5 minutes for self-test
6. Verify OTA status published: `"status": "success"`
7. Query device version via MQTT: confirm `"firmware_version": "v1.3.0"`

Expected Duration: ~12 minutes (10 min wait + 2.4 min transfer + 5 min self-test)

Acceptance Criteria:
-  No error messages in gateway logs
-  Device telemetry resumes after update
-  Version persists across subsequent resets

---

 Test 2: Rollback on Self-Test Failure

Preconditions:
- Device running v1.2.0
- Inject fault in v1.3.0 firmware (e.g., infinite loop in sensor init)

Steps:
1. Push faulty v1.3.0 firmware
2. Device downloads, flashes, resets
3. Application enters infinite loop (self-test flag never set)
4. Wait 5 minutes → watchdog triggers reset
5. Bootloader detects failed self-test → auto-rollback to Bank A (v1.2.0)
6. Verify OTA status: `"status": "rollback"`
7. Query device version: confirm `"firmware_version": "v1.2.0"`

Expected Duration: ~17 minutes (12 min update + 5 min timeout)

Acceptance Criteria:
-  Device recovers automatically (no manual intervention)
-  Telemetry resumes on v1.2.0
-  Rollback logged in boot history

---

 Test 3: Invalid Signature Rejection

Preconditions:
- Device running v1.2.0
- Modify v1.3.0 firmware binary (flip one byte) to invalidate signature

Steps:
1. Push modified firmware to S3
2. Device downloads firmware
3. Bootloader verifies signature → RSA verify FAILS
4. Device publishes OTA status: `"status": "failed", "error_code": "invalid_signature"`
5. Verify device remains on v1.2.0 (no bank swap occurred)

Acceptance Criteria:
-  Invalid firmware never executed
-  Bank B erased after rejection
-  Device operational on original firmware

---

 Test 4: Battery Low Deferral

Preconditions:
- Device battery voltage = 2.9 V (below 3.0 V threshold)
- OTA campaign active

Steps:
1. Device receives OTA notification
2. Device checks battery voltage → below threshold
3. Device publishes OTA status: `"status": "deferred", "reason": "battery_low"`
4. Replace batteries (voltage → 4.2 V)
5. Device retries OTA on next cycle → proceeds normally

Acceptance Criteria:
-  OTA deferred when battery low (prevent bricking)
-  OTA resumes automatically after battery replacement
-  No user intervention required

---

 Test 5: Gateway Offline Resilience

Preconditions:
- Gateway loses internet connection mid-campaign
- Device not yet notified

Steps:
1. Disconnect gateway Ethernet cable
2. Cloud publishes OTA notification (device unreachable)
3. Gateway buffers notification in local MQTT queue (QoS 1)
4. Reconnect gateway after 2 hours
5. Gateway delivers buffered notification
6. Device proceeds with OTA normally

Acceptance Criteria:
-  OTA notification not lost during outage
-  Device receives update when connectivity restored
-  Campaign tracks device as "pending" (not failed)

---

 Test 6: Concurrent Multi-Device Rollout

Preconditions:
- Campaign targets 20 devices in BuildingA
- Phased rollout: 10% → 50% → 100% over 12 hours

Steps:
1. Phase 1: 2 devices receive notification at T+0
2. Monitor success rate (expect 100%)
3. Phase 2 (T+4h): 10 devices receive notification
4. Phase 3 (T+12h): Remaining 8 devices receive notification
5. Verify all 20 devices report `"status": "success"`

Expected Duration: 12 hours (phased rollout strategy)

Acceptance Criteria:
-  No more than 3 devices updating simultaneously (rate limiting)
-  100% success rate (no rollbacks)
-  Campaign dashboard shows real-time progress

---

 Monitoring and Alerting

 OTA Campaign Dashboard (Web UI)

Metrics Displayed:
- Campaign progress: 15/20 devices updated (75%)
- Phase status: Phase 2 in progress (50% target)
- Success rate: 14 success, 1 rollback, 0 failed
- Average duration: 11.3 minutes per device
- ETA: 2 hours 15 minutes (remaining 5 devices)

Real-Time Updates: WebSocket subscription to `{tenant}/campaigns/{campaign_id}/status`

 Alerts (AWS SNS)

Trigger Conditions:
- Rollback rate > 10%: Pause campaign, investigate faulty firmware
- Failure rate > 5%: Alert DevOps team, check gateway connectivity
- Individual device timeout > 30 minutes: Alert user to check physical device

---

 References

1. STMicroelectronics, AN4765: Application Note - Firmware Update Over-The-Air for STM32 MCUs, Rev 3, 2023.
2. ARM, PSA Certified Secure Boot, Platform Security Architecture, 2024. [Online]. Available: https://www.psacertified.org/
3. IETF, RFC 9019: A Firmware Update Architecture for IoT, June 2021.
4. OWASP, IoT Security Guidance: Secure Firmware Updates, 2024.
5. Mbed TLS, RSA Signature Verification API Documentation, v3.4.0, 2024.

---

Document Version: 1.0  
Last Updated: January 12, 2026  
Validated By: Firmware Team, Security Audit (Penetration Test: Zero P0/P1 findings)
