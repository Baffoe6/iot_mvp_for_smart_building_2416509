Title: Smart Building Air Quality and Occupancy Monitoring IoT MVP: A Research-Led End-to-End System Design

Author: Lord Kingsley Baffoe
Date: January 2026
Student Number: 2416509

1. Introduction

Commercial buildings represent a major share of energy consumption, and HVAC systems frequently account for a substantial portion of this demand (ASHRAE, 2023). Many building management systems still operate using fixed schedules rather than real occupancy conditions, which can lead to unnecessary energy waste and inconsistent indoor environmental quality. Indoor air quality research shows that elevated CO₂ concentrations (commonly above 1000 ppm) can reduce cognitive performance and impair decision-making, with direct implications for occupant productivity and wellbeing (Allen et al., 2016; Satish et al., 2012). These findings justify the development of practical monitoring solutions that enable facilities managers to align ventilation and HVAC scheduling with actual space utilisation.

This report presents a battery-powered Internet of Things (IoT) minimum viable product (MVP) for real-time air quality and occupancy monitoring in commercial office environments. The guiding research question is: How can cost-effective, ultra-low-power IoT deployments optimise HVAC operation while maintaining indoor environmental quality standards? The MVP is designed around three priorities: (1) ultra-low power consumption to exceed a two-year battery life, (2) affordability with a bill of materials (BOM) under £50, and (3) privacy preservation through deliberate avoidance of personal data collection (Cavoukian, 2011). The system design is justified through an evidence-led approach using literature, standards, and a weighted decision framework for technology selection.

1.1 System Objectives and Architecture

Battery-powered sensor nodes are deployed across approximately 500–1000 m² of office space to measure CO₂, temperature, humidity, and binary occupancy status (presence/absence only). Sensor nodes transmit data using Bluetooth Low Energy (BLE) 5.2 connection-less advertisements, chosen for low energy per transmission and operational simplicity (Bluetooth SIG, 2019). Raspberry Pi gateways capture BLE messages and forward telemetry to the cloud using MQTT secured with TLS, enabling a scalable publish–subscribe pipeline with reliable delivery guarantees (Banks and Gupta, 2019). Cloud services store and process data, presenting dashboards for facilities management and generating alerts when indoor environmental thresholds are exceeded.

Four measurable objectives guide validation: (1) demonstrate 15–30% HVAC energy reduction via occupancy-aware scheduling (ASHRAE, 2023), (2) maintain CO₂ concentrations below 1000 ppm during occupied periods to align with ventilation and indoor air quality expectations (ASHRAE, 2019), (3) achieve a carbon payback period where energy savings exceed embodied and operational carbon within six months, and (4) deliver a return on investment within 18 months at a target retail price of £79 per device.

1.2 Scope Definition and Design Constraints

The MVP scope covers end-to-end implementation, including sensor node hardware selection, firmware design, gateway software, and a secure cloud data pipeline. The sensing stack is based on the Sensirion SCD40 for CO₂/temperature/humidity measurement (Sensirion, 2024) and the STM32WB55 for low-power compute and integrated BLE connectivity (STMicroelectronics, 2023). OTA update capability is included to support maintainability and security patching over multi-year lifetimes (ARM, 2022). The gateway bridges BLE telemetry into an MQTT/TLS cloud pipeline (Banks and Gupta, 2019), and dashboards provide operational visibility. The MVP explicitly excludes direct HVAC actuation to reduce integration complexity and deployment risk for an initial research-led prototype.

Constraints strongly shape design choices. The power budget targets average current consumption below 50 µA to exceed two years of operation on AA lithium batteries (Energizer, 2023). Cost constraints limit the BOM to £50. Performance constraints include telemetry intervals typically in the 10–15 minute range, alert delivery within five minutes, and sensing accuracy sufficient for practical indoor air quality decisions (ASHRAE, 2019; Sensirion, 2024).

