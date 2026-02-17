class Sample {
  long tMs;
  float hr;
  int zoneIdx;

  Sample(long tMs, float hr, int zoneIdx) {
    this.tMs = tMs;
    this.hr = hr;
    this.zoneIdx = zoneIdx;
  }
}

class FitnessSession {
  int maxHR;
  boolean active = false;
  long startMs = 0;
  long stopMs = 0;

  ArrayList<Sample> samples = new ArrayList<Sample>();
  long[] zoneMs = new long[5];

  long lastSampleMs = 0;
  int lastZoneIdx = 0;

  FitnessSession(int maxHR) { this.maxHR = maxHR; }

  void start() {
    active = true;
    samples.clear();
    Arrays.fill(zoneMs, 0);
    startMs = millis();
    lastSampleMs = 0;
  }

  void stop() {
    active = false;
    stopMs = millis();
    if (lastSampleMs != 0) zoneMs[lastZoneIdx] += (millis() - lastSampleMs);
  }

  void tick() {}

  void addSample(float hr) {
    if (!active) return;
    if (hr < 20 || hr > 250) return;

    long now = millis();
    int z = zoneIndexForHR(hr, maxHR);
    samples.add(new Sample(now, hr, z));

    if (lastSampleMs != 0) zoneMs[lastZoneIdx] += (now - lastSampleMs);
    lastSampleMs = now;
    lastZoneIdx = z;
  }

  boolean isActive() { return active; }

  long getActiveMs() {
    if (active) return millis() - startMs;
    if (startMs == 0) return 0;
    return stopMs - startMs;
  }

  long getZoneMs(int idx) {
    long t = zoneMs[idx];
    if (active && lastSampleMs != 0 && idx == lastZoneIdx) t += (millis() - lastSampleMs);
    return t;
  }

  float minHRSeen() {
    float m = Float.POSITIVE_INFINITY;
    for (Sample s : samples) m = min(m, s.hr);
    return (m == Float.POSITIVE_INFINITY) ? 0 : m;
  }

  float maxHRSeen() {
    float m = Float.NEGATIVE_INFINITY;
    for (Sample s : samples) m = max(m, s.hr);
    return (m == Float.NEGATIVE_INFINITY) ? 0 : m;
  }
}
