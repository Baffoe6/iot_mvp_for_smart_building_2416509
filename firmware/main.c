/**
 * @file main.c
 * @brief IoT MVP - Main firmware application for STM32WB55
 * @details Smart Building Air Quality and Occupancy Monitoring System
 *          - CO2/Temp/Humidity sensing using Sensirion SCD40
 *          - PIR occupancy detection
 *          - BLE 5.2 connection-less advertisements
 *          - Secure OTA updates with RSA-2048 signature verification
 *          - Target: <50 µA average current, 2.4-year battery life
 * 
 * @author IoT MVP Team
 * @date January 2026
 * @version 1.0.0
 */

#include "stm32wbxx_hal.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"
#include "scd40_driver.h"
#include "pir_sensor.h"
#include "ble_service.h"
#include "power_manager.h"
#include "watchdog.h"
#include "ota_manager.h"

/* Configuration Constants */
#define SAMPLING_INTERVAL_OCCUPIED_MS   (10 * 60 * 1000)  // 10 minutes
#define SAMPLING_INTERVAL_VACANT_MS     (20 * 60 * 1000)  // 20 minutes
#define CO2_ALERT_THRESHOLD_PPM         1200
#define TEMP_ALERT_THRESHOLD_C          27.0f
#define BATTERY_LOW_THRESHOLD_MV        2400
#define WATCHDOG_TIMEOUT_MS             30000

/* Task Priorities */
#define SENSING_TASK_PRIORITY           (tskIDLE_PRIORITY + 3)
#define COMMS_TASK_PRIORITY             (tskIDLE_PRIORITY + 2)
#define WATCHDOG_TASK_PRIORITY          (tskIDLE_PRIORITY + 4)

/* Stack Sizes (bytes) */
#define SENSING_TASK_STACK_SIZE         512
#define COMMS_TASK_STACK_SIZE           1024
#define WATCHDOG_TASK_STACK_SIZE        256

/* Global Handles */
static TaskHandle_t sensingTaskHandle = NULL;
static TaskHandle_t commsTaskHandle = NULL;
static TaskHandle_t watchdogTaskHandle = NULL;
static QueueHandle_t sensorDataQueue = NULL;
static SemaphoreHandle_t i2cMutex = NULL;

/* Sensor Data Structure */
typedef struct {
    uint16_t co2_ppm;
    float temperature_c;
    float humidity_rh;
    uint8_t occupancy_detected;
    uint32_t timestamp_unix;
    uint16_t battery_mv;
} SensorData_t;

/* System State */
typedef struct {
    uint8_t is_occupied;
    uint32_t last_motion_timestamp;
    uint32_t sampling_interval_ms;
    uint8_t low_battery_alert_sent;
    uint16_t boot_count;
} SystemState_t;

static SystemState_t systemState = {0};

/**
 * @brief Sensing Task - Samples all sensors and queues data
 * @param argument Unused
 */
