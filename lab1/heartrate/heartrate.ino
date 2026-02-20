#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

#define BUZZER 12

// Reset pin, MFIO pin
const int resPin = 4;
const int mfioPin = 5;

// Sensor object
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin);
bioData body;

// timing for serial output
unsigned long lastPrint = 0;
const unsigned long printInterval = 250; // 4 times per second

void setup() {
  Serial.begin(115200);

  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);
  pinMode(LED_BUILTIN, OUTPUT);

  Wire.begin();
  delay(1000);

  int result = bioHub.begin();
  bioHub.configBpm(MODE_ONE);
}

void loop() {
  body = bioHub.readBpm();

  unsigned long now = millis();
    if (Serial.available()) {
      char c = Serial.read();
      if (c == 'B') {
        digitalWrite(LED_BUILTIN, HIGH);
        buzzTwice();
        digitalWrite(LED_BUILTIN, LOW);
      }
    }

  // Send data
  if (now - lastPrint >= printInterval && body.confidence > 75) {
    lastPrint = now;

    Serial.print("H:");
    Serial.print(body.heartRate);
    Serial.print(",C:");
    Serial.print(body.confidence);
    Serial.print(",O:");
    Serial.print(body.oxygen);
    Serial.println();
  }

 
}

void buzzTwice() {
  // passive buzzers are usually louder around 2000–4000 Hz
  int freq = 2500;

  tone(BUZZER, freq);
  delay(250);
  noTone(BUZZER);

  delay(150);

  tone(BUZZER, freq);
  delay(250);
  noTone(BUZZER);
}
