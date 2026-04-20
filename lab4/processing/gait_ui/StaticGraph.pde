class StaticGraph {
  float x, y, w, h;
  ArrayList<float[]> data;
  String[] streamLabels;
  color[] colors = {Style.RED, Style.GREEN, Style.BLUE, Style.ACCENT};
  String title;
  int selectedIndex = -1;

  StaticGraph(float x, float y, float w, float h, String[] labels, String title) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.streamLabels = labels;
    this.title = title;
  }

  void setData(ArrayList<float[]> recorded) {
    this.data = recorded;
    selectedIndex = -1;
  }

  void display(Style style) {
    pushMatrix();
    translate(x, y);
    
    style.card(0, 0, w, h, title);
    
    if (data == null || data.size() < 2) {
      fill(Style.TEXT_DIM);
      textAlign(CENTER, CENTER);
      text("NO RECORDED DATA", w/2, h/2);
      popMatrix();
      return;
    }

    int nStreams = streamLabels.length;
    float startX = 60;
    float startY = 80;
    float graphW = w - 100;
    float graphH = h - 110;

    // Draw grid & axis
    stroke(45);
    strokeWeight(1);
    line(startX, startY + graphH, startX + graphW, startY + graphH); // X axis
    line(startX, startY, startX, startY + graphH); // Y axis

    // Scale Logic
    float floor = 0, ceil = 1024;
    if (title.contains("ACCELEROMETER")) {
      floor = -20;
      ceil = 20;

      // Draw 0 line for accel
      stroke(30);
      float zeroY = map(0, floor, ceil, startY + graphH, startY);
      line(startX, zeroY, startX + graphW, zeroY);
    }

    // Draw Y axis labels and ticks
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(RIGHT, CENTER);
    for (int i = 0; i <= 4; i++) {
      float val = lerp(floor, ceil, i / 4.0);
      float ty = map(val, floor, ceil, startY + graphH, startY);
      text((int)val, startX - 10, ty);
      stroke(45);
      line(startX - 5, ty, startX, ty);
    }

    // Stream indices: FSR uses 0-3, Accel uses 4-6 in recordedData
    int streamOffset = title.contains("ACCELEROMETER") ? 4 : 0;

    // Draw lines
    for (int i = 0; i < nStreams; i++) {
      stroke(colors[i % colors.length]);
      strokeWeight(2);
      noFill();
      beginShape();
      for (int j = 0; j < data.size(); j++) {
        float vx = map(j, 0, data.size() - 1, startX, startX + graphW);
        float val = data.get(j)[i + streamOffset];
        float vy = map(val, floor, ceil, startY + graphH, startY);
        vertex(vx, vy);
      }
      endShape();
    }

    // Legend
    for (int i = 0; i < nStreams; i++) {
        fill(colors[i % colors.length]);
        textSize(14); // Increased from 11
        textAlign(RIGHT, TOP);
        text(streamLabels[i], w - 20, 60 + i*20); // Adjusted spacing
    }

    // Time ticks on X axis
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(CENTER);
    for (int i = 0; i <= 5; i++) {
      float tx = map(i, 0, 5, startX, startX + graphW);
      int frameIdx = (int)map(i, 0, 5, 0, data.size()-1);
      float seconds = frameIdx / 50.0; // Assuming 50Hz
      text(nf(seconds, 0, 1) + "s", tx, startY + graphH + 20);
      stroke(40);
      line(tx, startY + graphH, tx, startY + graphH + 5);
    }
    textAlign(CENTER, TOP);
    text("TIME (SECONDS)", startX + graphW/2, startY + graphH + 35);

    // Interaction Line
    // Accurate mapping subtraction calculation:
    // mouseX is global. 100 is translation for dashboard. x is graph start within dashboard. startX is internal graph margin.
    float absoluteGraphStartX = 97 + x + startX;

    // Y axis title (centered vertically and rotated)
    pushMatrix();
    translate(15, startY + graphH/2);
    rotate(-HALF_PI);
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(CENTER, BOTTOM);
    text(title.contains("ACCELEROMETER") ? "ACCEL (m/s²)" : "PRESSURE", 0, 0);
    popMatrix();

    if (mouseX > absoluteGraphStartX && mouseX < absoluteGraphStartX + graphW && 
        mouseY > y + startY && mouseY < y + startY + graphH) {
      
      float relMouseX = mouseX - absoluteGraphStartX;
      int idx = (int)map(relMouseX, 0, graphW, 0, data.size() - 1);
      idx = constrain(idx, 0, data.size() - 1);
      
      if (title.contains("FSR")) {
        float lx = map(idx, 0, data.size() - 1, startX, startX + graphW);
        stroke(Style.TEXT_DIM, 120);
        strokeWeight(1);
        line(lx, startY, lx, startY + graphH);
      }
      
      if (mousePressed) {
        selectedIndex = idx;
      }
    }

    if (selectedIndex != -1 && title.contains("FSR")) {
      float sx = map(selectedIndex, 0, data.size() - 1, startX, startX + graphW);
      stroke(Style.ACCENT);
      strokeWeight(2);
      line(sx, startY, sx, startY + graphH);
      fill(Style.ACCENT);
      noStroke();
      ellipse(sx, startY + graphH, 8, 8);
    }

    popMatrix();
  }
}