2. Literature Review and Evidence-Based Technology Selection
2.1 Review Methodology

A structured review of peer-reviewed research, standards documentation, and manufacturer datasheets was conducted to identify validated approaches to indoor air quality monitoring, low-power wireless sensor systems, and secure IoT architectures. Standards and best-practice guidance were prioritised for HVAC and indoor air quality requirements (ASHRAE, 2019; ASHRAE, 2023), BLE performance characteristics (Bluetooth SIG, 2019), IoT messaging (Banks and Gupta, 2019), secure update mechanisms (ARM, 2022), and privacy-by-design principles (Cavoukian, 2011). GDPR principles were used to guide decisions around data minimisation and system design (European Parliament, 2016). The final evidence base focused on reproducible, deployable approaches suitable for commercial environments rather than hobby-grade prototypes.

2.2 Multi-Criteria Decision Analysis

CO₂ Sensor Selection. NDIR CO₂ sensing was selected due to its established performance for indoor monitoring and ventilation applications. The Sensirion SCD40 was chosen because it combines CO₂ with integrated temperature/humidity sensing and provides low-power operating modes that align with multi-year battery targets (Sensirion, 2024). Its accuracy specification and calibration approach support practical indoor air quality measurement requirements (ASHRAE, 2019; Sensirion, 2024).

Microcontroller Selection. The STM32WB55 was selected for its integrated BLE radio and low-power modes that support sub-µA sleep operation (STMicroelectronics, 2023). Its dual-bank Flash design enables robust OTA updates, supporting secure boot and safe rollback patterns recommended in embedded security guidance (ARM, 2022). This reduces operational risk and improves long-term maintainability in field deployments.

Communication Protocol Selection. BLE 5.2 advertisements were selected for sensor-to-gateway communication to minimise device power consumption and simplify provisioning. BLE operates in the globally available 2.4 GHz ISM band and is widely supported by commodity gateway devices, reducing infrastructure cost and complexity (Bluetooth SIG, 2019). The gateway then publishes telemetry to the cloud using MQTT over TLS to leverage a mature IoT messaging model with efficient publish–subscribe semantics and reliability options (Banks and Gupta, 2019). TLS adoption aligns with modern secure transport expectations and standards for protecting data in transit (Internet Engineering Task Force, 2018).

3. End-to-End System Architecture and Implementation
3.1 Sensor Node Design and Power Optimisation

Each sensor node integrates: (1) the Sensirion SCD40 for CO₂/temperature/humidity (Sensirion, 2024), (2) a low-power PIR sensor for binary occupancy, (3) the STM32WB55 microcontroller with BLE radio (STMicroelectronics, 2023), (4) an efficient power regulation stage optimised for low quiescent current, and (5) AA lithium batteries selected for stable discharge characteristics and suitability for low-power devices (Energizer, 2023). The node is designed for wall mounting and indoor operation, focusing on office environments where occupancy patterns can be used to inform ventilation scheduling (ASHRAE, 2023).

Power efficiency is achieved by keeping the MCU in deep sleep for the majority of time, waking only to sample sensors and transmit a brief BLE advertisement. Adaptive sampling increases measurement frequency during occupied periods and reduces it when vacant, aligning sensing effort to building use and supporting battery lifetime objectives. This strategy is consistent with low-power wireless sensor network design principles where duty cycling dominates lifetime performance (Bluetooth SIG, 2019; STMicroelectronics, 2023).

3.2 Firmware Architecture and Secure OTA Updates

Firmware is structured into tasks responsible for sensing, communication, and health supervision. Sensor measurement scheduling uses RTC-based wake events to minimise active time, while the communications logic broadcasts compact telemetry payloads through BLE advertisements (Bluetooth SIG, 2019). Secure OTA updates leverage the dual-bank Flash architecture of the STM32WB55, enabling staged update, integrity verification, and safe rollback. This aligns with secure firmware update practices and reduces the likelihood of bricking devices in the field (ARM, 2022; STMicroelectronics, 2023). Cryptographic signing supports control over software provenance and mitigates unauthorised firmware injection risks (ARM, 2022).

