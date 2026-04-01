class Style {
  static final color BG = #121212;
  static final color PANEL = #1E1E1E;
  static final color ACCENT = #00FFCC;
  static final color TEXT_MAIN = #FFFFFF;
  static final color TEXT_DIM = #AAAAAA;
  static final color RED = #FF5555;
  static final color GREEN = #55FF55;
  static final color BLUE = #5555FF;
  
  void card(float x, float y, float w, float h, String title) {
    fill(PANEL);
    noStroke();
    rect(x, y, w, h, 8);
    
    fill(ACCENT);
    textSize(16);
    textAlign(LEFT, TOP);
    text(title, x + 15, y + 15);
    
    stroke(PANEL + 20);
    line(x + 15, y + 40, x + w - 15, y + 40);
  }
}
