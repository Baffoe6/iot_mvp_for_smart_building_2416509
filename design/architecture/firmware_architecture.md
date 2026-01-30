 Firmware Architecture and Secure OTA Updates

 Overview

The device firmware is designed around an event-driven architecture with ultra-low-power operation as the primary constraint. All major functions (sensing, communication, OTA updates) are scheduled by the RTC and executed in short bursts before returning to Standby mode.

Key Design Principles:
1. Energy-first: Every decision optimizes for minimum active time and deepest sleep
2. Fail-safe: Watchdog timers, error recovery, and rollback mechanisms prevent bricking
3. Secure by design: Encrypted communications, signed firmware, secure boot
4. Maintainable: Modular structure, clear separation of concerns, comprehensive logging

---

 Firmware Architecture

 Software Stack

```
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Sensing Task │  │ Comms Task   │  │ OTA Task     │  │
│  │ (CO₂, PIR)   │  │ (BLE GATT)   │  │ (bootloader) │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│                  Middleware / HAL                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Sensor       │  │ BLE Stack    │  │ Crypto       │  │
│  │ Drivers      │  │ (STM32WB)    │  │ (mbedTLS)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    RTOS (FreeRTOS)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Task         │  │ Timers       │  │ Queue / Sem  │  │
│  │ Scheduler    │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│              STM32 HAL / Low-Level Drivers               │
│  (I²C, GPIO, RTC, Flash, Power Management, Watchdog)    │
└─────────────────────────────────────────────────────────┘
```

 RTOS Selection: FreeRTOS

Rationale:
- Tickless idle: Integrates with STM32 low-power modes (Standby, Stop)
- Small footprint: ~10 KB Flash, ~1 KB RAM overhead
- STM32 integration: ST provides optimized port (STM32CubeMX generates configuration)
- Mature ecosystem: Widely used in commercial IoT devices, extensive documentation
- MIT license: No licensing fees or restrictions

Alternatives considered:
- Zephyr RTOS: More modern, better power management API, but larger footprint (~50 KB) and steeper learning curve
- Bare-metal: Minimal overhead but complex state machine for managing sleep, tasks, and interrupts—error-prone

---

 Task Structure

 Task 1: Sensing Task (Priority: High)

Responsibilities:
- Wakeup from RTC alarm (every 10-20 minutes, adaptive)
- Power on SCD40 via GPIO-controlled MOSFET
- Initiate I²C transaction: start measurement, wait 5 seconds, read CO₂/temp/RH
- Read PIR status (check for motion events since last cycle)
- Apply Automatic Self-Calibration (ASC) correction to CO₂ reading
- Store readings in circular buffer (RAM, 24 samples = 4 hours @ 10 min interval)
- Check alert thresholds (CO₂ >1200 ppm, temp >27°C)
- If alert, set flag for immediate BLE transmission
- If routine, wait for next BLE connection interval
- Power off SCD40, return to sleep

Pseudocode:
```c
void vSensingTask(void pvParameters) {
    while (1) {
        // Wait for RTC alarm event (FreeRTOS queue)
        xQueueReceive(xRTCAlarmQueue, &wakeup_event, portMAX_DELAY);
        
        // Power on SCD40
        HAL_GPIO_WritePin(SCD40_PWR_EN, GPIO_PIN_SET);
        vTaskDelay(pdMS_TO_TICKS(30)); // Sensor init time
        
        // Start CO₂ measurement
        SCD40_StartMeasurement();
        vTaskDelay(pdMS_TO_TICKS(5000)); // Wait for NDIR reading
        
        // Read sensor data
        sensor_data_t data;
        SCD40_ReadMeasurement(&data.co2_ppm, &data.temp_c, &data.rh_percent);
        
        // Read PIR status
        data.occupancy = HAL_GPIO_ReadPin(PIR_OUT);
        
        // Timestamp
        data.timestamp = HAL_RTCEx_BKUPRead(&hrtc, RTC_BKP_DR0);
        
        // Power off SCD40
        HAL_GPIO_WritePin(SCD40_PWR_EN, GPIO_PIN_RESET);
        
        // Store in buffer
        CircularBuffer_Push(&sensor_buffer, &data);
        
        // Check thresholds
        if (data.co2_ppm > 1200 || data.temp_c > 27.0) {
            xEventGroupSetBits(xAlertEventGroup, ALERT_BIT);
        }
        
        // Determine next wakeup interval (adaptive)
        uint32_t next_interval = (data.occupancy) ? 600 : 1200; // 10 or 20 min
        HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, next_interval, RTC_WAKEUPCLOCK_CK_SPRE_16BITS);
        
        // Notify Comms task
        xTaskNotifyGive(xCommsTaskHandle);
    }
}
```

