// ── Serial ────────────────────────────────────────────
export const BAUD_RATE = 115200;

// ── Blind spot ────────────────────────────────────────
/** Distance (mm) at or below which the blind spot alert fires */
export const BLIND_SPOT_THRESHOLD_MM = 1500;

/** Distance zones (mm) for colour coding */
export const DISTANCE_DANGER_MM = 500;
export const DISTANCE_WARNING_MM = 1000;

// ── Impact / fall ─────────────────────────────────────
/** Acceleration magnitude (m/s²) that counts as a fall/impact event */
export const FALL_THRESHOLD = 20;

// ── Health ────────────────────────────────────────────
export const SPO2_LOW = 95; // below this is concerning
export const BPM_LOW = 50;
export const BPM_HIGH = 160;

// ── Mic ───────────────────────────────────────────────
/** Peak ADC counts (0–4095) above which the environment is considered loud */
export const MIC_LOUD_THRESHOLD = 800;

// ── Chart history ─────────────────────────────────────
export const CHART_HISTORY = 60; // number of data points to retain for graphs
