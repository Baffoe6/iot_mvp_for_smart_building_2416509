/**
 * @file scd40_driver.h
 * @brief Sensirion SCD40 CO2 Sensor Driver for STM32
 * @details NDIR CO2 sensor with integrated temperature and humidity
 *          - I2C interface (address 0x62)
 *          - Measurement time: 5 seconds
 *          - Current: 18 mA during measurement, <0.5 µA sleep
 *          - Accuracy: ±40 ppm ±3% of reading
 * 
 * @author IoT MVP Team
 * @version 1.0.0
 */

#ifndef SCD40_DRIVER_H
#define SCD40_DRIVER_H

#include "stm32wbxx_hal.h"

/* I2C Address */
#define SCD40_I2C_ADDRESS               0x62

/* Commands */
#define SCD40_CMD_START_PERIODIC_MEASUREMENT    0x21b1
#define SCD40_CMD_READ_MEASUREMENT              0xec05
#define SCD40_CMD_STOP_PERIODIC_MEASUREMENT     0x3f86
#define SCD40_CMD_GET_SERIAL_NUMBER             0x3682
#define SCD40_CMD_PERFORM_SELF_TEST             0x3639
#define SCD40_CMD_PERFORM_FACTORY_RESET         0x3632
#define SCD40_CMD_REINIT                        0x3646
#define SCD40_CMD_SET_TEMPERATURE_OFFSET        0x241d
#define SCD40_CMD_GET_TEMPERATURE_OFFSET        0x2318
#define SCD40_CMD_SET_SENSOR_ALTITUDE           0x2427
#define SCD40_CMD_GET_SENSOR_ALTITUDE           0x2322
#define SCD40_CMD_SET_AMBIENT_PRESSURE          0xe000
#define SCD40_CMD_PERFORM_FORCED_RECALIBRATION  0x362f
#define SCD40_CMD_SET_AUTOMATIC_SELF_CALIBRATION 0x2416
#define SCD40_CMD_GET_AUTOMATIC_SELF_CALIBRATION 0x2313

/* Timing */
#define SCD40_MEASUREMENT_INTERVAL_MS   5000    // 5 seconds
#define SCD40_SERIAL_NUMBER_TIMEOUT_MS  1
#define SCD40_SELF_TEST_TIMEOUT_MS      10000   // 10 seconds
#define SCD40_FACTORY_RESET_TIMEOUT_MS  1200

/* Data Ready */
#define SCD40_DATA_READY_INTERVAL_MS    5000

/**
 * @brief SCD40 sensor data structure
 */
typedef struct {
    uint16_t co2_ppm;           // CO2 concentration in ppm
    float temperature_c;         // Temperature in degrees Celsius
    float humidity_rh;           // Relative humidity in %
    uint8_t data_ready;          // 1 if data is ready, 0 otherwise
} SCD40_Data_t;

/**
 * @brief Initialize SCD40 sensor
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_Init(void);

/**
 * @brief Start periodic measurement mode
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_StartPeriodicMeasurement(void);

/**
 * @brief Stop periodic measurement mode
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_StopPeriodicMeasurement(void);

/**
 * @brief Read measurement data (CO2, temperature, humidity)
 * @param co2_ppm Pointer to CO2 concentration variable
 * @param temperature_c Pointer to temperature variable
 * @param humidity_rh Pointer to humidity variable
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_ReadMeasurement(uint16_t *co2_ppm, float *temperature_c, float *humidity_rh);

/**
 * @brief Check if data is ready for reading
 * @return 1 if data ready, 0 otherwise
 */
uint8_t SCD40_IsDataReady(void);

/**
 * @brief Get sensor serial number
 * @param serial_number Pointer to 6-byte serial number array
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_GetSerialNumber(uint8_t *serial_number);

/**
 * @brief Perform self-test
 * @return HAL_OK if test passed, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_PerformSelfTest(void);

/**
 * @brief Set temperature offset for compensation
 * @param offset_c Temperature offset in degrees Celsius
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_SetTemperatureOffset(float offset_c);

/**
 * @brief Enable/disable automatic self-calibration (ASC)
 * @param enable 1 to enable, 0 to disable
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_SetAutomaticSelfCalibration(uint8_t enable);

/**
 * @brief Set sensor altitude for pressure compensation
 * @param altitude_m Altitude in meters above sea level
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_SetSensorAltitude(uint16_t altitude_m);

/**
 * @brief Perform forced recalibration (FRC)
 * @param target_co2_ppm Known CO2 reference concentration
 * @param correction_ppm Pointer to store correction value
 * @return HAL_OK if successful, HAL_ERROR otherwise
 */
HAL_StatusTypeDef SCD40_PerformForcedRecalibration(uint16_t target_co2_ppm, int16_t *correction_ppm);

#endif /* SCD40_DRIVER_H */
