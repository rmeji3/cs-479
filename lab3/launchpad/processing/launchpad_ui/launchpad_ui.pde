// ============================================
// Launchpad Controller UI - Main Sketch
// ============================================

import processing.serial.*;
import ddf.minim.*;

// --- Components ---
SerialHandler  serialHandler;
PadGrid        padGrid;
SoundManager   soundManager;
LoopRecorder   loopRecorder;

// --- Mixer ---
Slider volSlider;
Slider speedSlider;

// VU
float vuLevel = 0;
float prevVUDisplay = 0;

boolean isConnected = false;
PFont fontMain, fontSmall;

void setup() {
  size(1080, 640);
  smooth(8);
  surface.setTitle("Launchpad Controller");

  fontMain  = createFont("Helvetica-Bold", 28);
  fontSmall = createFont("Helvetica", 12);

  soundManager  = new SoundManager(this);
  padGrid       = new PadGrid(50, 115, 130, 16);
  loopRecorder  = new LoopRecorder();

  volSlider   = new Slider(840, 145, 52, 230, "VOL",   true, 65);
  speedSlider = new Slider(930, 145, 52, 230, "SPEED", true, 50);
  volSlider.setSolidColor(color(80, 140, 255));
  speedSlider.setSolidColor(color(180, 80, 255));

  soundManager.setVolume(volSlider.value);

  serialHandler = new SerialHandler(this);
  serialHandler.connect();
}

void draw() {
  background(34, 34, 38);

  soundManager.setVolume(volSlider.value);
  soundManager.speedMultiplier = map(speedSlider.value, 0, 100, 1.0, 0.15);

  vuLevel *= 0.88;

  float db = map(volSlider.value, 0, 100, -14, 4);
  volSlider.setSubtitle((db >= 0 ? "+" : "") + nf(db, 1, 1) + " dB", color(120, 160, 255));
  speedSlider.setSubtitle(nf(soundManager.speedMultiplier, 1, 1) + "x", color(180, 160, 255));

  drawTitle();
  drawVUMeter();
  drawPadBorder();
  padGrid.draw();
  drawMixerPanel();
  volSlider.draw();
  speedSlider.draw();
  drawRecSection();
  drawStatus();

  soundManager.updateHeldPads();
  loopRecorder.update();
}

void drawTitle() {
  textFont(fontMain);
  fill(255, 255, 255, 200);
  textAlign(LEFT, TOP);
  text("LAUNCHPAD", 50, 24);

  noStroke();
  fill(255, 255, 255, 20);
  rect(50, 64, 260, 1);
}

void drawVUMeter() {
  float vuX = 50;
  float vuY = 82;
  float vuW = 5 * 130 + 4 * 16;
  float vuH = 12;
  int vuSegs = 40;

  fill(255, 255, 255, 55);
  textSize(9);
  textAlign(RIGHT, CENTER);
  text("VU", vuX - 8, vuY + vuH / 2);

  noStroke();
  fill(22, 22, 34);
  rect(vuX, vuY, vuW, vuH, 4);

  float smooth = lerp(prevVUDisplay, vuLevel, 0.25);
  prevVUDisplay = smooth;

  float segW = (vuW - 6) / vuSegs;
  for (int i = 0; i < vuSegs; i++) {
    float sx  = vuX + 3 + i * segW;
    float pct = (float)(i + 1) / vuSegs * 100;
    boolean lit = smooth >= (pct - 100.0 / vuSegs);

    float t = (float) i / vuSegs;
    color segColor;
    if (t < 0.6) {
      segColor = lerpColor(color(50, 210, 90), color(255, 220, 50), t / 0.6);
    } else {
      segColor = lerpColor(color(255, 220, 50), color(255, 55, 55), (t - 0.6) / 0.4);
    }

    fill(lit ? segColor : color(red(segColor) * 0.05, green(segColor) * 0.05, blue(segColor) * 0.05));
    noStroke();
    rect(sx + 1, vuY + 2.5, segW - 2, vuH - 5, 1.5);
  }
}

void drawPadBorder() {
  noFill();
  stroke(48, 48, 52);
  strokeWeight(1);
  rect(35, 100, 5 * 130 + 4 * 16 + 30, 2 * 130 + 1 * 16 + 40, 12);
}

void drawMixerPanel() {
  noFill();
  stroke(48, 48, 52);
  strokeWeight(1);
  rect(820, 100, 200, 2 * 130 + 1 * 16 + 40, 12);

  textFont(fontSmall);
  fill(255, 255, 255, 80);
  textAlign(CENTER, TOP);
  text("M I X E R", 920, 107);

  noStroke();
  fill(255, 255, 255, 12);
  rect(835, 122, 170, 1);
}

void drawRecSection() {
  // Pad grid ends around y=400
  float recY = 420;

  // Status text
  textFont(fontSmall);
  fill(loopRecorder.getStatusColor());
  textAlign(LEFT, TOP);
  String statusText = loopRecorder.getStatusText();
  if (loopRecorder.state == LoopRecorder.RECORDING) {
    boolean blink = (millis() / 350) % 2 == 0;
    if (!blink) statusText = statusText.replace("●", "○");
  }
  text(statusText, 55, recY);

  // 2x5 loop bank grid
  loopRecorder.drawBank(50, recY + 22);
}

void drawStatus() {
  noStroke();
  fill(isConnected ? color(80, 255, 120) : color(255, 80, 80));
  ellipse(65, height - 18, 8, 8);

  textFont(fontSmall);
  fill(255, 255, 255, 100);
  textAlign(LEFT, CENTER);
  text(isConnected ? "Connected" : "No hardware — click pads to test", 78, height - 18);
}

// --- Mouse ---

void mousePressed() {
  if (volSlider.handleMousePressed(mouseX, mouseY)) return;
  if (speedSlider.handleMousePressed(mouseX, mouseY)) return;
  if (loopRecorder.handleClick(mouseX, mouseY)) return;
  for (int i = 0; i < 10; i++) {
    if (padGrid.pads[i].contains(mouseX, mouseY)) {
      padGrid.setPadState(i, true);
      soundManager.play(i);
      loopRecorder.recordPad(i);
    }
  }
}

void mouseDragged() {
  volSlider.handleMouseDragged(mouseX, mouseY);
  speedSlider.handleMouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  volSlider.handleMouseReleased();
  speedSlider.handleMouseReleased();
  for (int i = 0; i < 10; i++) {
    if (padGrid.pads[i].contains(mouseX, mouseY)) {
      padGrid.setPadState(i, false);
    }
  }
}

void serialEvent(Serial port) {
  serialHandler.handleEvent(port);
}

void stop() {
  soundManager.cleanup();
  super.stop();
}
