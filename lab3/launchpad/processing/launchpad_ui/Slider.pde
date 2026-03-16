// ============================================
// Slider.pde - Vertical Fader with Knob Handle
// ============================================
// LED-segment bar with a draggable knob/handle
// at the current value. Interactive sliders
// have a highlighted knob.
// ============================================

class Slider {
  float x, y, w, h;
  String label;
  float value;
  float displayValue;
  boolean interactive;
  boolean isDragging;
  int numSegments = 16;

  int colorMode;
  color solidColor;

  String subtitle = "";
  color subtitleColor = color(255, 255, 255, 100);

  Slider(float x, float y, float w, float h,
         String label, boolean interactive, float defaultVal) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.interactive = interactive;
    this.value = defaultVal;
    this.displayValue = defaultVal;
    this.isDragging = false;
    this.colorMode = 0;
    this.solidColor = color(50, 200, 220);
  }

  void setSolidColor(color c) {
    colorMode = 1;
    solidColor = c;
  }

  void setValue(float v) {
    if (!isDragging) {
      value = constrain(v, 0, 100);
    }
  }

  void setSubtitle(String text, color c) {
    subtitle = text;
    subtitleColor = c;
  }

  // --- Mouse interaction ---

  boolean handleMousePressed(float mx, float my) {
    if (!interactive) return false;
    if (mx >= x - 6 && mx <= x + w + 6 && my >= y && my <= y + h) {
      isDragging = true;
      updateFromMouse(my);
      return true;
    }
    return false;
  }

  void handleMouseDragged(float mx, float my) {
    if (isDragging) {
      updateFromMouse(my);
    }
  }

  void handleMouseReleased() {
    isDragging = false;
  }

  void updateFromMouse(float my) {
    float barTop    = y + 12;
    float barBottom = y + h - 12;
    float pct = map(my, barBottom, barTop, 0, 100);
    value = constrain(pct, 0, 100);
  }

  // --- Drawing ---

  void draw() {
    displayValue = lerp(displayValue, value, 0.14);

    // Label
    fill(255, 255, 255, 160);
    textAlign(CENTER, BOTTOM);
    textSize(10);
    text(label, x + w / 2, y - 6);

    // Background panel
    noStroke();
    fill(26, 26, 44, 210);
    rect(x, y, w, h, 9);

    // Track groove (thin dark line down the center)
    fill(16, 16, 24);
    rect(x + w / 2 - 3, y + 10, 6, h - 20, 3);

    // LED segments
    float segH   = (h - 20) / numSegments;
    float segGap = 2.5;

    for (int i = 0; i < numSegments; i++) {
      float sy  = y + h - 10 - (i + 1) * segH;
      float pct = (float)(i + 1) / numSegments * 100;
      boolean lit = displayValue >= (pct - 100.0 / numSegments);

      float t = (float) i / numSegments;
      color segColor;

      if (colorMode == 0) {
        if (t < 0.5) {
          segColor = lerpColor(color(50, 210, 90), color(255, 220, 50), t * 2);
        } else {
          segColor = lerpColor(color(255, 220, 50), color(255, 55, 55), (t - 0.5) * 2);
        }
      } else {
        float b = 0.5 + t * 0.5;
        segColor = color(red(solidColor) * b, green(solidColor) * b, blue(solidColor) * b);
      }

      if (lit) {
        fill(segColor);
        int topLitSeg = int(displayValue / (100.0 / numSegments));
        if (i == topLitSeg) {
          fill(lerpColor(segColor, color(255), 0.22));
        }
      } else {
        fill(red(segColor) * 0.07, green(segColor) * 0.07, blue(segColor) * 0.07);
      }

      noStroke();
      rect(x + 6, sy + segGap / 2, w - 12, segH - segGap, 3);
    }

    // === KNOB / HANDLE at current value ===
    float barTop    = y + 12;
    float barBottom = y + h - 12;
    float knobY = map(displayValue, 0, 100, barBottom, barTop);
    float knobW = w + 8;
    float knobH = 14;
    float knobX = x - 4;

    // Knob shadow
    noStroke();
    fill(10, 10, 15, 80);
    rect(knobX + 2, knobY - knobH / 2 + 2, knobW - 2, knobH, 5);

    // Knob body
    if (interactive) {
      // Interactive: metallic look with highlight
      fill(isDragging ? 95 : 75, isDragging ? 95 : 75, isDragging ? 105 : 85);
    } else {
      // Read-only: subtle dark knob
      fill(55, 55, 62);
    }
    stroke(40, 40, 48);
    strokeWeight(1);
    rect(knobX, knobY - knobH / 2, knobW, knobH, 5);

    // Knob center line (grip detail)
    noStroke();
    fill(255, 255, 255, interactive ? 50 : 25);
    rect(knobX + knobW / 2 - 6, knobY - 1, 12, 2, 1);

    // Knob side notches (grip texture)
    if (interactive) {
      fill(255, 255, 255, 20);
      rect(knobX + 4, knobY - 3, knobW - 8, 1, 1);
      rect(knobX + 4, knobY + 2, knobW - 8, 1, 1);
    }

    // Drag highlight border
    if (isDragging) {
      noFill();
      stroke(255, 255, 255, 40);
      strokeWeight(2);
      rect(knobX - 1, knobY - knobH / 2 - 1, knobW + 2, knobH + 2, 6);
    }

    // Value text
    noStroke();
    fill(255, 255, 255, 170);
    textAlign(CENTER, TOP);
    textSize(13);
    text(int(displayValue), x + w / 2, y + h + 6);

    // Subtitle
    if (!subtitle.equals("")) {
      fill(subtitleColor);
      textSize(8);
      text(subtitle, x + w / 2, y + h + 23);
    }
  }
}
