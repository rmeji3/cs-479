// ============================================
// Simon Says Controller - Sensor Abstractions
// ============================================

#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include "Adafruit_MPR121.h"
#include "config.h"

class PadSensor {
public:
  void begin(Adafruit_MPR121* capSensor) {
    _cap = capSensor;
    for (int i = 0; i < NUM_PADS; i++) {
      _debouncedState[i] = false;
      _prevState[i] = false;
      _lastRawState[i] = false;
      _lastChangeTime[i] = 0;
    }
  }

  void update() {
    unsigned long now = millis();
    for (uint8_t i = 0; i < NUM_PADS; i++) {
      _prevState[i] = _debouncedState[i];
      bool raw = (_cap->filteredData(i) < TOUCH_THRESHOLD);
      if (raw != _lastRawState[i]) {
        _lastChangeTime[i] = now;
        _lastRawState[i] = raw;
      }
      if ((now - _lastChangeTime[i]) >= DEBOUNCE_MS) {
        _debouncedState[i] = raw;
      }
    }
  }

  bool isPressed(uint8_t pad) {
    return (pad < NUM_PADS) ? _debouncedState[pad] : false;
  }

private:
  Adafruit_MPR121* _cap;
  bool _debouncedState[NUM_PADS];
  bool _prevState[NUM_PADS];
  bool _lastRawState[NUM_PADS];
  unsigned long _lastChangeTime[NUM_PADS];
};

class FlexSensor {
public:
  void begin() {
    pinMode(FLEX_PIN, INPUT);
    _smoothed = analogRead(FLEX_PIN);
    _value = 0;
  }

  void update() {
    int raw = analogRead(FLEX_PIN);
    _smoothed = (_smoothed * FLEX_SMOOTH + raw) / (FLEX_SMOOTH + 1);
    _value = map(_smoothed, FLEX_FLAT, FLEX_BENT, 0, 100);
    _value = constrain(_value, 0, 100);
  }

  int getValue() { return _value; }

private:
  int _value;
  int _smoothed;
};

#endif
