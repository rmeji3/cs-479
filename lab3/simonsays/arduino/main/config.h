// ============================================
// Simon Says Controller - Configuration
// ============================================

#ifndef CONFIG_H
#define CONFIG_H

// --- Pad Settings ---
#define NUM_PADS          11      // 0-9 game pads + 10 end game button
#define TOUCH_THRESHOLD   6
#define DEBOUNCE_MS       30

// --- Flex Sensor ---
#define FLEX_PIN          A0
#define FLEX_FLAT         700
#define FLEX_BENT         850
#define FLEX_SMOOTH       7

// --- Communication ---
#define SERIAL_BAUD       115200
#define SEND_INTERVAL_MS  15

#endif
