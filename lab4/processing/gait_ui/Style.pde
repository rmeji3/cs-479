class Style {
  static final color BG = #F0F2F5;
  static final color PANEL = #FFFFFF;
  static final color ACCENT = #007AFF;
  static final color TEXT_MAIN = #1D1D1F;
  static final color TEXT_DIM = #6E6E73;
  static final color RED = #FF3B30;
  static final color GREEN = #34C759;
  static final color BLUE = #007AFF;
  static final color DARK = #D2D2D7;
  static final color HOVER = #E8E8ED;
  
  void card(float x, float y, float w, float h, String title) {
    fill(PANEL);
    noStroke();
    rect(x, y, w, h, 12);
    
    // Main card background with border
    fill(PANEL);
    stroke(BORDER);
    strokeWeight(1);
    rect(x, y, w, h, 12);
    noStroke();
    
    // Title background gradient effect
    fill(ACCENT_LIGHT);
    rect(x, y, w, 45, 12, 12, 0, 0);
    
    // Title text
    fill(ACCENT);
    textSize(20);
    textAlign(LEFT, TOP);
    text(title, x + 20, y + 20);
    
    stroke(DARK);
    strokeWeight(1);
    line(x + 20, y + 55, x + w - 20, y + 55);
  }

  boolean button(float x, float y, float w, float h, String label, color baseColor, boolean active, float translateX) {
    boolean hover = mouseX > x + translateX && mouseX < x + w + translateX && 
                    mouseY > y && mouseY < y + h;
    
    if (active) {
      fill(baseColor);
    } else if (hover) {
      // Darken slightly for hover in light mode
      fill(red(baseColor)*0.9, green(baseColor)*0.9, blue(baseColor)*0.9);
    } else {
      fill(235);
    }
    
    noStroke();
    rect(x, y, w, h, 8);
    
    // In light mode, active buttons get white text.
    // Neutral buttons (baseColor == 100) also get white text on hover.
    if (active || (hover && (baseColor != 40 && baseColor != 235))) {
      fill(255);
    } else {
      fill(TEXT_MAIN);
    }
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2);
    
    return hover && mousePressed;
  }
}
