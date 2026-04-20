class RecommendationsPanel {
  float x, y, w, h;
  
  RecommendationsPanel(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  void display(Style style, Recommendation rec, String gaitType) {
    pushMatrix();
    translate(x, y);
    
    // Card background
    fill(style.PANEL);
    stroke(#CCCCCC);
    strokeWeight(1);
    rect(0, 0, w, h, 8);
    
    // Title
    fill(style.ACCENT);
    textSize(13);
    textAlign(LEFT, TOP);
    text("SHOE & EXERCISE RECOMMENDATIONS", 12, 12);
    
    // Gait Classification  
    stroke(#CCCCCC);
    line(12, 32, w - 12, 32);
    
    fill(style.ACCENT);
    textSize(10);
    text("GAIT PATTERN:", 12, 40);
    
    fill(style.TEXT_MAIN);
    textSize(9);
    text(rec.title, 120, 40);
    
    // Recommended Shoes (compact)
    fill(style.TEXT_DIM);
    textSize(9);
    text("🥾 SHOES:", 12, 60);
    
    fill(style.TEXT_MAIN);
    textSize(8);
    if (rec.shoes.size() > 0) text("• " + rec.shoes.get(0), 15, 72);
    if (rec.shoes.size() > 1) text("• " + rec.shoes.get(1), 15, 82);
    
    // Recommended Exercises (compact)
    fill(style.TEXT_DIM);
    textSize(9);
    text("🏃 EXERCISES:", 350, 60);
    
    fill(style.TEXT_MAIN);
    textSize(8);
    if (rec.exercises.size() > 0) text("• " + rec.exercises.get(0), 353, 72);
    if (rec.exercises.size() > 1) text("• " + rec.exercises.get(1), 353, 82);
    
    // Tip/Warning
    fill(#FF9800);
    textSize(8);
    textAlign(LEFT, TOP);
    text("⚠️ TIP:", 12, h - 35);
    
    fill(style.TEXT_MAIN);
    String[] tipLines = wrapText(rec.tip, w - 30, 8);
    for (int i = 0; i < min(2, tipLines.length); i++) {
      text(tipLines[i], 35, h - 35 + 12 + i * 10);
    }
    
    popMatrix();
  }
  
  String[] wrapText(String text, float maxWidth, float textSize) {
    ArrayList<String> lines = new ArrayList<String>();
    String[] words = split(text, ' ');
    String currentLine = "";
    
    textSize(textSize);
    for (String word : words) {
      if (textWidth(currentLine + " " + word) < maxWidth) {
        currentLine += " " + word;
      } else {
        if (currentLine.length() > 0) {
          lines.add(currentLine.trim());
        }
        currentLine = word;
      }
    }
    if (currentLine.length() > 0) {
      lines.add(currentLine.trim());
    }
    
    String[] result = new String[lines.size()];
    return lines.toArray(result);
  }
}
