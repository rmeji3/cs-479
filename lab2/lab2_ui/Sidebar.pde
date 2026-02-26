class Sidebar {
  float w = 220; // Slightly wider for larger text
  String[] items = {"Overview", "Stress Monitoring", "Fitness Mode", "Meditation Monitoring", "PSC Analysis"};
  
  void display() {
    noStroke();
    fill(sidebarColor);
    rect(0, 0, w, height);
    
    fill(20, 100, 20);
    textSize(34); // Larger Title
    text("Vitals", 25, 60);
    
    textSize(18); // Larger Menu Text
    for (int i = 0; i < items.length; i++) {
      float y = 140 + i * 70; // Increased spacing
      boolean isSelected = currentMode.equals(items[i]);
      boolean isHovered = (mouseX < w && mouseY > y-35 && mouseY < y+35);
      
      if (isSelected) {
        fill(255);
        rect(10, y-30, w-20, 60, 10);
        fill(10, 80, 10);
      } else if (isHovered) {
        fill(255, 150);
        rect(10, y-30, w-20, 60, 10);
        fill(50);
        if (mousePressed) {
          currentMode = items[i];
          // isRestingBaselineComplete remains same (persists between modes)
        }
      } else {
        fill(80);
      }
      text(items[i], 20, y+8);
    }
    
    // Bottom: Age Control
    stroke(20, 100, 20, 50);
    line(10, height-120, w-10, height-120);
    noStroke();
    
    float ageY = height - 80;
    fill(20, 100, 20);
    textSize(14);
    text("User Age", 25, ageY - 25);
    
    // Age Box
    boolean ageHover = (mouseX < w && mouseY > ageY-30 && mouseY < ageY+30);
    if (isAgeFocused) {
      stroke(20, 100, 20);
      strokeWeight(2);
      fill(255);
    } else if (ageHover) {
      noStroke();
      fill(255, 200);
    } else {
      noStroke();
      fill(255, 100);
    }
    rect(15, ageY - 20, w - 30, 40, 10);
    noStroke();
    
    fill(10, 80, 10);
    textSize(22);
    textAlign(CENTER);
    String ageDisplay = isAgeFocused ? ageBuffer + "|" : str(userAge) + " yrs";
    text(ageDisplay, w/2, ageY + 8);
    textAlign(LEFT);
  }
}