Error Handling:
- If I²C timeout (sensor non-responsive): Retry once, then log error and use last valid reading
- If out-of-range reading (e.g., CO₂ = 0 or >5000 ppm): Mark as invalid, do not transmit, increment error counter
- If 3 consecutive errors: Send error report via BLE, consider sensor fault

---

 Task 2: Communications Task (Priority: Medium)

Responsibilities:
- Manage BLE connection with gateway
- Advertise device presence (connection-less mode for energy efficiency)
- When gateway connects: authenticate, send buffered sensor data via GATT notifications
- Implement retry logic with exponential backoff if transmission fails
- Handle OTA update requests from gateway
- Maintain connection statistics (RSSI, packet loss, retries)

BLE GATT Service Design:

| Service | UUID | Characteristics | Description |
|---------|------|-----------------|-------------|
| Environmental Sensing | 0x181A (standard) | Temperature, Humidity, CO₂ | Read + Notify |
| Custom Occupancy | 0xABCD (vendor-specific) | Occupancy State, Motion Count | Read + Notify |
| Device Info | 0x180A (standard) | Model, Serial, Firmware Version | Read-only |
| OTA Service | 0xEFAB (custom) | OTA Control, Firmware Data | Write + Indicate |

Connection Strategy:
- Advertising mode: Non-connectable advertisements (broadcast sensor data in ADV payload) every 10 seconds
- Connection mode: If gateway needs to pull buffered data or initiate OTA, it connects (connection interval 100 ms, slave latency 4, timeout 4 s)
- Energy optimization: Connection-less mode avoids connection overhead (~5 mA continuous for connection maintenance)

Pseudocode:
```c
void vCommsTask(void pvParameters) {
    // Initialize BLE stack
    BLE_Init();
    BLE_SetAdvertisingData(&sensor_data_latest);
    BLE_StartAdvertising();
    
    while (1) {
        // Wait for notification from Sensing task or BLE event
        ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(10000)); // 10 s timeout
        
        // Update advertising payload with latest sensor data
        BLE_UpdateAdvertisingData(&sensor_data_latest);
        
        // Check for alert flag
        if (xEventGroupGetBits(xAlertEventGroup) & ALERT_BIT) {
            // Switch to connectable mode, wait for gateway to pull data
            BLE_StartConnectableAdvertising();
            // Wait for connection, send alert, then disconnect
            xEventGroupClearBits(xAlertEventGroup, ALERT_BIT);
        }
        
        // If connected: handle GATT read/write/notify
        if (BLE_IsConnected()) {
            // Send all buffered data (notifications)
            while (!CircularBuffer_IsEmpty(&sensor_buffer)) {
                sensor_data_t data;
                CircularBuffer_Pop(&sensor_buffer, &data);
                BLE_SendNotification(CHAR_HANDLE_CO2, &data, sizeof(data));
                vTaskDelay(pdMS_TO_TICKS(50)); // BLE throughput pacing
            }
            // Disconnect to save power
            BLE_Disconnect();
        }
    }
}
```

Security:
- BLE pairing: LE Secure Connections (ECDH key exchange), Just Works or Passkey entry
- Bonding: Store pairing keys in backup SRAM (survives Standby mode) and encrypted Flash
- Whitelist: Only allow connections from known gateway MAC addresses (set during provisioning)

---

 Task 3: Watchdog and Error Handling (Priority: Highest)

