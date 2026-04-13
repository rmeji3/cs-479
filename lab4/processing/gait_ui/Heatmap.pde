class Heatmap {
  float x, y, w, h;
  float[] values = new float[4]; // MF, LF, MM, HEEL
  String[] labels = {"MF", "LF", "MM", "HEEL"};
  PVector[] positions;
  PImage footImg;

  Heatmap(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    
    // Load the user-provided foot image (converted to png)
    footImg = loadImage("foot.png");
    
    // Relative positions calibrated for a RIGHT foot image
    positions = new PVector[4];
    positions[0] = new PVector(w * 0.35, h * 0.27); // MF (Medial Forefoot) - top right for right foot
    positions[1] = new PVector(w * 0.58, h * 0.45); // LF (Lateral Forefoot) - mid right for right foot
    positions[2] = new PVector(w * 0.39, h * 0.45); // MM (Medial Mid-foot) - mid left for right foot
    positions[3] = new PVector(w * 0.52, h * 0.86); // HEEL - bottom center
  }

  void update(float mf, float lf, float heel, float mm) {
    // Arduino order: MF, LF, HEEL, MM
    values[0] = mf; 
    values[1] = lf;
    values[2] = mm; 
    values[3] = heel;
  }

  void display(Style style) {
    pushMatrix();
    translate(x, y);
    
    style.card(0, 0, w, h, "PRESSURE DISTRIBUTION");
    
    // Draw Foot Image
    if (footImg != null) {
      pushMatrix();
      translate(w/2, h/2 + 20);
      // Flip horizontally for right foot
      scale(-1, 1);
      imageMode(CENTER);
      tint(100); // Dim the image slightly
      image(footImg, 0, 0, w * 0.8, h * 0.82);
      noTint();
      popMatrix();
    }
    
    // Draw Heatmap Overlay
    for (int i = 0; i < 4; i++) {
      // Adjusted mapping: Lowered threshold significantly to 700 to increase sensitivity
      // Guard against NaN sensor values which cause map() to return NaN
      float raw = values[i];
      if (Float.isNaN(raw)) raw = 0;
      float intensity = map(raw, 600, 1023, 0, 1);
      intensity = constrain(intensity, 0, 1);
      
      // Color gradient from Blue (cold) to Red (hot)
      color c;
      if (intensity < 0.5) {
        c = lerpColor(color(0, 100, 255, 150), color(255, 255, 0, 180), intensity * 2);
      } else {
        c = lerpColor(color(255, 255, 0, 180), color(255, 0, 0, 200), (intensity - 0.5) * 2);
      }
      
      float size = 40 + intensity * 60;
      
      // Outer glow
      fill(c, 100);
      noStroke();
      ellipse(positions[i].x, positions[i].y, size * 1.5, size * 1.5);
      
      // Inner circle
      fill(c);
      ellipse(positions[i].x, positions[i].y, size, size);
      
      fill(255);
      textSize(12);
      textAlign(CENTER, CENTER);
      text(labels[i], positions[i].x, positions[i].y);
    }
    
    popMatrix();
  }
}
