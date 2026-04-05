class Style {
  // Modern aesthetic color palette
  static final color BG = #F8FAFC;                    // Soft white-blue background
  static final color PANEL = #FFFFFF;                 // Clean white panels
  static final color ACCENT = #0F5FDF;               // Rich professional blue
  static final color ACCENT_LIGHT = #E0F0FF;         // Light blue accent
  static final color TEXT_MAIN = #1A202C;            // Deep charcoal
  static final color TEXT_DIM = #718096;             // Medium gray
  static final color RED = #E63946;                  // Modern red
  static final color GREEN = #2ECC71;                // Modern green
  static final color BLUE = #3498DB;                 // Modern bright blue
  static final color SHADOW = #00000015;             // Soft shadow
  static final color BORDER = #E2E8F0;               // Subtle border
  
  void card(float x, float y, float w, float h, String title) {
    // Shadow effect
    fill(SHADOW);
    rect(x + 2, y + 2, w, h, 12);
    
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
    textSize(16);
    textAlign(LEFT, TOP);
    text(title, x + 15, y + 15);
    
    // Divider
    stroke(BORDER);
    strokeWeight(1);
    line(x + 15, y + 40, x + w - 15, y + 40);
    noStroke();
  }
}