static void SensingTask(void *argument)
{
    SensorData_t sensorData = {0};
    TickType_t lastWakeTime = xTaskGetTickCount();
    HAL_StatusTypeDef status;
    
    DebugLog("Sensing Task started");
    
    // Initialize sensors
    if (SCD40_Init() != HAL_OK) {
        ErrorHandler("SCD40 initialization failed");
    }
    
    if (PIR_Init() != HAL_OK) {
        ErrorHandler("PIR initialization failed");
    }
    
    // Start SCD40 periodic measurement mode
    SCD40_StartPeriodicMeasurement();
    
    for (;;)
    {
        // Kick watchdog
        WatchdogKick();
        
        // Check PIR for occupancy
        sensorData.occupancy_detected = PIR_ReadMotion();
        
        // Update system state based on occupancy
        if (sensorData.occupancy_detected) {
            systemState.is_occupied = 1;
            systemState.last_motion_timestamp = HAL_GetTick();
            systemState.sampling_interval_ms = SAMPLING_INTERVAL_OCCUPIED_MS;
        } else {
            // Check if vacant for >30 minutes
            uint32_t time_since_motion = HAL_GetTick() - systemState.last_motion_timestamp;
            if (time_since_motion > (30 * 60 * 1000)) {
                systemState.is_occupied = 0;
                systemState.sampling_interval_ms = SAMPLING_INTERVAL_VACANT_MS;
            }
        }
        
        // Acquire I2C mutex for sensor access
        if (xSemaphoreTake(i2cMutex, pdMS_TO_TICKS(5000)) == pdTRUE)
        {
            // Read CO2, temperature, humidity from SCD40
            status = SCD40_ReadMeasurement(&sensorData.co2_ppm, 
                                          &sensorData.temperature_c, 
                                          &sensorData.humidity_rh);
            
            if (status != HAL_OK) {
                DebugLog("SCD40 read error, skipping cycle");
                xSemaphoreGive(i2cMutex);
                vTaskDelayUntil(&lastWakeTime, pdMS_TO_TICKS(systemState.sampling_interval_ms));
                continue;
            }
            
            xSemaphoreGive(i2cMutex);
        }
        else
        {
            DebugLog("I2C mutex timeout");
            vTaskDelayUntil(&lastWakeTime, pdMS_TO_TICKS(systemState.sampling_interval_ms));
            continue;
        }
        
        // Read battery voltage
        sensorData.battery_mv = ADC_ReadBatteryVoltage();
        
        // Get RTC timestamp
        sensorData.timestamp_unix = RTC_GetUnixTimestamp();
        
        // Check for alert conditions
        if (sensorData.co2_ppm > CO2_ALERT_THRESHOLD_PPM ||
            sensorData.temperature_c > TEMP_ALERT_THRESHOLD_C)
        {
            // Set high-priority alert flag in BLE advertisement
            BLE_SetAlertFlag(1);
        }
        
        // Check low battery
        if (sensorData.battery_mv < BATTERY_LOW_THRESHOLD_MV && 
            !systemState.low_battery_alert_sent)
        {
            BLE_SetLowBatteryFlag(1);
            systemState.low_battery_alert_sent = 1;
        }
        
        // Queue sensor data for transmission
        if (xQueueSend(sensorDataQueue, &sensorData, 0) != pdTRUE)
        {
            DebugLog("Sensor queue full, data dropped");
        }
        
        // Log to flash for local storage
        Flash_AppendSensorData(&sensorData);
        
        // Enter low-power sleep until next sampling interval
        DebugLog("Entering sleep, next wake in %lu ms", systemState.sampling_interval_ms);
        vTaskDelayUntil(&lastWakeTime, pdMS_TO_TICKS(systemState.sampling_interval_ms));
    }
}

/**
 * @brief Communications Task - BLE advertising and gateway comms
 * @param argument Unused
 */
static void CommsTask(void *argument)
{
    SensorData_t sensorData;
    uint8_t ble_payload[100];
    uint16_t payload_len;
    
    DebugLog("Comms Task started");
    
    // Initialize BLE stack
    if (BLE_Init() != HAL_OK) {
        ErrorHandler("BLE initialization failed");
    }
    
    // Set device name and configure advertising
    BLE_SetDeviceName("IAQ-Sensor-%08X", HAL_GetUIDw0());
    BLE_ConfigureAdvertising(BLE_ADV_INTERVAL_MS(1000)); // 1s interval
    
    for (;;)
    {
        // Kick watchdog
        WatchdogKick();
        
        // Wait for sensor data from queue (10-20 min timeout)
        if (xQueueReceive(sensorDataQueue, &sensorData, pdMS_TO_TICKS(25 * 60 * 1000)) == pdTRUE)
        {
            // Construct BLE advertisement payload
            payload_len = BLE_BuildPayload(ble_payload, sizeof(ble_payload), &sensorData);
            
            // Transmit BLE advertisement (10 µJ energy per message)
            if (BLE_Advertise(ble_payload, payload_len) != HAL_OK) {
                DebugLog("BLE advertising failed");
            } else {
                DebugLog("BLE adv sent: CO2=%u ppm, Temp=%.1f C, Occ=%u", 
                        sensorData.co2_ppm, sensorData.temperature_c, sensorData.occupancy_detected);
            }
            
            // Check for pending OTA updates
            if (OTA_CheckForUpdate() == OTA_UPDATE_AVAILABLE) {
                DebugLog("OTA update available, initiating download");
                OTA_StartUpdate();
            }
        }
        
        // Periodic keep-alive (every 5 minutes even if no data)
        BLE_SendKeepAlive();
        
        vTaskDelay(pdMS_TO_TICKS(5000)); // 5s between checks
    }
}

/**
 * @brief Watchdog Task - Monitor system health and reset if hung
 * @param argument Unused
 */
