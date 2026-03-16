// ============================================
// SoundManager.pde - Sound Playback
// ============================================
// Gracefully handles missing files and
// prevents Minim crash on disposal.
// ============================================

class SoundManager {
  Minim minim;
  AudioSample[] samples;
  boolean[] loaded;
  AudioSample failSound;
  boolean failLoaded = false;

  SoundManager(PApplet parent) {
    minim   = new Minim(parent);
    samples = new AudioSample[11];
    loaded  = new boolean[11];

    String[] names = {
      "pad_0.wav", "pad_1.wav", "pad_2.wav", "pad_3.wav", "pad_4.wav",
      "pad_5.wav", "pad_6.wav", "pad_7.wav", "pad_8.wav", "pad_9.wav",
      "flex.wav"
    };

    println("--- Loading Sounds ---");
    for (int i = 0; i < 11; i++) {
      try {
        samples[i] = minim.loadSample(names[i], 2048);
        loaded[i]  = (samples[i] != null);
        println(loaded[i] ? "  [OK]   " + names[i] : "  [MISS] " + names[i]);
      } catch (Exception e) {
        loaded[i] = false;
        println("  [MISS] " + names[i]);
      }
    }

    try {
      failSound = minim.loadSample("fail.wav", 2048);
      failLoaded = (failSound != null);
    } catch (Exception e) {
      failLoaded = false;
    }
    println("---");
  }

  void play(int index) {
    if (index >= 0 && index < 11 && loaded[index]) {
      samples[index].trigger();
    }
  }

  void playFail() {
    if (failLoaded) failSound.trigger();
  }

  void cleanup() {
    try {
      for (int i = 0; i < 11; i++) {
        if (loaded[i] && samples[i] != null) {
          samples[i].close();
          loaded[i] = false;
        }
      }
      if (failLoaded && failSound != null) {
        failSound.close();
        failLoaded = false;
      }
      // Don't call minim.stop() — Minim auto-disposes itself
      // Calling it manually causes a NullPointerException
    } catch (Exception e) {
      // Ignore cleanup errors
    }
  }
}