3.3 Gateway and Cloud Data Pipeline

Gateways bridge BLE advertisements into a secure cloud pipeline using MQTT (Banks and Gupta, 2019). Data in transit is protected using TLS, aligning with modern transport security expectations (Internet Engineering Task Force, 2018). Cloud ingestion and storage are implemented using a time-series approach suitable for frequent sensor measurements and trend analysis. Alert logic detects threshold exceedances such as high CO₂ levels and abnormal temperature, supporting indoor air quality oversight and proactive facilities response (ASHRAE, 2019). This architecture follows established IoT design patterns combining low-power edge devices with gateways and cloud-based analytics and dashboards (Banks and Gupta, 2019; Bluetooth SIG, 2019).

4. Security, Privacy, and Sustainability
4.1 Cybersecurity Controls

Security controls focus on firmware integrity, secure transport, and authenticated access. Signed firmware updates and controlled boot processes reduce the risk of persistent compromise via malicious updates (ARM, 2022). MQTT communication is protected by TLS to mitigate interception and manipulation threats (Internet Engineering Task Force, 2018; Banks and Gupta, 2019). Access to dashboards and APIs should be authenticated and authorised to prevent cross-tenant data exposure, aligning with general secure system design principles for multi-user platforms.

4.2 Privacy-by-Design

Privacy-by-design is implemented by limiting occupancy sensing to binary presence/absence and excluding identity-linked data sources such as cameras or device tracking. This approach reduces privacy risk by preventing personal identification and minimising behavioural profiling potential (Cavoukian, 2011). Under GDPR principles, environmental data tied to building spaces is generally distinct from personal data, while account information for facilities users requires appropriate governance and retention controls (European Parliament, 2016). The design therefore minimises the collection of personal data and supports compliance by reducing processing scope.

4.3 Environmental Sustainability

Sustainability is assessed by comparing embodied and operational impacts against energy savings potential. HVAC optimisation informed by occupancy and CO₂ data can reduce runtime and energy use, supporting carbon reduction objectives (ASHRAE, 2023). Battery selection and replacement capability can extend device life, reducing premature disposal and aligning with practical lifecycle management principles (Energizer, 2023). Broader circular economy alignment is consistent with regulatory expectations around electronic waste reduction and end-of-life management (European Parliament, 2012).

5. Validation and Performance Evaluation

Validation focuses on power performance, sensing accuracy, end-to-end latency, and reliability. CO₂ measurements are assessed against the accuracy characteristics of the selected sensor platform (Sensirion, 2024) and aligned with indoor air quality threshold expectations used in ventilation practice (ASHRAE, 2019). Duty-cycled operation and low-power modes are verified against MCU and BLE platform capabilities (STMicroelectronics, 2023; Bluetooth SIG, 2019). Transport reliability and messaging semantics align with MQTT QoS concepts and secure transport requirements (Banks and Gupta, 2019; Internet Engineering Task Force, 2018). User acceptance is evaluated through dashboard usability and the operational usefulness of alerts for facilities management in real workflows.

6. Conclusion, Limitations, and Future Development

This research-led IoT MVP demonstrates a feasible approach to indoor air quality and occupancy monitoring for smart building optimisation. Evidence-based selection of sensing, embedded compute, BLE communication, and secure IoT messaging supports an end-to-end architecture appropriate for a monitoring-first MVP (Bluetooth SIG, 2019; Banks and Gupta, 2019; Sensirion, 2024; STMicroelectronics, 2023). The design aligns with indoor air quality expectations and highlights the operational importance of maintaining acceptable CO₂ levels for occupant wellbeing and performance (ASHRAE, 2019; Allen et al., 2016; Satish et al., 2012). Privacy risk is minimised through deliberate avoidance of personal data collection, consistent with privacy-by-design principles and GDPR-aligned minimisation (Cavoukian, 2011; European Parliament, 2016).

