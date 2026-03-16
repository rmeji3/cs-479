// ============================================
// Simon Says Controller - Main Sketch
// ============================================
// Reads 11 capacitive touch pads (0-9 game +
// 10 end game) and a flex sensor. Streams
// data to Processing.
//
// Serial Protocol:
//   BBBBBBBBBBB,FFF\n
//   11 chars for pads 0-10, comma, flex 0-100
// ============================================

#include <Wire.h>
#include "Adafruit_MPR121.h"
#include "config.h"
#include "sensors.h"

Adafruit_MPR121 cap = Adafruit_MPR121();
PadSensor pads;
FlexSensor flex;
unsigned long lastSendTime = 0;

void setup() {
  Serial.begin(SERIAL_BAUD);
  while (!Serial) delay(10);

  Serial.println("SIMON_INIT");

  if (!cap.begin()) {
    Serial.println("MPR121_ERROR");
    while (1) delay(10);
  }

  pads.begin(&cap);
  flex.begin();

  Serial.println("SIMON_READY");
}

void loop() {
  pads.update();
  flex.update();

  unsigned long now = millis();
  if (now - lastSendTime >= SEND_INTERVAL_MS) {
    lastSendTime = now;
    sendData();
  }
}

// Sends: "00100000001,75\n"
void sendData() {
  for (int i = 0; i < NUM_PADS; i++) {
    Serial.print(pads.isPressed(i) ? '1' : '0');
  }
  Serial.print(',');
  Serial.println(flex.getValue());
}
