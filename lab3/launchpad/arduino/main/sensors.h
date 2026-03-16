// ============================================
// Launchpad Controller - Sensor Abstractions
// ============================================

#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include "Adafruit_MPR121.h"
#include "config.h"

// ============================================
// PadSensor: Reads MPR121 with per-pad debounce
// ============================================
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
      // Save previous debounced state for edge detection
      _prevState[i] = _debouncedState[i];

      // Read raw touch state using our custom threshold
      bool raw = (_cap->filteredData(i) < TOUCH_THRESHOLD);

      // If raw state changed, reset the debounce timer
      if (raw != _lastRawState[i]) {
        _lastChangeTime[i] = now;
        _lastRawState[i] = raw;
      }

      // Only accept the new state if it's been stable for DEBOUNCE_MS
      if ((now - _lastChangeTime[i]) >= DEBOUNCE_MS) {
        _debouncedState[i] = raw;
      }
    }
  }

  bool isPressed(uint8_t pad) {
    return (pad < NUM_PADS) ? _debouncedState[pad] : false;
  }

  bool justPressed(uint8_t pad) {
    return (pad < NUM_PADS) ? (_debouncedState[pad] && !_prevState[pad]) : false;
  }

  bool justReleased(uint8_t pad) {
    return (pad < NUM_PADS) ? (!_debouncedState[pad] && _prevState[pad]) : false;
  }

private:
  Adafruit_MPR121* _cap;
  bool _debouncedState[NUM_PADS];
  bool _prevState[NUM_PADS];
  bool _lastRawState[NUM_PADS];
  unsigned long _lastChangeTime[NUM_PADS];
};

// ============================================
// FlexSensor: Reads analog flex with smoothing
// ============================================
class FlexSensor {
public:
  void begin() {
    pinMode(FLEX_PIN, INPUT);
    // Seed the smoothed value with a real reading
    _smoothed = analogRead(FLEX_PIN);
    _value = 0;
  }

  void update() {
    int raw = analogRead(FLEX_PIN);

    // Exponential moving average for smooth readings
    _smoothed = (_smoothed * FLEX_SMOOTH + raw) / (FLEX_SMOOTH + 1);

    // Map to 0-100 and constrain
    _value = map(_smoothed, FLEX_FLAT, FLEX_BENT, 0, 100);
    _value = constrain(_value, 0, 100);
  }

  int getValue() {
    return _value;
  }

  int getRaw() {
    return _smoothed;
  }

private:
  int _value;
  int _smoothed;
};

#endif