Responsibilities:
- Independent watchdog timer (IWDG) with 30-second timeout
- Feed watchdog every 20 seconds from main loop (if all tasks healthy)
- If watchdog expires: system reset, increment reset counter in backup register
- If >3 consecutive watchdog resets: enter safe mode (disable sensors, BLE beacon SOS, wait for OTA recovery)

Implementation:
- IWDG clocked by LSI (32 kHz), prescaler 256, reload value 3750 → 30 s timeout
- Each task sets a "health" bit in shared event group before sleeping
- Watchdog task checks all bits set, feeds IWDG, clears bits

Pseudocode:
```c
void vWatchdogTask(void pvParameters) {
    HAL_IWDG_Init(&hiwdg); // Start watchdog
    
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(20000)); // 20 s period
        
        // Check if all tasks reported healthy
        EventBits_t health = xEventGroupGetBits(xHealthEventGroup);
        if ((health & ALL_TASKS_HEALTHY) == ALL_TASKS_HEALTHY) {
            HAL_IWDG_Refresh(&hiwdg); // Feed the dog
            xEventGroupClearBits(xHealthEventGroup, ALL_TASKS_HEALTHY);
        } else {
            // Task(s) hung: log error, attempt recovery (skip this cycle)
            LogError("Task health check failed: 0x%02X", health);
        }
    }
}
```

---

 Power Management Strategy

 Sleep Entry Procedure
1. Complete all pending I²C transactions (flush buffers)
2. Disable unnecessary peripherals (I²C, SPI, unused GPIO)
3. Configure wakeup sources:
   - RTC alarm (next scheduled sensor reading)
   - EXTI (PIR motion interrupt)
   - BLE radio wakeup (if connection active)
4. Set next RTC alarm (adaptive interval: 10, 15, or 20 min)
5. Enter Standby mode with backup SRAM retention:
   ```c
   HAL_PWR_EnterSTANDBYMode();
   ```
6. On wakeup: Resume from reset vector (not from sleep return point)
7. Check reset source: RTC alarm vs. PIR vs. watchdog
8. Restore state from backup SRAM: sensor calibration, occupancy state, BLE bonding info

 State Preservation (Backup SRAM, 8 KB)
```c
typedef struct {
    uint32_t magic_number;           // 0xDEADBEEF (verify integrity)
    uint32_t firmware_version;       // For compatibility check after OTA
    uint32_t sensor_calibration_offset;
    uint32_t occupancy_state;        // Last known occupancy
    uint32_t ble_bonding_keys[8];   // Encrypted pairing keys
    uint32_t error_counters[4];      // I²C, BLE, watchdog, sensor faults
    uint32_t total_runtime_hours;    // Uptime tracking
    uint32_t crc32;                  // Data integrity
} backup_state_t;
```

Rationale for Standby over Stop 2:
- Standby: 0.9 µA, 8 KB backup SRAM retained, RTC and wakeup sources active
- Stop 2: 2.1 µA, full SRAM retained but more complex resume (double power, marginal benefit)

---

 Secure Over-the-Air (OTA) Updates

 OTA Architecture

Goals:
1. Secure: Only signed firmware images from trusted source
2. Reliable: Rollback to previous version if update fails
3. Efficient: Minimize device downtime and energy consumption during update

Dual-Bank Flash Layout (STM32WB55, 1 MB total):

| Address | Size | Purpose |
|---------|------|---------|
| 0x0800 0000 | 128 KB | Bootloader (secure, read-only) |
| 0x0802 0000 | 384 KB | Bank A (active firmware) |
| 0x0808 0000 | 384 KB | Bank B (update staging) |
| 0x080E 0000 | 128 KB | Configuration + logs (persistent) |

Update Flow:

