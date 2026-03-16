// ============================================
// Pad.pde - 3D Button (CLICK ME Style)
// ============================================
// Dark grey face on top, darker colored body
// only visible at the BOTTOM as a depth band.
// No colored border at top or sides.
// ============================================

class Pad {
  float x, y, w, h;
  int index;
  String label;
  color baseColor;

  boolean pressed;
  float glowAmount;
  float pressScale;
  long autoReleaseTime = 0;

  float cornerR = 18;

  Pad(float x, float y, float w, float h, int index, String label, color baseColor) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.index = index;
    this.label = label;
    this.baseColor = baseColor;
    this.pressed = false;
    this.glowAmount = 0;
    this.pressScale = 1.0;
  }

  void setPressed(boolean state) {
    if (state && !this.pressed) {
      this.glowAmount = 1.0;
      this.pressScale = 0.94;
    }
    this.pressed = state;
    if (state) autoReleaseTime = 0;
  }

  void triggerFlash() {
    setPressed(true);
    autoReleaseTime = millis() + 120;
  }

  boolean contains(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void update() {
    if (autoReleaseTime > 0 && millis() >= autoReleaseTime) {
      pressed = false;
      autoReleaseTime = 0;
    }
    if (pressed) {
      glowAmount = lerp(glowAmount, 1.0, 0.3);
    } else {
      glowAmount *= 0.82;
      if (glowAmount < 0.01) glowAmount = 0;
    }
    pressScale = lerp(pressScale, pressed ? 0.97 : 1.0, 0.2);
  }

  void draw() {
    update();
    pushMatrix();
    translate(x + w / 2, y + h / 2);
    scale(pressScale);

    float depth = pressed ? 2 : 7;
    float cr = cornerR;
    noStroke();

    // === RING GLOW ===
    if (glowAmount > 0.01) {
      for (int i = 5; i >= 0; i--) {
        float g = map(i, 0, 5, 2, 28) * glowAmount;
        float a = map(i, 0, 5, 55, 3) * glowAmount;
        fill(red(baseColor), green(baseColor), blue(baseColor), a);
        rect(-w / 2 - g, -h / 2 - g,
             w + g * 2, h + depth + g * 2, cr + g * 0.4);
      }
    }

    // === SHADOW ===
    fill(4, 4, 8, 55);
    rect(-w / 2 + 5, h / 2 + depth - 1, w - 10, 5, 3);

    // === COLORED BODY (only bottom peeks out) ===
    // Same width as face, but starts lower and extends deeper
    float bodyBr = pressed ? 1.0 : 0.45;
    fill(constrain(red(baseColor) * bodyBr, 0, 255),
         constrain(green(baseColor) * bodyBr, 0, 255),
         constrain(blue(baseColor) * bodyBr, 0, 255));
    rect(-w / 2, -h / 2 + 3, w, h + depth, cr);

    // === DARK GREY FACE (covers everything except bottom band) ===
    float grey = pressed ? 50 : 30;
    fill(grey, grey, grey + 2);
    rect(-w / 2, -h / 2, w, h, cr);

    // === TEXT ===
    fill(255, 255, 255, pressed ? 255 : 155);
    textAlign(CENTER, CENTER);
    textSize(24);
    text(index, 0, -10);

    fill(red(baseColor), green(baseColor), blue(baseColor), pressed ? 255 : 125);
    textSize(9);
    text(label, 0, 16);

    popMatrix();
  }
}
