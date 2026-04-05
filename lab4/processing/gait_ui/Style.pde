class Style {
  static final color BG = #FFFFFF;
  static final color PANEL = #F5F5F5;
  static final color ACCENT = #0088CC;
  static final color TEXT_MAIN = #000000;
  static final color TEXT_DIM = #666666;
  static final color RED = #CC0000;
  static final color GREEN = #008800;
  static final color BLUE = #0000CC;
  
  void card(float x, float y, float w, float h, String title) {
    fill(PANEL);
    noStroke();
    rect(x, y, w, h, 8);
    
    fill(ACCENT);
    textSize(16);
    textAlign(LEFT, TOP);
    text(title, x + 15, y + 15);
    
    stroke(#CCCCCC);
    line(x + 15, y + 40, x + w - 15, y + 40);
  }
}
