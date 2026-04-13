#ifndef CONFIG_H
#define CONFIG_H

// FSR Pins (Analog)
// Ordering aligned with user's requested array: MF, LF, HEEL, MM
#define PIN_FSR_MF   A0
#define PIN_FSR_LF   A1
#define PIN_FSR_HEEL A2
#define PIN_FSR_MM   A3

// LED Pins (PWM for intensity - User specified configuration)
#define PIN_LED_MF 3
#define PIN_LED_LF 6
#define PIN_LED_MM 10
#define PIN_LED_HEEL 11

// MPU-6050 usually uses I2C (SDA/SCL)
// On FireBeetle 328P, SDA is A4 and SCL is A5
#define PIN_ACCEL_INT 2 // Accelerometer Interrupt Pin

#endif
