class RestingHRSession {
  int durationMs;
  boolean active = false;
  int startMs = 0;

  float sum = 0;
  int count = 0;
  float restingHR = -1;

  RestingHRSession(int durationMs) { this.durationMs = durationMs; }

  void start() {
    active = true;
    startMs = millis();
    sum = 0;
    count = 0;
  }

  void tick() {
    if (!active) return;
    if (millis() - startMs >= durationMs) finish();
  }

  void addSample(float hr, float confidence) {
    if (!active) return;
    if (hr < 30 || hr > 220) return;
    if (confidence < 70) return;
    sum += hr;
    count++;
  }

  void finish() {
    active = false;
    if (count > 0) restingHR = sum / count;
  }

  boolean isActive() { return active; }
  float getRestingHR() { return restingHR; }

  int secondsLeft() {
    if (!active) return 0;
    return max(0, (durationMs - (millis() - startMs)) / 1000);
  }
}
