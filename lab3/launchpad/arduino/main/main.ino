// ============================================
// Launchpad Controller - Main Sketch
// CS479 Lab 3
// ============================================
// Reads 10 capacitive touch pads (MPR121) and
// a flex sensor, then streams data to Processing
// over serial.
//
// Serial Protocol (sent every SEND_INTERVAL_MS):
//   BBBBBBBBBB,FFF\n
//   B = 0/1 for each pad (index 0-9)
//   FFF = flex value 0-100
// ============================================

#include <Wire.h>
#include "Adafruit_MPR121.h"
#include "config.h"
#include "sensors.h"

// Hardware
Adafruit_MPR121 cap = Adafruit_MPR121();

// Sensor wrappers
PadSensor pads;
FlexSensor flex;

// Timing
unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(SERIAL_BAUD);
  while (!Serial) delay(10);

  Serial.println("LAUNCHPAD_INIT");

  // Initialize MPR121 capacitive sensor
  if (!cap.begin()) {
    Serial.println("MPR121_ERROR");
    while (1) delay(10);
  }

  pads.begin(&cap);
  flex.begin();

  Serial.println("LAUNCHPAD_READY");
}

void loop() {
  // Update sensor readings (with debounce + smoothing)
  pads.update();
  flex.update();

  // Send data at a fixed interval
  unsigned long now = millis();
  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;
    sendData();
  }
}

// Sends one line: "0100000010,75\n"
void sendData() {
  for (int i = 0; i < NUM_PADS; i++) {
    Serial.print(pads.isPressed(i) ? '1' : '0');
  }
  Serial.print(',');
  Serial.println(flex.getValue());
}
