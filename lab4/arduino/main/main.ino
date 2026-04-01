#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "config.h"

Adafruit_MPU6050 mpu;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);

  // Initialize LEDs
  pinMode(PIN_LED_MF, OUTPUT);
  pinMode(PIN_LED_LF, OUTPUT);
  pinMode(PIN_LED_MM, OUTPUT);
  pinMode(PIN_LED_HEEL, OUTPUT);

  // Initialize MPU-6050
  if (!mpu.begin()) {
    // Serial.println("Failed to find MPU6050 chip");
    while (1) { delay(10); }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  delay(100);
}

void loop() {
  // Read FSR values
  int valMF = analogRead(PIN_FSR_MF);
  int valLF = analogRead(PIN_FSR_LF);
  int valMM = analogRead(PIN_FSR_MM);
  int valHEEL = analogRead(PIN_FSR_HEEL);

  // Map FSR values to LED brightness (PWM 0-255)
  // Assuming calibration may be needed, using 0-1023 range
  analogWrite(PIN_LED_MF, map(valMF, 0, 1023, 0, 255));
  analogWrite(PIN_LED_LF, map(valLF, 0, 1023, 0, 255));
  analogWrite(PIN_LED_MM, map(valMM, 0, 1023, 0, 255));
  analogWrite(PIN_LED_HEEL, map(valHEEL, 0, 1023, 0, 255));

  // Get MPU-6050 data
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Send data to Serial for Processing
  // Format: MF,LF,MM,HEEL,accelX,accelY,accelZ,gyroX,gyroY,gyroZ
  Serial.print(valMF); Serial.print(",");
  Serial.print(valLF); Serial.print(",");
  Serial.print(valMM); Serial.print(",");
  Serial.print(valHEEL); Serial.print(",");
  Serial.print(a.acceleration.x); Serial.print(",");
  Serial.print(a.acceleration.y); Serial.print(",");
  Serial.print(a.acceleration.x); Serial.print(",");
  Serial.print(g.gyro.x); Serial.print(",");
  Serial.print(g.gyro.y); Serial.print(",");
  Serial.println(g.gyro.z);

  delay(20); // ~50Hz sampling
}
