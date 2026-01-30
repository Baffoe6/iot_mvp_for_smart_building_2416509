 Device Hardware Design

 Overview

The sensing device is a battery-powered, wall-mounted unit that monitors CO₂ concentration, temperature, humidity, and occupancy in office spaces. The design prioritizes ultra-low power consumption to achieve ≥2-year battery lifetime while maintaining accuracy and reliability.

---

 Hardware Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    SENSOR DEVICE                             │
│                                                               │
│  ┌──────────┐      ┌──────────────────────────────────┐    │
│  │ Power    │──────│ STM32WB55 Microcontroller        │    │
│  │ Supply   │      │  - Cortex-M4 (64 MHz)            │    │
│  │          │      │  - Cortex-M0 (BLE stack)         │    │
│  │ 2×AA     │      │  - 1 MB Flash, 256 KB RAM        │    │
│  │ Lithium  │      │  - AES-256 crypto accelerator    │    │
│  │ (3.6V)   │      │  - RTC & low-power timer         │    │
│  │          │      │  - Watchdog timer                │    │
│  └────┬─────┘      └────────┬─────────────────────────┘    │
│       │                     │                               │
│       │  ┌──────────────────┼──────────────────────┐       │
│       │  │                  │                      │       │
│       ▼  ▼                  ▼                      ▼       │
│  ┌─────────────┐   ┌────────────────┐   ┌──────────────┐  │
│  │ LDO         │   │ Sensirion      │   │ Panasonic    │  │
│  │ Regulator   │   │ SCD40          │   │ EKMB PIR     │  │
│  │ (3.3V)      │   │ NDIR CO₂       │   │ Motion       │  │
│  │             │   │ + Temp/RH      │   │ Sensor       │  │
│  │ TPS62840    │   │ (I²C)          │   │ (Digital)    │  │
│  └─────────────┘   └────────────────┘   └──────────────┘  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ BLE 5.2 Radio (integrated in STM32WB55)               │ │
│  │  - 2.4 GHz ISM band                                    │ │
│  │  - Printed PCB antenna + U.FL for external (optional) │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────┐          ┌──────────────┐                  │
│  │ Status LED  │          │ Push Button  │                  │
│  │ (RGB)       │          │ (pairing)    │                  │
│  └─────────────┘          └──────────────┘                  │
└───────────────────────────────────────────────────────────────┘
```

---

 Component Selection Summary

| Component | Part Number | Key Specs | Unit Cost | Justification |
|-----------|-------------|-----------|-----------|---------------|
| MCU | STM32WB55RGV6 | Cortex-M4 @ 64 MHz, BLE 5.2, 1 MB Flash, 256 KB RAM, 0.6 µA deep sleep | £5.00 | Lowest cost with integrated BLE, excellent power efficiency, dual-core for BLE stack isolation |
| CO₂ Sensor | Sensirion SCD40 | NDIR, 400-5000 ppm, ±40 ppm ±3%, I²C, 18 mA @ 5s measurement | £12.00 | Best-in-class energy, auto-calibration (ASC), integrated temp/RH reduces BOM |
| PIR Sensor | Panasonic EKMB1301111 | 5 m range, <10 µA standby, digital output | £3.00 | Ultra-low power, mature technology, privacy-preserving |
| LDO Regulator | TI TPS62840 | 750 mA, 60 nA IQ, 80% efficiency at 10 µA load | £1.50 | Ultra-low quiescent current critical for battery life |
| Battery | 2× Energizer L91 (AA Lithium) | 3.6V nominal, 3000 mAh, -40 to +60°C | £4.00 | Long shelf life (20 years), low self-discharge (<0.5%/year), wide temp range |
| PCB + Enclosure | Custom 2-layer PCB, ABS enclosure | 80×60×25 mm, IP30, wall-mount | £5.00 | Standard manufacturing, adequate protection |
| Passives + Misc | Capacitors, resistors, antenna, connectors | — | £2.50 | Standard 0402/0603 SMD, ceramic chip antenna |
| TOTAL BOM | — | — | £33.00 | Under £50 target with £17 margin for assembly, testing, markup |

---

 Power Supply Architecture

 Battery Selection
- Chemistry: Lithium AA (L91) × 2 in series
- Nominal voltage: 3.6 V (1.8 V per cell)
- Capacity: 3000 mAh per cell
- Self-discharge: <0.5% per year (negligible over 2 years)
- Operating range: -40°C to +60°C (exceeds indoor office requirement)
- End-of-life voltage: 2.0 V (1.0 V per cell)

Rationale: Lithium AA cells offer the best energy density for the form factor, negligible self-discharge, and flat discharge curve. Alkaline cells have higher self-discharge (~3%/year) and steeper voltage drop, reducing usable capacity.

 Voltage Regulation
- Regulator: Texas Instruments TPS62840 (buck converter)
- Input range: 2.0-5.5 V (tolerates full battery discharge)
- Output: 3.3 V (MCU, sensors)
- Quiescent current: 60 nA (no load)
- Efficiency: 80% at 10 µA load, 90% at 1 mA load

Rationale: Quiescent current dominates standby power. TPS62840's 60 nA IQ is 100× lower than traditional LDOs (~5 µA), critical for 2-year battery life. Buck topology maintains efficiency across wide input range.

 Power Topology
```
Battery (2×AA)    TPS62840 Buck          STM32WB55 + Sensors
  3.6V nominal  ──►  3.3V regulated  ──►  VDD (MCU, SCD40, PIR)
  2.0V minimum                            VDDA (analog supply)
