// ============================================
// LoopRecorder.pde - 10-Slot Loop Bank (2x5)
// ============================================
// Bigger slots in a 2x5 grid with same 3D
// style as the pads. Click to toggle, X to
// delete. Stopping a loop stops sounds immediately.
// ============================================

class LoopEvent {
  int padIndex;
  long timeOffset;
  long lastFiredCycle;

  LoopEvent(int padIndex, long timeOffset) {
    this.padIndex = padIndex;
    this.timeOffset = timeOffset;
    this.lastFiredCycle = -1;
  }
}

class LoopSlot {
  ArrayList<LoopEvent> events = new ArrayList<LoopEvent>();
  long duration;
  long playStartTime;
  boolean playing = false;
  boolean hasData = false;

  void startPlayback() {
    playing = true;
    playStartTime = millis();
    for (LoopEvent e : events) e.lastFiredCycle = -1;
  }

  void stopPlayback() {
    playing = false;
  }

  void clear() {
    events.clear();
    duration = 0;
    playing = false;
    hasData = false;
  }
}

class LoopRecorder {
  static final int IDLE      = 0;
  static final int RECORDING = 1;

  int state = IDLE;
  LoopSlot[] slots = new LoopSlot[10];
  int activeRecSlot = -1;
  long recordStartTime;

  boolean prevFlexBent = false;
  int flexThreshold = 75;

  // 2x5 grid layout params
  float bankX, bankY;
  float slotW   = 130;
  float slotH   = 40;
  float slotGapX = 16;
  float slotGapY = 12;
  int bankCols = 5;
  int bankRows = 2;

  LoopRecorder() {
    for (int i = 0; i < 10; i++) {
      slots[i] = new LoopSlot();
    }
  }

  // --- Flex ---

  void updateFlex(int flexValue) {
    boolean bent = (flexValue >= flexThreshold);
    if (bent && !prevFlexBent) onFlexTrigger();
    prevFlexBent = bent;
  }

  void onFlexTrigger() {
    if (state == IDLE) {
      int slot = findEmptySlot();
      if (slot >= 0) {
        activeRecSlot = slot;
        startRecording();
      }
    } else if (state == RECORDING) {
      stopRecording();
    }
  }

  int findEmptySlot() {
    for (int i = 0; i < 10; i++) {
      if (!slots[i].hasData) return i;
    }
    return -1;
  }

  void startRecording() {
    state = RECORDING;
    slots[activeRecSlot].clear();
    recordStartTime = millis();
  }

  void stopRecording() {
    long dur = millis() - recordStartTime;
    if (dur < 300 || slots[activeRecSlot].events.size() == 0) {
      slots[activeRecSlot].clear();
    } else {
      slots[activeRecSlot].duration = dur;
      slots[activeRecSlot].hasData = true;
      slots[activeRecSlot].startPlayback();
    }
    state = IDLE;
    activeRecSlot = -1;
  }

  void toggleSlot(int i) {
    if (slots[i].hasData) {
      if (slots[i].playing) {
        slots[i].stopPlayback();
        soundManager.stopAllSounds();
      } else {
        slots[i].startPlayback();
      }
    }
  }

  void deleteSlot(int i) {
    if (slots[i].playing) {
      soundManager.stopAllSounds();
    }
    slots[i].clear();
  }

  void recordPad(int padIndex) {
    if (state == RECORDING && activeRecSlot >= 0) {
      long offset = millis() - recordStartTime;
      slots[activeRecSlot].events.add(new LoopEvent(padIndex, offset));
    }
  }

  // --- Playback ---

  void update() {
    for (int s = 0; s < 10; s++) {
      LoopSlot slot = slots[s];
      if (!slot.playing || slot.duration == 0) continue;

      long now = millis();
      long totalElapsed = now - slot.playStartTime;
      long currentCycle = totalElapsed / slot.duration;
      long posInCycle   = totalElapsed % slot.duration;

      for (LoopEvent e : slot.events) {
        if (e.lastFiredCycle < currentCycle && posInCycle >= e.timeOffset) {
          soundManager.play(e.padIndex);
          padGrid.flashPad(e.padIndex);
          e.lastFiredCycle = currentCycle;
        }
      }
    }
  }

