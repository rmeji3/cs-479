// ============================================
// PadGrid.pde - 5x2 Circle Pad Grid
// ============================================
// Layout matches physical copper tape:
//
//   5  0
//   6  1
//   7  2
//   8  3
//   9  4
// ============================================

class PadGrid {
  CirclePad[] pads;
  int cols = 2;
  int rows = 5;
  int total = 10;

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

  PadGrid(float startX, float startY, float diameter, float gap) {
    pads = new CirclePad[total];

    float radius = diameter / 2;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Map grid position to pad index:
        // col 0 (left) = row + 5
        // col 1 (right) = row
        int idx = (col == 0) ? row + 5 : row;

        float cx = startX + radius + col * (diameter + gap);
        float cy = startY + radius + row * (diameter + gap);

        pads[idx] = new CirclePad(cx, cy, diameter, idx, colors[idx]);
      }
    }
  }

  void setLit(int index, boolean state) {
    if (index >= 0 && index < total) pads[index].setLit(state);
  }

  void flashPad(int index) {
    if (index >= 0 && index < total) pads[index].flash();
  }

  boolean isPadLit(int index) {
    return (index >= 0 && index < total) ? pads[index].lit : false;
  }

  void clearAll() {
    for (int i = 0; i < total; i++) pads[i].setLit(false);
  }

  void flashAll() {
    for (int i = 0; i < total; i++) pads[i].flash();
  }

  void draw() {
    for (int i = 0; i < total; i++) pads[i].draw();
  }
}
