#ifndef CONFIG_H
#define CONFIG_H

// FSR Pins (Analog)
#define PIN_FSR_MF A0   // Medial Forefoot
#define PIN_FSR_LF A1   // Lateral Forefoot
#define PIN_FSR_MM A2   // Medial Mid-foot
#define PIN_FSR_HEEL A3 // Heel

// LED Pins (PWM for intensity - User specified configuration)
#define PIN_LED_MF 3
#define PIN_LED_LF 5
#define PIN_LED_MM 6
#define PIN_LED_HEEL 9

// MPU-6050 usually uses I2C (SDA/SCL)
// On FireBeetle 328P, SDA is A4 and SCL is A5
#define PIN_ACCEL_INT 2 // Accelerometer Interrupt Pin

#endif
