class Style {
  static final color BG = #121212;
  static final color PANEL = #1E1E1E;
  static final color ACCENT = #00FFCC;
  static final color TEXT_MAIN = #FFFFFF;
  static final color TEXT_DIM = #AAAAAA;
  static final color RED = #FF5555;
  static final color GREEN = #55FF55;
  static final color BLUE = #5555FF;
  static final color DARK = #0A0A0A;
  static final color HOVER = #333333;
  
  void card(float x, float y, float w, float h, String title) {
    fill(PANEL);
    noStroke();
    rect(x, y, w, h, 12);
    
    fill(ACCENT);
    textSize(18);
    textAlign(LEFT, TOP);
    text(title, x + 20, y + 20);
    
    stroke(PANEL + 15);
    strokeWeight(1);
    line(x + 20, y + 50, x + w - 20, y + 50);
  }

  boolean button(float x, float y, float w, float h, String label, color baseColor, boolean active, float translateX) {
    boolean hover = mouseX > x + translateX && mouseX < x + w + translateX && 
                    mouseY > y && mouseY < y + h;
    
    if (active) {
      fill(baseColor);
    } else if (hover) {
      fill(red(baseColor)*0.8, green(baseColor)*0.8, blue(baseColor)*0.8);
    } else {
      fill(40);
    }
    
    noStroke();
    rect(x, y, w, h, 8);
    
    // If it is a neutral button (baseColor == 100), make text white on hover/active
    if (baseColor == 100 && (active || hover)) {
      fill(255);
    } else {
      fill(active || hover ? 0 : 200);
    }
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2);
    
    return hover && mousePressed;
  }
}
