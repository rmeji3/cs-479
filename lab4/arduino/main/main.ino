#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "config.h"

Adafruit_MPU6050 mpu;

// Filtering variables
float alpha = 0.2; // Smoothing factor (0.0 to 1.0) - Adjust for more/less smoothing
float fMF = 0, fLF = 0, fMM = 0, fHEEL = 0;
float fAX = 0, fAY = 0, fAZ = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);

  // Initialize LEDs
  pinMode(PIN_LED_MF, OUTPUT);
  pinMode(PIN_LED_LF, OUTPUT);
  pinMode(PIN_LED_MM, OUTPUT);
  pinMode(PIN_LED_HEEL, OUTPUT);

  // Initialize Accel Interrupt Pin
  pinMode(PIN_ACCEL_INT, INPUT);

  // Initialize MPU-6050
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
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

  // Apply Exponential Moving Average (EMA) filtering
  fMF = (alpha * valMF) + ((1 - alpha) * fMF);
  fLF = (alpha * valLF) + ((1 - alpha) * fLF);
  fMM = (alpha * valMM) + ((1 - alpha) * fMM);
  fHEEL = (alpha * valHEEL) + ((1 - alpha) * fHEEL);

  // Map filtered FSR values to LED brightness (PWM 0-255)
  // Fix: Convert fMF to int BEFORE map to prevent overflow/looping
  // Increased threshold to 350 to reduce over-sensitivity
  int mMF = (int)fMF;
  int mLF = (int)fLF;
  int mMM = (int)fMM;
  int mHEEL = (int)fHEEL;
  
  analogWrite(PIN_LED_MF, (mMF > 350) ? map(constrain(mMF, 350, 850), 350, 850, 0, 255) : 0);
  analogWrite(PIN_LED_LF, (mLF > 350) ? map(constrain(mLF, 350, 850), 350, 850, 0, 255) : 0);
  analogWrite(PIN_LED_MM, (mMM > 350) ? map(constrain(mMM, 350, 850), 350, 850, 0, 255) : 0);
  analogWrite(PIN_LED_HEEL, (mHEEL > 350) ? map(constrain(mHEEL, 350, 850), 350, 850, 0, 255) : 0);

  // Get MPU-6050 data
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Filter Accelerometer data
  fAX = (alpha * a.acceleration.x) + ((1 - alpha) * fAX);
  fAY = (alpha * a.acceleration.y) + ((1 - alpha) * fAY);
  fAZ = (alpha * a.acceleration.z) + ((1 - alpha) * fAZ);

  // Send data to Serial for Processing (using filtered values)
  // Format: MF,LF,MM,HEEL,accelX,accelY,accelZ,gyroX,gyroY,gyroZ
  // Set UI deadzone to 300 to match LED sensitivity
  Serial.print((fMF > 300) ? (int)fMF : 0); Serial.print(",");
  Serial.print((fLF > 300) ? (int)fLF : 0); Serial.print(",");
  Serial.print((fMM > 300) ? (int)fMM : 0); Serial.print(",");
  Serial.print((fHEEL > 300) ? (int)fHEEL : 0); Serial.print(",");
  Serial.print(fAX, 3); Serial.print(",");
  Serial.print(fAY, 3); Serial.print(",");
  Serial.print(fAZ, 3); Serial.print(",");
  Serial.print(g.gyro.x, 3); Serial.print(",");
  Serial.print(g.gyro.y, 3); Serial.print(",");
  Serial.println(g.gyro.z, 3);

  delay(20); // ~50Hz sampling
}