```
┌──────────────┐
│  1. Gateway  │  Checks for new firmware (cloud API)
│  sends OTA   │  Compares device FW version vs. latest
│  notification│  Initiates OTA if newer available
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  2. Device   │  Receives OTA metadata (version, size, signature)
│  validates   │  Verifies signature with public key (stored in bootloader)
│  metadata    │  Checks sufficient battery (>30%), not already updating
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  3. Download │  Gateway sends firmware in 4 KB chunks over BLE
│  firmware to │  Device writes to Bank B (inactive)
│  Bank B      │  Verifies each chunk with CRC32
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  4. Verify   │  Compute SHA-256 hash of entire Bank B image
│  full image  │  Compare against metadata signature
│  signature   │  If match: mark Bank B as "pending boot"
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  5. Reboot   │  System reset
│  to          │  Bootloader checks for "pending boot" flag
│  bootloader  │  Verifies Bank B signature again (defense in depth)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  6. Swap     │  Bootloader remaps Bank B to 0x0802 0000 (active)
│  banks and   │  Boots new firmware from Bank B
│  boot new FW │  Old firmware remains in Bank A (rollback safety)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  7. Validate │  New firmware runs self-test (sensor I²C, BLE stack, RTC)
│  new FW      │  If all pass: mark Bank B as "confirmed good"
│  (first boot)│  If fail: bootloader detects and auto-rollback to Bank A
└──────────────┘
```

 Cryptographic Security

Firmware Signing (Build-Time):
1. Developer builds firmware binary (`app.bin`)
2. Compute SHA-256 hash: `H = SHA256(app.bin)`
3. Sign hash with RSA-2048 private key (kept secure, offline): `S = RSA_sign(H, private_key)`
4. Package metadata: `{version, size, H, S}` → `app_metadata.json`
5. Upload `app.bin` + `app_metadata.json` to cloud storage

Signature Verification (Device-Side):
1. Device stores RSA-2048 public key in bootloader (read-only Flash, set during manufacturing)
2. On OTA metadata receive: `H_claimed = metadata.hash`, `S_claimed = metadata.signature`
3. Compute actual hash: `H_actual = SHA256(downloaded_image)`
4. Verify signature: `RSA_verify(H_claimed, S_claimed, public_key)` → true/false
5. Compare hashes: `H_actual == H_claimed`
6. Only if both pass: proceed with flash write

Key Storage:
- Public key: Embedded in bootloader at address 0x0801F000 (last page of bootloader, write-protected)
- Private key: Never stored on device; kept on secure build server with HSM (hardware security module)

 Rollback Mechanism

Scenario: New firmware boots but fails self-test (e.g., I²C bus lockup, BLE stack crash)

Detection:
- Bootloader sets "pending confirmation" flag after swapping banks
- New firmware must call `OTA_ConfirmUpdate()` within 5 minutes (10 boot cycles)
- If not confirmed: bootloader increments "boot failure counter"
- If counter reaches 3: automatic rollback to Bank A (old, known-good firmware)

Implementation:
```c
// In new firmware, after successful self-test:
void OTA_ConfirmUpdate(void) {
    // Write "confirmed" flag to backup register
    HAL_RTCEx_BKUPWrite(&hrtc, RTC_BKP_DR10, OTA_CONFIRMED_MAGIC);
    // Reset boot failure counter
    HAL_RTCEx_BKUPWrite(&hrtc, RTC_BKP_DR11, 0);
}

// In bootloader, before jumping to application:
void Bootloader_CheckOTA(void) {
    uint32_t ota_status = HAL_RTCEx_BKUPRead(&hrtc, RTC_BKP_DR10);
    uint32_t boot_failures = HAL_RTCEx_BKUPRead(&hrtc, RTC_BKP_DR11);
    
    if (ota_status == OTA_PENDING_CONFIRMATION) {
        boot_failures++;
        HAL_RTCEx_BKUPWrite(&hrtc, RTC_BKP_DR11, boot_failures);
        
        if (boot_failures >= 3) {
            // Rollback: swap banks back to Bank A
            Flash_SwapBanks();
            HAL_RTCEx_BKUPWrite(&hrtc, RTC_BKP_DR10, OTA_ROLLBACK);
        }
    }
}
```

 OTA Energy Budget

Per 4 KB chunk:
- BLE RX: 10 mA × 200 ms = 2 mJ
- Flash write: 15 mA × 50 ms = 0.75 mJ
- Total per chunk: 2.75 mJ

