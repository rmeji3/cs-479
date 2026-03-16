// ============================================
// CirclePad.pde - 3D Circle Button
// ============================================
// Dark grey circular face with a colored
// crescent at the bottom for 3D depth.
// Same visual language as the launchpad pads.
// ============================================

class CirclePad {
  float x, y, diameter;
  int index;
  color baseColor;

  boolean lit;
  float glowAmount;
  float pressScale;
  long autoReleaseTime = 0;

  CirclePad(float x, float y, float diameter, int index, color baseColor) {
    this.x = x;
    this.y = y;
    this.diameter = diameter;
    this.index = index;
    this.baseColor = baseColor;
    this.lit = false;
    this.glowAmount = 0;
    this.pressScale = 1.0;
  }

  void setLit(boolean state) {
    if (state && !this.lit) {
      this.glowAmount = 1.0;
      this.pressScale = 0.92;
    }
    this.lit = state;
    if (state) autoReleaseTime = 0;
  }

  void flash() {
    setLit(true);
    autoReleaseTime = millis() + 150;
  }

  boolean contains(float mx, float my) {
    return dist(mx, my, x, y) <= diameter / 2;
  }

  void update() {
    if (autoReleaseTime > 0 && millis() >= autoReleaseTime) {
      lit = false;
      autoReleaseTime = 0;
    }
    if (lit) {
      glowAmount = lerp(glowAmount, 1.0, 0.3);
    } else {
      glowAmount *= 0.80;
      if (glowAmount < 0.01) glowAmount = 0;
    }
    pressScale = lerp(pressScale, lit ? 0.96 : 1.0, 0.18);
  }

  void draw() {
    update();

    pushMatrix();
    translate(x, y);
    scale(pressScale);

    float d     = diameter;
    float depth = lit ? 2 : 6;

    noStroke();

    // === RING GLOW ===
    if (glowAmount > 0.01) {
      for (int i = 5; i >= 0; i--) {
        float g = map(i, 0, 5, 2, 26) * glowAmount;
        float a = map(i, 0, 5, 55, 3) * glowAmount;
        fill(red(baseColor), green(baseColor), blue(baseColor), a);
        ellipse(0, depth / 4, d + g * 2, d + g * 2);
      }
    }

    // === SHADOW ===
    fill(4, 4, 8, 45);
    ellipse(0, depth + 3, d - 10, d * 0.25);

    // === COLORED BODY (shifted down — darker shade for 3D depth) ===
    float bodyBr = lit ? 0.7 : 0.38;
    fill(constrain(red(baseColor) * bodyBr, 0, 255),
         constrain(green(baseColor) * bodyBr, 0, 255),
         constrain(blue(baseColor) * bodyBr, 0, 255));
    ellipse(0, depth / 2 + 1, d, d);

    // === COLORED FACE ===
    float faceBr = lit ? 1.3 : 0.85;
    fill(constrain(red(baseColor) * faceBr, 0, 255),
         constrain(green(baseColor) * faceBr, 0, 255),
         constrain(blue(baseColor) * faceBr, 0, 255));
    ellipse(0, 0, d - 2, d - 2);

    // === TEXT (darker shade for readability) ===
    float txtBr = lit ? 0.4 : 0.5;
    fill(red(baseColor) * txtBr, green(baseColor) * txtBr, blue(baseColor) * txtBr, lit ? 240 : 160);
    textAlign(CENTER, CENTER);
    textSize(20);
    text(index, 0, -2);

    popMatrix();
  }
}
