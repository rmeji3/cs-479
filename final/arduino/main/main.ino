#include <Wire.h>
#include <VL53L1X.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "SparkFun_Bio_Sensor_Hub_Library.h"

// ── Pin definitions ───────────────────────────────────
#define MIC_PIN       36   // A0 - MAX9814 OUT
#define MPU_INT_PIN   13   // D7
#define RESET_PIN     14   // D8
#define MFIO_PIN       2   // D9

// ── Sensor objects ────────────────────────────────────
VL53L1X tof;
Adafruit_MPU6050 mpu;
SparkFun_Bio_Sensor_Hub bioHub(RESET_PIN, MFIO_PIN);

// ── Mic sampling ─────────────────────────────────────
#define MIC_SAMPLES   64

unsigned long lastPrint = 0;
#define PRINT_INTERVAL 500

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== 4-Sensor Test ===\n");

  Wire.begin(); // SDA=IO21, SCL=IO22

  // ── VL53L1X ────────────────────────────────────────
  Serial.print("[VL53L1X] Init... ");
  tof.setTimeout(500);
  if (!tof.init()) {
    Serial.println("FAILED - check SDA/SCL");
    while (1);
  }
  tof.setDistanceMode(VL53L1X::Long);
  tof.startContinuous(100);
  Serial.println("OK");

  // ── MPU-6050 ───────────────────────────────────────
  Serial.print("[MPU-6050] Init... ");
  if (!mpu.begin()) {
    Serial.println("FAILED - check SDA/SCL");
    while (1);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  pinMode(MPU_INT_PIN, INPUT);
  Serial.println("OK");

  // ── MAX32664 (Pulse Ox) ────────────────────────────
  Serial.print("[MAX32664] Init... ");
  int result = bioHub.begin(Wire, 0x55);
  if (result != 0) {
    Serial.print("FAILED (error ");
    Serial.print(result);
    Serial.println(") - check RESET/MFIO pins");
    while (1);
  }
  bioHub.configBpm(MODE_ONE);
  delay(4000);
  Serial.println("OK");

  // ── MAX9814 ────────────────────────────────────────
  Serial.print("[MAX9814] Init... ");
  pinMode(MIC_PIN, INPUT);
  Serial.println("OK");

  Serial.println("\n--- All sensors ready ---");
  Serial.println("Dist(mm) | Ax    Ay    Az   | Gx    Gy    Gz   | SpO2 | BPM | Mic");
  Serial.println("---------|------------------|------------------|------|-----|----");
}

void loop() {
  if (millis() - lastPrint < PRINT_INTERVAL) return;
  lastPrint = millis();

  // ── VL53L1X ────────────────────────────────────────
  uint16_t dist = tof.read(false);
  if (tof.timeoutOccurred()) {
    Serial.print("TIMEOUT  | ");
  } else {
    Serial.print(dist);
    Serial.print("mm\t| ");
  }

  // ── MPU-6050 ───────────────────────────────────────
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);
  Serial.print(accel.acceleration.x, 1); Serial.print("\t");
  Serial.print(accel.acceleration.y, 1); Serial.print("\t");
  Serial.print(accel.acceleration.z, 1); Serial.print("\t| ");
  Serial.print(gyro.gyro.x, 1); Serial.print("\t");
  Serial.print(gyro.gyro.y, 1); Serial.print("\t");
  Serial.print(gyro.gyro.z, 1); Serial.print("\t| ");

  // ── MAX32664 ───────────────────────────────────────
  bioData body = bioHub.readBpm();
  Serial.print(body.oxygen);  Serial.print("\t| ");
  Serial.print(body.heartRate); Serial.print("\t| ");

  // ── MAX9814 mic ────────────────────────────────────
  int peak = 0;
  int baseline = 2048;
  for (int i = 0; i < MIC_SAMPLES; i++) {
    int val = abs(analogRead(MIC_PIN) - baseline);
    if (val > peak) peak = val;
    delayMicroseconds(100);
  }
  Serial.println(peak);
}