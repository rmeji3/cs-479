// ============================================
// SoundManager.pde - Audio Playback
// ============================================

class SoundManager {
  Minim minim;
  AudioSample[] samples;
  boolean[] loaded;
  float gainDB = 0;

  long[] padPressStart;
  long[] lastTriggerTime;
  int[] sampleLengthMs;
  int holdDelayMs = 200;
  float speedMultiplier = 1.0;

  String[] fileNames = {
    "absolutely-insane-kikdrum.wav",
    "ec-sn084.wav",
    "ec-hat004.wav",
    "bright-fat-synth.wav",
    "707-clap.wav",
    "distortotom.wav",
    "electric-reverse-crash.wav",
    "bleep_1.wav",
    "classicrave.wav",
    "strange-widdly-synth-spring-verb.wav"
  };

  SoundManager(PApplet parent) {
    minim           = new Minim(parent);
    samples         = new AudioSample[10];
    loaded          = new boolean[10];
    padPressStart   = new long[10];
    lastTriggerTime = new long[10];
    sampleLengthMs  = new int[10];

    println("--- Loading Sounds ---");
    for (int i = 0; i < 10; i++) {
      try {
        samples[i] = minim.loadSample(fileNames[i], 2048);
        loaded[i]  = (samples[i] != null);
        if (loaded[i]) {
          sampleLengthMs[i] = samples[i].length();
          println("  [OK]   Pad " + i + " (" + sampleLengthMs[i] + "ms)");
        } else {
          sampleLengthMs[i] = 500;
        }
      } catch (Exception e) {
        println("  [ERR]  Pad " + i + ": " + e.getMessage());
        loaded[i] = false;
        sampleLengthMs[i] = 500;
      }
    }
    println("---");
  }

  void play(int index) {
    if (index >= 0 && index < 10 && loaded[index]) {
      samples[index].setGain(gainDB);
      samples[index].trigger();
      vuLevel = min(vuLevel + 35, 100);
    }
  }

  void setVolume(float volumePct) {
    gainDB = map(volumePct, 0, 100, -14, 4);
  }

  // Stop ALL currently playing sounds immediately
  void stopAllSounds() {
    for (int i = 0; i < 10; i++) {
      if (loaded[i]) {
        samples[i].stop();
      }
    }
  }

  void updateHeldPads() {
    long now = millis();
    for (int i = 0; i < 10; i++) {
      if (padGrid.isPadPressed(i)) {
        if (padPressStart[i] == 0) {
          padPressStart[i] = now;
          lastTriggerTime[i] = now;
        }
        long heldFor = now - padPressStart[i];
        if (heldFor >= holdDelayMs) {
          int repeatInterval = max(int(sampleLengthMs[i] * speedMultiplier), 80);
          if (now - lastTriggerTime[i] >= repeatInterval) {
            play(i);
            lastTriggerTime[i] = now;
          }
        }
      } else {
        padPressStart[i] = 0;
        lastTriggerTime[i] = 0;
      }
    }
  }

  void cleanup() {
    for (int i = 0; i < 10; i++) {
      if (loaded[i]) samples[i].close();
    }
    minim.stop();
  }
}
