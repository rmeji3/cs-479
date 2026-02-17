enum Zone {
  VERY_LIGHT(0, "Very Light (50–60%)", 50, 60, 0xFFA0A0A0),
  LIGHT(1, "Light (60–70%)",           60, 70, 0xFF50A0FF),
  MODERATE(2, "Moderate (70–80%)",     70, 80, 0xFF46B45A),
  HARD(3, "Hard (80–90%)",             80, 90, 0xFFFFAA3C),
  MAXIMUM(4, "Maximum (90–100%)",      90, 100, 0xFFF05050);

  int idx;
  String label;
  float loPct, hiPct;
  int col;

  Zone(int idx, String label, float loPct, float hiPct, int col) {
    this.idx = idx;
    this.label = label;
    this.loPct = loPct;
    this.hiPct = hiPct;
    this.col = col;
  }

  static Zone fromIndex(int i) {
    for (Zone z : values()) if (z.idx == i) return z;
    return VERY_LIGHT;
  }
}

int zoneIndexForHR(float hr, int maxHR) {
  float pct = (hr * 100.0) / maxHR;
  pct = constrain(pct, 0, 100);

  if (pct >= 90) return 4;
  if (pct >= 80) return 3;
  if (pct >= 70) return 2;
  if (pct >= 60) return 1;
  return 0;
}