```

Load switching: GPIO-controlled MOSFET for SCD40 power domain (powered only during measurement) to eliminate quiescent current. PIR and MCU always powered.

---

 Sensor Integration

 1. Sensirion SCD40 CO₂ Sensor

Interface: I²C (address 0x62)

Measurement Strategy:
- Single-shot mode: Sensor powered on, 5-second measurement, powered off
- Duty cycle: Every 10 minutes (typical), 5 minutes (occupied), 15 minutes (vacant)
- Calibration: Automatic Self-Calibration (ASC) enabled; assumes 7-day exposure to fresh air (400 ppm)

Power Profile:
| State | Current | Duration | Energy |
|-------|---------|----------|--------|
| Powered off (MOSFET open) | 0 µA | 595 s (avg) | 0 mWh |
| Measurement (I²C active) | 18 mA | 5 s | 0.075 mWh |
| Average (10 min cycle) | 250 µA | — | 0.83 mWh/cycle |

Placement:
- Wall-mounted at 1.2-1.5 m height (breathing zone per ASHRAE 62.1)
- Away from windows (solar heating), HVAC vents (unrepresentative air), and doors (transient readings)
- Sensor opening facing room center, not obstructed

 2. Panasonic EKMB PIR Sensor

Interface: Digital GPIO (active high on motion detection)

Detection Parameters:
- Range: 5 m (covers typical office room ~20 m²)
- Field of view: 100° (wide angle for desk + door coverage)
- Re-trigger delay: 3 seconds (built-in timer in sensor)
- Sensitivity: Configurable via external resistor (set for seated human movement)

Power Profile:
- Standby: <10 µA (always on, waiting for motion)
- Active (when motion detected): ~15 µA (for 3 s duration)
- Average: ~10 µA continuous

Integration:
- GPIO interrupt (EXTI) on rising edge wakes MCU from deep sleep
- Debounce: firmware tracks last 3 events; motion = true if ≥2 detections in 60 s window
- Occupancy state machine: "occupied" if motion OR rising CO₂ (>50 ppm/10 min)

Placement:
- Ceiling or high wall mount (2.5-3 m) for overhead coverage
- Angled 45° downward toward desk area
- Avoid direct view of heaters, sunlight, or moving air (false triggers)

 3. Temperature and Humidity (from SCD40)

The SCD40 includes integrated temperature and relative humidity sensors on the same die:
- Temperature: ±0.8°C accuracy, sufficient for thermal comfort assessment
- Humidity: ±6% RH accuracy, adequate for condensation risk detection
- No additional cost or power: included with CO₂ sensor

Data Logging:
- Temperature and humidity logged at same interval as CO₂ (10 min typical)
- Used for:
  - Thermal comfort index calculation (ISO 7730)
  - SCD40 CO₂ measurement compensation (built-in)
  - HVAC feedback (heating/cooling demand)

---

 Microcontroller Configuration

 STM32WB55RGV6 Key Features

Core Architecture:
- Application processor: ARM Cortex-M4F @ 64 MHz (32-bit FPU)
- Radio processor: ARM Cortex-M0+ @ 32 MHz (dedicated BLE stack)
- Memory: 1 MB Flash (dual-bank for OTA), 256 KB SRAM
- Crypto: AES-128/256 hardware accelerator, PKA (public-key), RNG

Low-Power Modes:
| Mode | Current | RAM Retained | RTC Running | Wakeup Sources | Description |
|------|---------|--------------|-------------|----------------|-------------|
| Run | 50 µA/MHz | Yes | Yes | — | Active processing |
| Sleep | 5.3 mA | Yes | Yes | Any interrupt | CPU stopped, peripherals active |
| Stop 2 | 2.1 µA | Yes | Yes | RTC, EXTI, LPUART | All clocks stopped except LSE |
| Shutdown | 0.6 µA | No | Yes | RTC alarm, EXTI | Lowest power, RAM lost |
| Standby | 0.9 µA | 8 KB backup | Yes | RTC, EXTI | Partial RAM retention |

Selected Mode: Standby with 8 KB backup SRAM for state preservation (occupancy state, sensor calibration offsets, BLE pairing keys).

Wakeup Strategy:
- RTC alarm: Every 10 minutes for routine sensing and transmission
- GPIO EXTI: PIR sensor interrupt wakes MCU for immediate occupancy update (but does not transmit unless BLE connection interval open or alert threshold crossed)

 Peripheral Configuration

I²C1 (SCD40):
- Speed: 100 kHz (standard mode)
- Pull-ups: 4.7 kΩ external (sensor operates at 3.3 V)
- Power: GPIO-controlled P-channel MOSFET for SCD40 VDD switching

GPIO (PIR):
- Pin: PC13 (wakeup-capable EXTI line)
- Mode: Input with pull-down, interrupt on rising edge
- Debounce: Software (check stable for 100 ms)

RTC:
- Clock source: LSE (32.768 kHz external crystal, 2 ppm accuracy)
- Alarm A: Periodic wakeup (10 min interval)
- Backup domain: Powered by VBAT (battery directly) in shutdown, maintains time and alarm

BLE Radio:
- Antenna: Chip ceramic antenna (Johanson 2450AT18A100) on PCB + optional U.FL connector for external antenna
- TX power: 0 dBm (1 mW) for normal operation, +6 dBm for extended range if needed
- Advertising interval: 1 second (during pairing), 10 seconds (normal operation if not connected)
- Connection interval: 100 ms (balance latency and power; BLE 5 LE Data Length Extension for bulk data)

---

 Enclosure and Mechanical Design

 Enclosure Specifications
- Dimensions: 80 × 60 × 25 mm (compact, unobtrusive)
- Material: ABS plastic (white, matte finish)
- Ingress Protection: IP30 (protected against solid objects >2.5 mm; no water protection needed indoors)
- Mounting: Wall-mount with keyhole slots + 3M VHB tape backup
- Ventilation: Side vents for CO₂ sensor (passive convection, no forced airflow to preserve battery)

 Internal Layout
- PCB: Single 2-layer board (70 × 50 mm), bottom half of enclosure
- Battery holder: Top half, clip-style for easy replacement (no screws)
- Sensor position: SCD40 near side vent, PIR behind clear window (IR-transparent ABS or separate lens)
- Status LED: Small RGB LED on front face (indicates pairing mode, errors, low battery)
- Pairing button: Recessed button on bottom edge (requires paperclip to avoid accidental press)

 Environmental Compliance
- Operating temperature: 15-25°C (office environment)
- Storage temperature: -10 to +50°C (shipping, warehouse)
- Humidity: 20-60% RH non-condensing
- Safety: CE marking (RED 2014/53/EU for radio), RoHS compliant (lead-free solder)
- Battery safety: Overcurrent protection (PTC fuse), reverse polarity protection (diode), no charging circuitry (lithium primary cells)

---

 Battery Lifetime Calculation

 Power Budget (per 10-minute cycle)

| Component | State | Current | Duration | Energy (mWh) |
|-----------|-------|---------|----------|--------------|
| STM32WB55 | Standby | 0.9 µA | 598 s | 0.0015 |
| | Wakeup & process | 10 mA | 2 s | 0.0185 |
| SCD40 | Powered off | 0 µA | 595 s | 0 |
| | Measurement | 18 mA | 5 s | 0.075 |
| PIR EKMB | Standby | 10 µA | 600 s | 0.030 |
| TPS62840 LDO | Quiescent | 60 nA | 600 s | 0.0001 |
| BLE Radio | Advertising (1/10 min) | 10 mA | 0.5 s | 0.0046 |
| | Sleep | 0 µA | 599.5 s | 0 |
| TOTAL per cycle | — | — | 10 min | 0.1297 mWh |

 Annual Energy Consumption
- Cycles per year: 365 × 24 × 6 = 52,560 cycles
- Energy per year: 52,560 × 0.1297 = 6,817 mWh = 6.82 Wh

 Battery Capacity
- 2× AA lithium (L91): 3.6 V × 3000 mAh = 10.8 Wh
- Usable capacity (80% depth of discharge): 10.8 × 0.8 = 8.64 Wh

 Battery Lifetime
- Lifetime = 8.64 Wh ÷ 6.82 Wh/year = 1.27 years

 ISSUE: Does not meet 2-year target with 10-minute interval!

 Optimization to Achieve 2-Year Lifetime

Option 1: Increase sampling interval to 15 minutes
- Cycles per year: 365 × 24 × 4 = 35,040 cycles
- Energy per year: 35,040 × 0.1297 = 4,545 mWh = 4.54 Wh
- Lifetime: 8.64 ÷ 4.54 = 1.90 years (close, but still short)

Option 2: Adaptive sampling + 15-minute base interval
- Vacant mode (PIR idle for >30 min): 20-minute CO₂ checks
  - Assume 40% of time vacant: 0.4 × (365 × 24 × 3) = 10,512 cycles
- Occupied mode (PIR active): 10-minute CO₂ checks
  - Assume 60% of time occupied: 0.6 × (365 × 24 × 6) = 31,536 cycles
- Total cycles: 10,512 + 31,536 = 42,048 cycles
- Energy per year: 42,048 × 0.1297 = 5,454 mWh = 5.45 Wh
- Lifetime: 8.64 ÷ 5.45 = 1.58 years (still short)

Option 3: Reduce BLE advertising + adaptive sampling
- BLE advertising only when data ready (not continuous beacon)
- Use connection-less advertisement (no maintain connection overhead)
- Advertising energy drops from 0.0046 to 0.0023 mWh/cycle
- New total per cycle: 0.1297 - 0.0023 = 0.1274 mWh
- With adaptive sampling (42,048 cycles): 42,048 × 0.1274 = 5,357 mWh = 5.36 Wh/year
- Lifetime: 8.64 ÷ 5.36 = 1.61 years

Option 4: Larger battery (3× AA cells)
- Capacity: 3.6 V × 4500 mAh = 16.2 Wh usable = 12.96 Wh
- Lifetime: 12.96 ÷ 5.36 = 2.42 years - BOM impact: +£2 (one extra cell), enclosure size +10 mm

RECOMMENDATION: 
- Use 3× AA lithium cells (increase enclosure to 90 × 60 × 25 mm)
- Implement adaptive sampling (10 min occupied, 20 min vacant)
- Use connection-less BLE advertisements (gateway scans passively)
- Final BOM: £33 + £2 = £35 (still under £50 target)
- Achieved lifetime: 2.4 years (20% margin over 2-year requirement)

---

 Design Validation and Testing

 Prototype Development
1. Proof-of-concept: STM32WB55 Nucleo board + SCD40 breakout + PIR module
2. Custom PCB v1.0: 2-layer board, hand assembly, firmware development
3. Pilot batch: 10 units for field testing (one office floor, 4 weeks)

 Key Tests
- Power consumption measurement: Bench test with Otii Arc power analyzer, verify <6 Wh/year average
- CO₂ accuracy: Compare against calibrated Vaisala GMP252 reference in controlled chamber
- PIR sensitivity: Test detection distance, false positive rate (heater, sunlight), false negative rate (stationary occupant)
- BLE range: Measure RSSI vs. distance, identify dead zones, validate 30 m minimum through office partitions
- Battery lifetime: Accelerated test (1 min = 1 day simulation via firmware time scaling), project to 2 years
- Temperature cycling: -10 to +40°C, 10 cycles, verify no solder joint failures, sensor drift <2%
- Drop test: 1 m drop onto concrete, 5 samples, verify enclosure integrity and continued operation

---

 Bill of Materials (BOM) - Final

| Item | Part Number | Qty | Unit Cost | Extended | Notes |
|------|-------------|-----|-----------|----------|-------|
| MCU | STM32WB55RGV6 | 1 | £5.00 | £5.00 | |
| CO₂ sensor | Sensirion SCD40 | 1 | £12.00 | £12.00 | |
| PIR sensor | Panasonic EKMB1301111 | 1 | £3.00 | £3.00 | |
| LDO | TI TPS62840 | 1 | £1.50 | £1.50 | |
| Battery | Energizer L91 AA Lithium | 3 | £2.00 | £6.00 | Updated to 3 cells |
| PCB | 2-layer, 70×50 mm | 1 | £2.50 | £2.50 | Qty 100 pricing |
| Enclosure | ABS, 90×60×25 mm | 1 | £3.00 | £3.00 | Injection molded |
| Antenna | Johanson 2450AT18A100 | 1 | £0.50 | £0.50 | Chip ceramic |
| Passives | Capacitors, resistors, LED | — | £2.00 | £2.00 | 0402/0603 SMD |
| Connectors | Battery holder, U.FL | — | £0.50 | £0.50 | |
| TOTAL | | | | £35.00 | Under £50 target |

Additional Costs (not in BOM):
- Assembly: £3/unit (pick-and-place + reflow + inspection)
- Testing: £1/unit (functional test + power measurement)
- Packaging: £0.50/unit
- Manufacturing cost: £35 + £4.50 = £39.50
- Target retail: £39.50 × 2.0 markup = £79 (end-user price, within market range for commercial BMS sensors)

---

 Related Documents

- [Firmware Architecture](firmware_architecture.md) – Software design, FreeRTOS tasks, OTA overview.
- [Communications Design](communications_design.md) – BLE and MQTT gateway details.
- [Power Budget (Appendix)](../../appendices/power_budget.md) – Detailed power calculations and validation.
- [INDEX](../../INDEX.md) – Full document map and keyword search.
