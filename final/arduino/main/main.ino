#include <Wire.h>
#include <VL53L1X.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "SparkFun_Bio_Sensor_Hub_Library.h"
#include <math.h>

//  Pin definitions 
#define MIC_PIN       39   // A1 - MAX9814 OUT
#define MPU_INT_PIN   13   // D7
#define RESET_PIN     14   // D8
#define MFIO_PIN       2   // D9
#define LED_PIN        4   // D4
//  Thresholds 
// warn if an object is within 1.5 m on the left side
#define BLIND_SPOT_MM       1500
// Impact/fall: total accel magnitude above this m/s^2 triggers alert
// a hard hit or drop spikes well above 20 given grav is 9.8
#define FALL_ACCEL_THRESH   20.0f

//  Mic sampling 
// Fewer samples keeps the loop fast while still capturing peak amplitude
#define MIC_SAMPLES   64

//  Sensor objects 
VL53L1X tof;
Adafruit_MPU6050 mpu;
SparkFun_Bio_Sensor_Hub bioHub(RESET_PIN, MFIO_PIN);

unsigned long lastPrint = 0;
#define PRINT_INTERVAL 200  // 200 ms

void setup() {
  Serial.begin(115200);
  delay(1000);

  Wire.begin();

  //  VL53L1X 
  tof.setTimeout(500);
  if (!tof.init()) {
    Serial.println("ERROR: VL53L1X init failed — check wiring");
    while (1);
  }
  tof.setDistanceMode(VL53L1X::Long);
  tof.startContinuous(100);
  Serial.println("VL53L1X OK");

  //  MPU-6050 
  if (!mpu.begin()) {
    Serial.println("ERROR: MPU-6050 init failed — check wiring");
    while (1);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  pinMode(MPU_INT_PIN, INPUT);
  Serial.println("MPU-6050 OK");

  //  MAX32664 (Pulse Ox) 
  int result = bioHub.begin(Wire, 0x55);
  if (result != 0) {
    Serial.print("ERROR: MAX32664 init failed, code ");
    Serial.println(result);
    while (1);
  }
  bioHub.configBpm(MODE_ONE);
  delay(4000);

  //  MAX9814 
  pinMode(MIC_PIN, INPUT);

  // LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.println("Setup complete — streaming JSON");
}

void loop() {
  if (millis() - lastPrint < PRINT_INTERVAL) return;
  lastPrint = millis();

  //  VL53L1X —  blind spot sensor
  uint16_t dist = tof.read(false);
  bool tofTimeout = tof.timeoutOccurred();
  // Object detected if sensor returned a valid reading within threshold
  bool blindSpot = !tofTimeout && (dist > 0) && (dist <= BLIND_SPOT_MM);

  //  MPU-6050 — fall / impact detection 
  sensors_event_t accel, gyro, temp;
  mpu.getEvent(&accel, &gyro, &temp);
  float ax = accel.acceleration.x;
  float ay = accel.acceleration.y;
  float az = accel.acceleration.z;
  float gx = gyro.gyro.x;
  float gy = gyro.gyro.y;
  float gz = gyro.gyro.z;
  float accelMag = sqrtf(ax*ax + ay*ay + az*az);
  bool fall = (accelMag >= FALL_ACCEL_THRESH);

  //  MAX32664 — health metrics 
  bioData body = bioHub.readBpm();

  //  MAX9814 — sound levels on blind side
  int micMin = 4095, micMax = 0;
  for (int i = 0; i < MIC_SAMPLES; i++) {
    int val = analogRead(MIC_PIN);
    if (val > micMax) micMax = val;
    if (val < micMin) micMin = val;
    delayMicroseconds(100);
  }
  int micPeak = micMax - micMin;

  // Frontend parses each line as a complete JSON object
  Serial.print("{");

  // Blind spot (VL53L1X + mic together)
  Serial.print("\"dist\":"); Serial.print(tofTimeout ? -1 : (int)dist); Serial.print(",");
  Serial.print("\"blind_spot\":"); Serial.print(blindSpot ? "true" : "false"); Serial.print(",");

  // light led if blindspot is true
  digitalWrite(LED_PIN, blindSpot ? HIGH : LOW);

  // Accelerometer / gyro raw + derived
  Serial.print("\"ax\":"); Serial.print(ax, 2); Serial.print(",");
  Serial.print("\"ay\":"); Serial.print(ay, 2); Serial.print(",");
  Serial.print("\"az\":"); Serial.print(az, 2); Serial.print(",");
  Serial.print("\"gx\":"); Serial.print(gx, 2); Serial.print(",");
  Serial.print("\"gy\":"); Serial.print(gy, 2); Serial.print(",");
  Serial.print("\"gz\":"); Serial.print(gz, 2); Serial.print(",");
  Serial.print("\"accel_mag\":"); Serial.print(accelMag, 2); Serial.print(",");
  Serial.print("\"fall\":"); Serial.print(fall ? "true" : "false"); Serial.print(",");

  // Health metrics (pulse ox)
  Serial.print("\"spo2\":"); Serial.print((int)body.oxygen); Serial.print(",");
  Serial.print("\"bpm\":"); Serial.print((int)body.heartRate); Serial.print(",");

  // Mic peak amplitude (0–4095)
  Serial.print("\"mic\":"); Serial.print(micPeak); Serial.print(",");

  // Timestamp since start
  Serial.print("\"ts\":"); Serial.print(millis());

  Serial.println("}");
}