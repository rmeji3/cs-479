// ============================================
// Launchpad Controller - Configuration
// ============================================

#ifndef CONFIG_H
#define CONFIG_H

// --- Pad Settings ---
#define NUM_PADS          10
#define TOUCH_THRESHOLD   6       // Raw filtered value below this = touched
#define DEBOUNCE_MS       30      // Debounce time in milliseconds

// --- Flex Sensor ---
#define FLEX_PIN          A0
#define FLEX_FLAT         700     // Raw ADC value when flat
#define FLEX_BENT         850     // Raw ADC value when fully bent
#define FLEX_SMOOTH       7       // Smoothing factor (higher = smoother, max 15)

// --- Communication ---
#define SERIAL_BAUD       115200
#define SEND_INTERVAL_MS  15      // How often to send data to Processing (ms)

#endif
