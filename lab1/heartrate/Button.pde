class Button {
  int x, y, w, h;
  String label;

  Button(int x, int y, int w, int h, String label) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
  }

  void draw(boolean enabled) {
    boolean hover = isInside(mouseX, mouseY);

    if (!enabled) fill(210);
    else if (hover) fill(235);
    else fill(245);

    stroke(180);
    rect(x, y, w, h, 8);

    fill(20);
    noStroke();
    textAlign(CENTER, CENTER);
    textSize(12);
    text(label, x + w/2, y + h/2);
  }

  boolean isClicked(int mx, int my) {
    return isInside(mx, my);
  }

  boolean isInside(int mx, int my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
}