static void WatchdogTask(void *argument)
{
    DebugLog("Watchdog Task started");
    
    // Initialize hardware watchdog
    Watchdog_Init(WATCHDOG_TIMEOUT_MS);
    
    for (;;)
    {
        // Check if other tasks are responsive
        uint32_t sensing_heartbeat = GetTaskHeartbeat(sensingTaskHandle);
        uint32_t comms_heartbeat = GetTaskHeartbeat(commsTaskHandle);
        
        uint32_t current_time = HAL_GetTick();
        
        if ((current_time - sensing_heartbeat) > WATCHDOG_TIMEOUT_MS ||
            (current_time - comms_heartbeat) > WATCHDOG_TIMEOUT_MS)
        {
            DebugLog("Task hang detected, forcing system reset");
            NVIC_SystemReset();
        }
        
        // Refresh hardware watchdog
        Watchdog_Refresh();
        
        vTaskDelay(pdMS_TO_TICKS(5000)); // Check every 5 seconds
    }
}

/**
 * @brief System Clock Configuration
 * @retval None
 */
static void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
    
    // Configure MSI oscillator (4 MHz for ultra-low power)
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI | RCC_OSCILLATORTYPE_LSE;
    RCC_OscInitStruct.LSEState = RCC_LSE_ON; // 32.768 kHz for RTC
    RCC_OscInitStruct.MSIState = RCC_MSI_ON;
    RCC_OscInitStruct.MSICalibrationValue = RCC_MSICALIBRATION_DEFAULT;
    RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_6; // 4 MHz
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
    
    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
        ErrorHandler("Clock oscillator config failed");
    }
    
    // Configure system clock
    RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                                  RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_MSI;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
    
    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK) {
        ErrorHandler("Clock config failed");
    }
}

/**
 * @brief Application entry point
 * @retval int
 */
int main(void)
{
    // Reset of all peripherals, Initializes the Flash interface and the Systick
    HAL_Init();
    
    // Configure the system clock
    SystemClock_Config();
    
    // Initialize power management (ultra-low power config)
    PowerManager_Init();
    PowerManager_ConfigureUltraLowPower();
    
    // Check if OTA update was applied (validate and rollback if failed)
    OTA_CheckBootStatus();
    
    // Increment boot counter in backup SRAM
    systemState.boot_count++;
    BackupSRAM_WriteBootCount(systemState.boot_count);
    
    // Initialize peripherals
    GPIO_Init();
    I2C_Init();
    ADC_Init();
    RTC_Init();
    Flash_Init();
    
    // Create synchronization primitives
    sensorDataQueue = xQueueCreate(10, sizeof(SensorData_t));
    i2cMutex = xSemaphoreCreateMutex();
    
    if (sensorDataQueue == NULL || i2cMutex == NULL) {
        ErrorHandler("RTOS primitives creation failed");
    }
    
    // Create FreeRTOS tasks
    xTaskCreate(SensingTask, "Sensing", SENSING_TASK_STACK_SIZE, NULL, 
                SENSING_TASK_PRIORITY, &sensingTaskHandle);
    
    xTaskCreate(CommsTask, "Comms", COMMS_TASK_STACK_SIZE, NULL, 
                COMMS_TASK_PRIORITY, &commsTaskHandle);
    
    xTaskCreate(WatchdogTask, "Watchdog", WATCHDOG_TASK_STACK_SIZE, NULL, 
                WATCHDOG_TASK_PRIORITY, &watchdogTaskHandle);
    
    DebugLog("IoT MVP Firmware v1.0.0 starting...");
    DebugLog("Device ID: %08X-%08X-%08X", HAL_GetUIDw0(), HAL_GetUIDw1(), HAL_GetUIDw2());
    DebugLog("Boot count: %u", systemState.boot_count);
    
    // Start the FreeRTOS scheduler
    vTaskStartScheduler();
    
    // Should never reach here
    while (1) {
        ErrorHandler("Scheduler returned unexpectedly");
    }
}

/**
 * @brief Error Handler
 * @param msg Error message
 */
void ErrorHandler(const char *msg)
{
    DebugLog("FATAL ERROR: %s", msg);
    
    // Log error to flash
    Flash_LogError(msg);
    
    // Disable interrupts and halt
    __disable_irq();
    
    // Blink LED rapidly to indicate error
    while (1) {
        HAL_GPIO_TogglePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin);
        HAL_Delay(100);
    }
}

/**
 * @brief Period elapsed callback in non blocking mode
 * @param htim TIM handle
 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM1) {
        HAL_IncTick();
    }
}