  // --- Click handling ---

  boolean handleClick(float mx, float my) {
    for (int i = 0; i < 10; i++) {
      int col = i % bankCols;
      int row = i / bankCols;
      float sx = bankX + col * (slotW + slotGapX);
      float sy = bankY + row * (slotH + slotGapY);

      if (mx >= sx && mx <= sx + slotW && my >= sy && my <= sy + slotH + 4) {
        // X button (top-right, 20x18 hit area)
        if (slots[i].hasData && mx >= sx + slotW - 22 && my <= sy + 18) {
          deleteSlot(i);
          return true;
        }
        toggleSlot(i);
        return true;
      }
    }
    return false;
  }

  // --- Drawing ---

  void drawBank(float x, float y) {
    bankX = x;
    bankY = y;

    for (int i = 0; i < 10; i++) {
      int col = i % bankCols;
      int row = i / bankCols;
      float sx = x + col * (slotW + slotGapX);
      float sy = y + row * (slotH + slotGapY);
      drawSlot(i, sx, sy);
    }
  }

  void drawSlot(int i, float sx, float sy) {
    LoopSlot slot = slots[i];
    float depth = 4;
    float cr = 10;

    // Color based on state
    color slotColor;
    boolean isRec = (state == RECORDING && i == activeRecSlot);
    if (isRec) {
      slotColor = color(255, 60, 60);
    } else if (slot.playing) {
      slotColor = color(50, 220, 120);
    } else if (slot.hasData) {
      slotColor = color(80, 150, 220);
    } else {
      slotColor = color(55, 55, 60);
    }

    noStroke();

    // Shadow
    fill(4, 4, 8, 40);
    rect(sx + 4, sy + slotH + 1, slotW - 8, depth + 2, 3);

    // Colored body (only bottom peeks out — same as pads)
    float br = (slot.playing || isRec) ? 0.85 : 0.4;
    fill(red(slotColor) * br, green(slotColor) * br, blue(slotColor) * br);
    rect(sx, sy + 2, slotW, slotH + depth, cr);

    // Dark face
    float grey = (slot.playing || isRec) ? 42 : 28;
    fill(grey, grey, grey + 2);
    rect(sx, sy, slotW, slotH, cr);

    // Slot number
    fill(255, 255, 255, slot.hasData ? 190 : 45);
    textAlign(CENTER, CENTER);
    textSize(15);
    text(i + 1, sx + slotW / 2 - 2, sy + slotH / 2 - 1);

    // X button (bigger, clear)
    if (slot.hasData && !isRec) {
      // X background circle
      float xbx = sx + slotW - 16;
      float xby = sy + 14;
      fill(255, 60, 60, 50);
      ellipse(xbx, xby, 18, 18);
      fill(255, 100, 100, 200);
      textAlign(CENTER, CENTER);
      textSize(13);
      text("✕", xbx, xby - 1);
    }

    // Playing indicator
    if (slot.playing) {
      float blink = (sin(millis() * 0.006 + i * 0.7) + 1) * 0.5;
      fill(50, 255, 130, 130 + 125 * blink);
      ellipse(sx + 14, sy + slotH - 10, 7, 7);
    }

    // Recording blink
    if (isRec) {
      float blink = (sin(millis() * 0.012) + 1) * 0.5;
      fill(255, 50, 50, 100 + 155 * blink);
      ellipse(sx + 14, sy + slotH - 10, 8, 8);
    }
  }

  // --- Status ---

  String getStatusText() {
    if (state == RECORDING) return "● RECORDING — bend flex to stop";
    int empty = 0;
    for (int i = 0; i < 10; i++) if (!slots[i].hasData) empty++;
    if (empty == 0) return "LOOP BANK FULL — delete a slot to record";
    return "LOOP RECORDER — bend flex to record (" + empty + " free)";
  }

  color getStatusColor() {
    return (state == RECORDING) ? color(255, 60, 60) : color(130, 130, 140);
  }
}
