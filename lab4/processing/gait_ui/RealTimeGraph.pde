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

  void display(Style style) {
    pushMatrix();
    translate(x, y);
    
    style.card(0, 0, w, h, title);
    
    // Draw data lines
    for (int i = 0; i < dataStreams.size(); i++) {
      stroke(colors[i % colors.length]);
      strokeWeight(1.5);
      noFill();
      beginShape();
      FloatList stream = dataStreams.get(i);
      for (int j = 0; j < stream.size(); j++) {
        float vx = map(j, 0, maxPoints, 20, w - 20);
        float vy = map(stream.get(j), 0, 1023, h - 20, 50); // Adjusted range for card padding
        vertex(vx, vy);
      }
      endShape();
      
      // Legend
      fill(colors[i % colors.length]);
      textSize(12);
      textAlign(RIGHT, TOP);
      text(streamLabels[i], w - 20, 15 + i*15);
    }
    
    popMatrix();
  }
}
