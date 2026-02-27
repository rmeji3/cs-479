class RealTimeGraph {
  float x, y, w, h;
  float[] values;
  ArrayList<Float> sessionValues = new ArrayList<Float>(); // For Fitness session tracking
  String title;
  String statusLabel = "";
  color lineCol = #120B09;
  float yMin = 0, yMax = 1023;
  boolean showTimeTicks = false;
  boolean isHrGraph = false;
  boolean autoAdjustX = false; // New: To show the whole session
  float upperThresh = -1, lowerThresh = -1; // New: For visualizing triggers
  
  RealTimeGraph(float x, float y, float w, float h, String title, color lineCol) {
    this(x, y, w, h, title, lineCol, 0, 1023);
  }
  
  RealTimeGraph(float x, float y, float w, float h, String title, color lineCol, float yMin, float yMax) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.title = title;
    this.lineCol = lineCol;
    this.yMin = yMin;
    this.yMax = yMax;
    values = new float[int(w)];
    for(int i=0; i<values.length; i++) values[i] = yMin + (yMax-yMin)/2;
  }
  
  void setStatus(String s) {
    statusLabel = s;
  }

  void update(float val) {
    if (autoAdjustX) {
      // For session tracking, we add a value every ~1 second to keep it efficient
      if (frameCount % 60 == 0 || sessionValues.size() == 0) {
        sessionValues.add(val);
      }
    } else {
      for (int i = 0; i < values.length - 1; i++) {
        values[i] = values[i+1];
      }
      values[values.length - 1] = val;
    }
  }
  
  void resetSession() {
    sessionValues.clear();
  }
  
  void display() {
    fill(255);
    noStroke();
    rect(x, y, w, h, 12);
    
    fill(50);
    textSize(18);
    textAlign(LEFT);
    text(title, x + 10, y - 10);
  
    // --- NEW: Y-Axis Label ---
    pushMatrix();
    translate(x - 45, y + h/2);
    rotate(HALF_PI * 3); // Rotate 270 degrees
    textAlign(CENTER);
    fill(0); // Black text
    textSize(12);
    text(isHrGraph ? "Heart Rate (BPM)" : "Amplitude", 0, 15);
    popMatrix();
    
    // --- NEW: X-Axis Label ---
    textAlign(CENTER);
    text("Time (seconds)", x + w/2, y + h + 35);
  
    fill(120);
    textSize(1); 
    //text(title, x + 10, y - 10);
    
    if (!statusLabel.equals("")) {
      textAlign(RIGHT);
      fill(lineCol, 200);
      textSize(24);
      text(statusLabel, x + w - 15, y + 35);
      textAlign(LEFT);
    }
    
    fill(0);
    textSize(11);
    textAlign(RIGHT);
    
    // Draw 5 Y-ticks (4 intervals) for better precision
    for (int i=0; i<=4; i++) {
       float val = yMin + i * (yMax-yMin)/4.0;
       float vy = map(val, yMin, yMax, y+h-5, y+5);
       text(int(val), x - 8, vy + 4);
       
       // Subtle Grid Lines
       stroke(245);
       strokeWeight(1);
       line(x, vy, x+w, vy);
    }
    textAlign(LEFT);
    
    // Borders
    stroke(230);
    strokeWeight(1);
    line(x, y, x, y+h);
    line(x, y+h, x+w, y+h);
    
    // Threshold Markers
    if (upperThresh > 0) {
      stroke(255, 100, 100, 150); // Faint Red
      float ty = map(upperThresh, yMin, yMax, y+h-5, y+5);
      line(x, ty, x+w, ty);
    }
    if (lowerThresh > 0) {
      stroke(100, 150, 255, 150); // Faint Blue
      float ty = map(lowerThresh, yMin, yMax, y+h-5, y+5);
      line(x, ty, x+w, ty);
    }

    // Time Ticks (X-axis) - RESTORED
    if (showTimeTicks) {
      fill(150);
      textSize(11);
      textAlign(CENTER);
      // Vertical offset for the ticks (just below the bottom border)
      float tickY = y + h + 15; 
      // Vertical offset for the axis label (further below the ticks)
      float labelY = y + h + 35;
      if (autoAdjustX) {
        int totalSecs = sessionValues.size();
        int step = max(1, totalSecs / 5); 
        for (int i=0; i<sessionValues.size(); i += step) {
          float vx = map(i, 0, max(1, sessionValues.size()-1), x, x+w);
          text(i + "s", vx, tickY);
        }
      } else {
        for (int i=0; i<=w; i+=100) {
          float sec = i / 60.0;
          text(nf(sec, 0, 1) + "s", x + w - i, tickY);
        }
      }
      textSize(12);
      text("Time (seconds)", x + w/2, labelY);
    }
    textAlign(LEFT);
    
    strokeWeight(2.5);
    if (!autoAdjustX) {
      drawStandardWave();
    } else {
      drawSessionWave();
    }
  }

  void drawStandardWave() {
    noFill();
    stroke(lineCol);
    beginShape();
    for (int i = 0; i < values.length; i++) {
      float mappedY = map(values[i], yMin, yMax, y+h-5, y+5);
      vertex(x + i, constrain(mappedY, y+5, y+h-5));
    }
    endShape();
  }

  void drawSessionWave() {
    if (sessionValues.size() < 2) return;
    
    for (int i = 0; i < sessionValues.size() - 1; i++) {
        float x1 = map(i, 0, sessionValues.size()-1, x, x+w);
        float x2 = map(i+1, 0, sessionValues.size()-1, x, x+w);
        float y1 = map(sessionValues.get(i), yMin, yMax, y+h-5, y+5);
        float y2 = map(sessionValues.get(i+1), yMin, yMax, y+h-5, y+5);
        
        if (isHrGraph) {
          float intensity = (sessionValues.get(i) / (220 - userAge)) * 100;
          if (intensity >= 90) stroke(210, 45, 45);      // Red
          else if (intensity >= 80) stroke(240, 150, 50); // Orange
          else if (intensity >= 70) stroke(75, 175, 75);  // Green
          else if (intensity >= 60) stroke(60, 160, 220); // Blue
          else stroke(150);                               // Grey (Very Light)
        } else {
          stroke(lineCol);
        }
        line(x1, constrain(y1, y+5, y+h-5), x2, constrain(y2, y+5, y+h-5));
    }
  }
}
