// ============================================
// FlexBar.pde - Horizontal Flex Input Bar
// ============================================
// A long 3D bar under the pad grid.
// Lights up gold when it's the flex's turn in
// the Simon Says sequence.
// ============================================

class FlexBar {
  float x, y, w, h;
  color barColor = color(255, 200, 50); // Gold

  boolean lit;
  float glowAmount;
  int flexValue;      // 0-100 from sensor
  boolean flexBent;   // true when player is bending past threshold
  int bendThreshold = 75;

  FlexBar(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.lit = false;
    this.glowAmount = 0;
    this.flexValue = 0;
    this.flexBent = false;
  }

  void setLit(boolean state) {
    if (state && !this.lit) {
      this.glowAmount = 1.0;
    }
    this.lit = state;
  }

  void flash() {
    setLit(true);
    // Will be unlit by game engine
  }

  void setFlexValue(int val) {
    flexValue = constrain(val, 0, 100);
    flexBent = (flexValue >= bendThreshold);
  }

  boolean contains(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void update() {
    if (lit) {
      glowAmount = lerp(glowAmount, 1.0, 0.3);
    } else {
      glowAmount *= 0.80;
      if (glowAmount < 0.01) glowAmount = 0;
    }
  }

  void draw() {
    update();

    float depth = lit ? 2 : 5;
    float cr    = 14;

    noStroke();

    // === GLOW ===
    if (glowAmount > 0.01) {
      for (int i = 4; i >= 0; i--) {
        float g = map(i, 0, 4, 2, 18) * glowAmount;
        float a = map(i, 0, 4, 45, 3) * glowAmount;
        fill(red(barColor), green(barColor), blue(barColor), a);
        rect(x - g, y - g, w + g * 2, h + g * 2, cr + 3);
      }
    }

    // === SHADOW ===
    fill(4, 4, 8, 40);
    rect(x + 5, y + h + depth - 1, w - 10, 4, 3);

    // === COLORED BODY (bottom depth) ===
    float bodyBr = lit ? 0.9 : 0.28;
    fill(red(barColor) * bodyBr, green(barColor) * bodyBr, blue(barColor) * bodyBr);
    rect(x, y + 2, w, h + depth, cr);

    // === DARK FACE ===
    float grey = lit ? 55 : 28;
    fill(grey, grey, grey + 2);
    rect(x, y, w, h, cr);

    // === FILL BAR (shows flex sensor level) ===
    if (flexValue > 2) {
      float fillW = map(flexValue, 0, 100, 0, w - 20);
      float fillAlpha = lit ? 200 : 80;
      fill(red(barColor), green(barColor), blue(barColor), fillAlpha);
      rect(x + 10, y + 8, fillW, h - 16, cr - 4);
    }

    // === LABEL ===
    fill(red(barColor), green(barColor), blue(barColor), lit ? 240 : 70);
    textAlign(CENTER, CENTER);
    textSize(14);
    text("F L E X", x + w / 2, y + h / 2 - 1);

    // === BENT INDICATOR ===
    if (flexBent) {
      fill(255, 220, 80, 200);
      textAlign(RIGHT, CENTER);
      textSize(11);
      text("BENT ●", x + w - 14, y + h / 2 - 1);
    }
  }
}
