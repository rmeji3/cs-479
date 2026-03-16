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
  AudioSample wrongSound;
  boolean wrongLoaded = false;
  AudioSample correctSound;
  boolean correctLoaded = false;

  SoundManager(PApplet parent) {
    minim   = new Minim(parent);
    samples = new AudioSample[11];
    loaded  = new boolean[11];

    String[] names = {
      "a#6.mp3", "a6.mp3", "b6.mp3", "c6.mp3", "cine-note.mp3",
      "d6.mp3", "e6.mp3", "f6.mp3", "g#6.mp3", "g6.mp3",
      "g.mp3"
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

    // g.mp3 (flex sound) plays at half volume
    if (loaded[10]) {
      samples[10].setGain(-6);
    }

    try {
      wrongSound = minim.loadSample("wrong.mp3", 2048);
      wrongLoaded = (wrongSound != null);
      println(wrongLoaded ? "  [OK]   wrong.mp3" : "  [MISS] wrong.mp3");
    } catch (Exception e) { wrongLoaded = false; }

    try {
      correctSound = minim.loadSample("correct.mp3", 2048);
      correctLoaded = (correctSound != null);
      println(correctLoaded ? "  [OK]   correct.mp3" : "  [MISS] correct.mp3");
    } catch (Exception e) { correctLoaded = false; }
    println("---");
  }

  void play(int index) {
    if (index >= 0 && index < 11 && loaded[index]) {
      samples[index].trigger();
    }
  }

  void playWrong() {
    if (wrongLoaded) wrongSound.trigger();
  }

  void playCorrect() {
    if (correctLoaded) correctSound.trigger();
  }

  void cleanup() {
    try {
      for (int i = 0; i < 11; i++) {
        if (loaded[i] && samples[i] != null) {
          samples[i].close();
          loaded[i] = false;
        }
      }
      if (wrongLoaded && wrongSound != null) {
        wrongSound.close();
        wrongLoaded = false;
      }
      if (correctLoaded && correctSound != null) {
        correctSound.close();
        correctLoaded = false;
      }
      // Don't call minim.stop() — Minim auto-disposes itself
      // Calling it manually causes a NullPointerException
    } catch (Exception e) {
      // Ignore cleanup errors
    }
  }
}
