class RealTimeGraph {
  float x, y, w, h;
  int maxPoints = 200;
  ArrayList<FloatList> dataStreams;
  color[] colors = {Style.RED, Style.GREEN, Style.BLUE, Style.ACCENT, #FF00FF, #00FFFF};
  String[] streamLabels;
  String title;

  RealTimeGraph(float x, float y, float w, float h, int numStreams, String[] labels, String title) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.streamLabels = labels;
    this.title = title;
    dataStreams = new ArrayList<FloatList>();
    for (int i = 0; i < numStreams; i++) {
      dataStreams.add(new FloatList());
    }
  }

  void addData(float[] newVals) {
    for (int i = 0; i < dataStreams.size(); i++) {
        dataStreams.get(i).append(newVals[i]);
        if (dataStreams.get(i).size() > maxPoints) {
            dataStreams.get(i).remove(0);
        }
    }
  }

  void clear() {
    for (FloatList stream : dataStreams) {
      stream.clear();
    }
  }

  void display(Style style) {
    pushMatrix();
    translate(x, y);
    
    style.card(0, 0, w, h, title);
    
    float startX = 60;
    float startY = 80;
    float graphW = w - 100;
    float graphH = h - 100;

    // Draw grid
    stroke(45);
    line(startX, startY + graphH, startX + graphW, startY + graphH); // X axis
    line(startX, startY, startX, startY + graphH); // Y axis

    // Draw Y axis labels and ticks
    float floor, ceil;
    if (title.contains("FSR")) {
      floor = 0; 
      ceil = 1024;
    } else {
      floor = -20;
      ceil = 20; 
    }

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

    // X axis label
    textAlign(CENTER, TOP);
    text("TIME (SAMPLES)", startX + graphW/2, startY + graphH + 25);

    // Y axis title (centered vertically and rotated)
    pushMatrix();
    translate(15, startY + graphH/2);
    rotate(-HALF_PI);
    textAlign(CENTER, BOTTOM);
    text(title.contains("FSR") ? "PRESSURE" : "ACCEL (m/s²)", 0, 0);
    popMatrix();

    // Draw data lines
    for (int i = 0; i < dataStreams.size(); i++) {
      stroke(colors[i % colors.length]);
      strokeWeight(2);
      noFill();
      beginShape();
      FloatList stream = dataStreams.get(i);
      for (int j = 0; j < stream.size(); j++) {
        float vx = map(j, 0, maxPoints - 1, startX, startX + graphW);

        float vVal = constrain(stream.get(j), floor, ceil);
        float vy = map(vVal, floor, ceil, startY + graphH, startY); 
        vertex(vx, vy);
      }
      endShape();
      
      // Legend
      fill(colors[i % colors.length]);
      textSize(14); // Increased from 12
      textAlign(RIGHT, TOP);
      text(streamLabels[i], w - 20, 60 + i*20); // Adjusted spacing for bigger text
    }
    
    popMatrix();
  }
}