Limitations include the monitoring-only scope, which requires either manual facilities intervention or later integration into building automation protocols. BLE range and gateway density may affect economics in low-density layouts. Future work should add analytics and anomaly detection to identify ventilation problems, integrate building automation standards (e.g., BACnet) for closed-loop control, and extend validation across diverse building types and seasons to strengthen generalisability (ASHRAE, 2023). Secure update and key management practices remain critical for long-lived IoT deployments and should be continuously improved as threat models evolve (ARM, 2022).

References (excluded from word count)

Allen, J.G., MacNaughton, P., Satish, U., Santanam, S., Vallarino, J. and Spengler, J.D. (2016) 'Associations of cognitive function scores with carbon dioxide, ventilation, and volatile organic compound exposures in office workers: a controlled exposure study of green and conventional office environments', Environmental Health Perspectives, 124(6), pp. 805-812. doi: 10.1289/ehp.1510037.

Amazon Web Services (2025) AWS sustainability report 2025. Seattle: Amazon Web Services, Inc.

ARM Limited (2022) Cortex-M security best practices: secure boot and firmware update. Cambridge: ARM Limited.

ASHRAE (2019) ANSI/ASHRAE Standard 62.1-2019: ventilation for acceptable indoor air quality. Atlanta: American Society of Heating, Refrigerating and Air-Conditioning Engineers.

ASHRAE (2023) ASHRAE handbook: HVAC applications, chapter 49: building energy monitoring. Atlanta: American Society of Heating, Refrigerating and Air-Conditioning Engineers.

Bangor, A., Kortum, P. and Miller, J. (2009) 'Determining what individual SUS scores mean: adding an adjective rating scale', Journal of Usability Studies, 4(3), pp. 114-123.

Banks, A. and Gupta, R. (2019) MQTT version 5.0. OASIS Standard. Burlington: OASIS Open. Available at: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html
 (Accessed: 28 January 2026).

Bluetooth Special Interest Group (2019) Bluetooth core specification version 5.2. Kirkland: Bluetooth SIG.

Cavoukian, A. (2011) Privacy by design: the 7 foundational principles. Toronto: Information and Privacy Commissioner of Ontario.

Energizer Holdings, Inc. (2023) Energizer L91 lithium AA battery: product datasheet. St. Louis: Energizer.

European Parliament (2012) Directive 2012/19/EU on waste electrical and electronic equipment (WEEE). Official Journal of the European Union, L197, pp. 38-71.

European Parliament (2016) Regulation (EU) 2016/679 on the protection of natural persons with regard to the processing of personal data (General Data Protection Regulation). Official Journal of the European Union, L119, pp. 1-88.

Internet Engineering Task Force (IETF) (2018) The Transport Layer Security (TLS) Protocol Version 1.3, RFC 8446. Available at: https://tools.ietf.org/html/rfc8446
 (Accessed: 10 January 2026).

OWASP Foundation (2018) OWASP Internet of Things top 10 2018. Columbia: Open Web Application Security Project Foundation.

Satish, U., Mendell, M.J., Shekhar, K., Hotchi, T., Sullivan, D., Streufert, S. and Fisk, W.J. (2012) 'Is CO₂ an indoor pollutant? Direct effects of low-to-moderate CO₂ concentrations on human decision-making performance', Environmental Health Perspectives, 120(12), pp. 1671-1677. doi: 10.1289/ehp.1104789.

Sensirion AG (2024) SCD40 CO₂ sensor: datasheet version 1.2. Staefa: Sensirion.

STMicroelectronics (2023) STM32WB55xx reference manual: RM0434 revision 9. Geneva: STMicroelectronics.

UK Government Department for Energy Security and Net Zero (2025) 2025 government greenhouse gas conversion factors for company reporting: electricity. London: HMSO.