Full firmware update (384 KB):
- Chunks: 384 / 4 = 96 chunks
- Energy: 96 × 2.75 mJ = 264 mJ = 0.073 mWh
- Battery impact: 0.073 / 8,640 mWh total = 0.0008% (negligible; one OTA update per device lifetime acceptable)

Constraint: Only allow OTA if battery voltage >3.0 V (>30% remaining) to avoid mid-flash power loss and bricking.

---

 Logging and Diagnostics

 Log Levels
- ERROR: Critical failures (watchdog reset, sensor fault, OTA failure)
- WARN: Non-critical issues (missed BLE connection, single I²C retry)
- INFO: State changes (occupancy detected, CO₂ threshold crossed)
- DEBUG: Detailed traces (only enabled in development builds)

 Log Storage
- Circular buffer in Flash: Last 16 KB (persistent across reboots)
- Backup SRAM counters: Error counts, uptime, reset reasons
- BLE GATT characteristic: "Log Stream" allows gateway to pull logs on demand

 Remote Diagnostics
- Gateway can request:
  - Last 100 log entries (via BLE GATT read)
  - Battery voltage (ADC measurement)
  - RSSI and connection statistics
  - Sensor calibration status (SCD40 ASC state)
- Useful for troubleshooting field deployments without physical access

---

 Development Tools and Workflow

 Toolchain
- IDE: STM32CubeIDE (Eclipse-based, free, includes debugger)
- Compiler: GCC ARM Embedded (arm-none-eabi-gcc)
- Debugger: ST-Link V3 (SWD interface, ~£25)
- Power profiler: Otii Arc (real-time current measurement, ~£500)

 Version Control
- Git repository: Separate branches for `main` (release), `develop` (integration), `feature/` (development)
- Semantic versioning: `vMAJOR.MINOR.PATCH` (e.g., v1.0.0 for MVP release)

 Build Automation
- CI/CD: GitHub Actions triggers on commit to `main`:
  1. Compile firmware for all configurations (debug, release)
  2. Run unit tests (on-host with Ceedling)
  3. Run static analysis (Cppcheck, Coverity)
  4. Sign firmware image with RSA key (from CI secrets)
  5. Upload `app.bin` + `app_metadata.json` to AWS S3
  6. Notify gateway API of new firmware version

 Testing Strategy
- Unit tests: Mock HAL functions, test business logic (sensor parsing, circular buffer, state machine)
- Integration tests: Run on Nucleo board, verify I²C, BLE, RTC, power modes
- Field tests: 10-device pilot, 4 weeks, collect power logs, error rates, user feedback

---

 Summary: Key Firmware Characteristics

| Aspect | Implementation | Justification |
|--------|----------------|---------------|
| Architecture | FreeRTOS with 3 tasks (Sensing, Comms, Watchdog) | Structured, maintainable, power-optimized with tickless idle |
| Power mode | Standby (0.9 µA) with backup SRAM | Lowest power while preserving critical state |
| Sensor strategy | Adaptive sampling (10/20 min) + GPIO power switch | Balances responsiveness and battery life |
| BLE mode | Connection-less advertisements (broadcast) | Avoids connection overhead (~5 mA continuous) |
| Security | TLS over BLE, RSA-2048 signed firmware | Defends against MITM, firmware tampering |
| OTA reliability | Dual-bank flash, signature verification, auto-rollback | Prevents bricking, ensures recoverability |
| Error handling | Watchdog, retry logic, safe mode | Resilient to transient faults, field-maintainable |
| Logging | Persistent Flash log + BLE diagnostics | Remote troubleshooting without physical access |

---

 Related Documents

- [Communications Design](communications_design.md) – BLE GATT service details and MQTT topic schema.
- [Cloud Architecture](cloud_architecture.md) – Backend data pipeline and storage.
- [OTA Updates (Appendix)](../../appendices/ota_updates.md) – Detailed OTA flow diagrams and test cases.
- [INDEX](../../INDEX.md) – Full document map and keyword search.
