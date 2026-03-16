// ============================================
// PadGrid.pde - 2x5 Launchpad Grid Layout
// ============================================
// Visual layout (reversed bottom row):
//
//   ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
//   │  9 │ │  8 │ │  7 │ │  6 │ │  5 │  ← top
//   └────┘ └────┘ └────┘ └────┘ └────┘
//   ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
//   │  0 │ │  1 │ │  2 │ │  3 │ │  4 │  ← bottom
//   └────┘ └────┘ └────┘ └────┘ └────┘
// ============================================

class PadGrid {
  Pad[] pads;
  int cols = 5;
  int rows = 2;

  String[] labels = {
    "KICK",       // 0
    "SNARE",      // 1
    "HI-HAT",     // 2
    "SYNTH",      // 3
    "CLAP",       // 4
    "TOM",        // 5
    "CRASH",      // 6
    "BLEEP",      // 7
    "RAVE",       // 8
    "WIDDLY"      // 9
  };

  color[] colors = {
    #FF3250,   // 0: Red
    #FF8C32,   // 1: Orange
    #FFDC32,   // 2: Yellow
    #32DC64,   // 3: Green
    #32C8DC,   // 4: Cyan
    #3278FF,   // 5: Blue
    #8250FF,   // 6: Indigo
    #C850FF,   // 7: Purple
    #FF50B4,   // 8: Pink
    #FF6464    // 9: Coral
  };

  PadGrid(float startX, float startY, float padSize, float gap) {
    pads = new Pad[10];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        int padIndex;
        if (row == 0) {
          // Top row: 9, 8, 7, 6, 5 (right to left)
          padIndex = 9 - col;
        } else {
          // Bottom row: 0, 1, 2, 3, 4 (left to right)
          padIndex = col;
        }

        float px = startX + col * (padSize + gap);
        float py = startY + row * (padSize + gap);

        pads[padIndex] = new Pad(px, py, padSize, padSize,
                                  padIndex, labels[padIndex], colors[padIndex]);
      }
    }
  }

  void setPadState(int index, boolean pressed) {
    if (index >= 0 && index < 10) {
      pads[index].setPressed(pressed);
    }
  }

  boolean isPadPressed(int index) {
    if (index >= 0 && index < 10) {
      return pads[index].pressed;
    }
    return false;
  }

  // Flash a pad briefly (for loop playback)
  void flashPad(int index) {
    if (index >= 0 && index < 10) {
      pads[index].triggerFlash();
    }
  }

  void draw() {
    for (int i = 0; i < 10; i++) {
      pads[i].draw();
    }
  }
}
