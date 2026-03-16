// ============================================
// Simon Says - Main Sketch
// ============================================
// 5-row × 2-column grid layout:
//   5  0
//   6  1
//   7  2
//   8  3
//   9  4
// + Flex bar below + end game button (pad 10)
// ============================================

import processing.serial.*;
import ddf.minim.*;

// --- Components ---
PadGrid        padGrid;
FlexBar        flexBar;
GameEngine     game;
SoundManager   soundManager;
SerialHandler  serialHandler;

// --- State ---
boolean isConnected = false;
PFont fontTitle, fontBody, fontSmall;

void setup() {
  size(560, 860);
  smooth(8);
  surface.setTitle("Simon Says");

  fontTitle = createFont("Helvetica-Bold", 32);
  fontBody  = createFont("Helvetica-Bold", 18);
  fontSmall = createFont("Helvetica", 12);

  // Grid: 2 columns, 5 rows
  float padDiam = 100;
  float padGap  = 16;
  float gridW   = 2 * padDiam + padGap;
  float gridH   = 5 * padDiam + 4 * padGap;
  float gridX   = (width - gridW) / 2;
  float gridY   = 130;

  // Components
  soundManager  = new SoundManager(this);
  padGrid       = new PadGrid(gridX, gridY, padDiam, padGap);
  flexBar       = new FlexBar(gridX, gridY + gridH + 30, gridW, 42);
  game          = new GameEngine();
  serialHandler = new SerialHandler(this);

  serialHandler.connect();
}

void draw() {
  background(30, 30, 34);

  game.update();

  drawTitle();
  drawScorePanel();
  padGrid.draw();
  flexBar.draw();
  drawStatusMessage();
  drawConnectionDot();
}

// ============================================
// UI Drawing
// ============================================

void drawTitle() {
  textFont(fontTitle);
  fill(255, 255, 255, 200);
  textAlign(CENTER, TOP);
  text("SIMON SAYS", width / 2, 26);

  noStroke();
  fill(255, 255, 255, 18);
  rect(width / 2 - 110, 72, 220, 1);
}

void drawScorePanel() {
  float y = 82;
  textFont(fontBody);
  textAlign(CENTER, TOP);

  // Level and score side by side
  float leftX  = width / 2 - 80;
  float rightX = width / 2 + 80;

  fill(255, 255, 255, 70);
  textSize(12);
  text("LEVEL", leftX, y);
  text("SCORE", rightX, y);

  textSize(22);
  fill(255, 255, 255, 230);
  text(str(game.level), leftX, y + 16);
  fill(100, 220, 255, 230);
  text(str(game.score), rightX, y + 16);

  // High score
  fill(255, 255, 255, 45);
  textSize(11);
  text("HI " + game.highScore, width / 2, y + 16);
}

void drawStatusMessage() {
  float y = flexBar.y + flexBar.h + 30;

  String msg = game.getStatusText();
  color msgColor = game.getStatusColor();

  textFont(fontBody);
  float tw = textWidth(msg);

  noStroke();
  fill(24, 24, 28);
  rect(width / 2 - tw / 2 - 20, y - 6, tw + 40, 32, 16);

  float alpha = 230;
  if (game.state == GameEngine.SHOWING) {
    alpha = 150 + 80 * ((sin(millis() * 0.005) + 1) / 2);
  }
  if (game.state == GameEngine.FAIL) {
    alpha = 150 + 100 * ((sin(millis() * 0.008) + 1) / 2);
  }

  fill(red(msgColor), green(msgColor), blue(msgColor), alpha);
  textAlign(CENTER, TOP);
  text(msg, width / 2, y);

  if (game.level >= game.flexStartLevel && game.state != GameEngine.IDLE) {
    textFont(fontSmall);
    fill(255, 200, 80, 55);
    textAlign(CENTER, TOP);
    text("Flex sensor active!", width / 2, y + 34);
  }
}

void drawConnectionDot() {
  noStroke();
  fill(isConnected ? color(80, 255, 120) : color(255, 80, 80));
  ellipse(40, height - 18, 8, 8);

  textFont(fontSmall);
  fill(255, 255, 255, 80);
  textAlign(LEFT, CENTER);
  text(isConnected ? "Connected" : "Click pads to test", 52, height - 18);
}

// ============================================
// Mouse
// ============================================

void mousePressed() {
  if (game.state == GameEngine.FAIL) {
    game.restart();
    return;
  }

  for (int i = 0; i < 10; i++) {
    if (padGrid.pads[i].contains(mouseX, mouseY)) {
      padGrid.flashPad(i);
      game.playerInput(i);
      return;
    }
  }

  if (flexBar.contains(mouseX, mouseY)) {
    game.playerInput(10);
    return;
  }
}

// ============================================
// Serial
// ============================================

void serialEvent(Serial port) {
  serialHandler.handleEvent(port);
}

void stop() {
  try { soundManager.cleanup(); } catch (Exception e) {}
  super.stop();
}
