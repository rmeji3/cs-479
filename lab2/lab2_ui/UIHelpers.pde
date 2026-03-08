import processing.sound.*;

void drawHeader() {
  fill(50);
  textSize(36); 
  textAlign(LEFT);
  text(currentMode, 20, 50); 
  
  // Resting baseline calculation (persists)
  checkBaseline();
  
  // Start/Stop button for Fitness Mode (Top Right of content area)
  if (currentMode.equals("Fitness Mode")) {
    boolean btnHover = (mouseX-240 > 750 && mouseX-240 < 920 && mouseY > 20 && mouseY < 60);
    fill(isFitnessActive ? color(255, 100, 100) : color(100, 200, 100));
    if (btnHover) fill(isFitnessActive ? color(200, 50, 50) : color(50, 150, 50));
    
    noStroke();
    rect(750, 20, 170, 40, 10);
    
    fill(255);
    textSize(20);
    textAlign(CENTER);
    text(isFitnessActive ? "STOP" : "START", 835, 47);
    textAlign(LEFT);
  }
}

void checkBaseline() {
  if (!isRestingBaselineComplete) {
    long elapsed = (millis() - restingBaselineStartTime) / 1000;
    if (elapsed >= 30) {
      isRestingBaselineComplete = true;
      restingBPM = sensorData[2];
      restingResp = sensorData[3];
    }
  }
}

void drawOverview() {
  // Moved content UP to y=80 (from 110)
  drawStatItem(20, 80, "Current Heart Rate", sensorData[2], "bpm", color(255, 100, 100));
  
  // Resting HR Card
  drawStatItem(20, 200, "Resting Heart Rate", restingBPM, "bpm", color(255, 200, 0));
  
  if (!isRestingBaselineComplete) {
    long elapsed = (millis() - restingBaselineStartTime) / 1000;
    int timeLeft = max(0, 30 - int(elapsed)); 
    fill(255, 100, 100);
    textSize(16);
    textAlign(CENTER);
    text("CALCULATING: " + timeLeft + "s left", 220, 315);
    textAlign(LEFT);
  }
  drawStatItem(20, 320, "Respiratory Rate", sensorData[3], "br/m", color(100, 150, 255));
  
  fill(255);
  noStroke();
  rect(450, 80, 480, 295, 15);
  
  fill(50);
  textSize(22); 
  text("Zone Intensity Analysis", 480, 115);
  
  float maxHR = 220 - userAge; 
  float hrPercent = (sensorData[2] / maxHR) * 100;
  
  textSize(16);
  fill(120);
  text("Effort Intensity", 480, 145);
  
  textSize(64); 
  fill(30);
  String percText = int(hrPercent) + "%";
  text(percText, 480, 215);
  
  // Unit "intensity" label after the percentage
  textSize(18);
  fill(160);
  text(" ", 485 + textWidth(percText), 230);
  
  drawZoneBar(480, 260, 420, hrPercent);
}


void drawFitnessMode() {
  // Narrow profile box (350 wide) to fit wider trend graph
  fill(255);
  rect(20, 80, 340, 340, 15);
  
  float maxHR = 220 - userAge; 
  float intensity = (sensorData[2] / maxHR) * 100;

  String zone = "Very Light";
  color zoneColor = color(150);
  
  if (intensity > 90) { zone = "Maximum"; zoneColor = color(210, 45, 45); }
  else if (intensity > 80) { zone = "Hard"; zoneColor = color(240, 150, 50); }
  else if (intensity > 70) { zone = "Moderate"; zoneColor = color(75, 175, 75); }
  else if (intensity > 60) { zone = "Light"; zoneColor = color(60, 160, 220); }
  // Default is Very Light

  fill(80);
  textSize(20);
  text("Fitness Profile", 45, 130);
  
  textSize(48); // Smaller to fit 350 wide box
  fill(zoneColor);
  text(zone, 45, 210);
  
  fill(100);
  textSize(22);
  text("HR: " + int(sensorData[2]) + " bpm", 45, 250);
  text("Resp: " + int(sensorData[3]) + " br/m", 45, 295);
  
  textSize(28);
  text("Intensity: " + int(intensity) + "%", 45, 360);
  
  // Time indicator
  fill(150);
  textSize(13);
  if (isFitnessActive) {
    long elapsed = (millis() - fitnessSessionStartTime) / 1000;
    text("Active Session: " + elapsed + "s", 45, 410);
  } else {
    text("Status: PAUSED", 45, 410);
  }
}
boolean isMusicPlaying = false;
void playMusic() {
  if (!calmMusic.isPlaying()) {
    calmMusic.loop(); // loop() is usually better for relaxation tracks
  }
}

void stopMusic() {
  calmMusic.stop(); 
}

void drawStressMode() {
  // Narrow profile box on the left
  fill(255);
  rect(20, 80, 350, 340, 15);
  
  fill(50);
  textSize(22);
  text("Stress Analysis", 45, 130);
  
  if (!isRestingBaselineComplete) {
    textSize(18);
    text("Waiting for baseline...", 45, 200);
    if (calmMusic != null && calmMusic.isPlaying()) calmMusic.stop();
  } else {
    float bpmDiff = sensorData[2] - restingBPM;
    textSize(38);
    if (bpmDiff > 12) {
      fill(255, 50, 50);
      text("STRESSED", 45, 210);
        // Toggle LED and play music
        if (!lastStateStressed) {
          if (myPort != null) myPort.write('S');
          lastStateStressed = true;
        }
        if (calmMusic != null && !calmMusic.isPlaying()) {
          calmMusic.loop(); 
      }  
    } else {
      fill(75, 175, 75);
      text("CALM", 45, 210);
      
      // Toggle LED and stop music
      if (lastStateStressed) {
        if (myPort != null) myPort.write('N');
        lastStateStressed = false;
      }
      if (calmMusic != null && calmMusic.isPlaying()) {
        calmMusic.stop();
      }
    }
    
    fill(100);
    textSize(22);
    text("BPM Change: " + (bpmDiff >= 0 ? "+" : "") + int(bpmDiff), 45, 280);
    
    // Stress levels
    fill(150);
    textSize(14);
    text("Resting: " + int(restingBPM) + " bpm", 45, 310);
  }

  // Calmness Panel on the right
  fill(255);
  rect(400, 80, 540, 340, 15);
  fill(50);
  textSize(22);
  text("Relaxation Space", 430, 120);
  
  if (calmMusic != null && calmMusic.isPlaying()) {
    fill(100, 150, 255);
    textSize(16);
    text("Now Playing: Clair De Lune", 430, 150);
  } else {
    fill(150);
    textSize(16);
    text("System Silent - Relax", 430, 150);
  }
  
  // Calming Pacer (Slower than meditation: 4s inhale / 8s exhale)
  long cycleTime = 12000;
  long timeInCycle = millis() % cycleTime;
  float pacerSize = 0;
  String instruction = "";
  color pacerColor;
  
  if (timeInCycle < 4000) {
    instruction = "Inhale Deeply...";
    pacerColor = color(100, 200, 255);
    pacerSize = map(timeInCycle, 0, 4000, 100, 240);
  } else {
    instruction = "Exhale Slowly...";
    pacerColor = color(180, 230, 255);
    pacerSize = map(timeInCycle, 4000, 12000, 240, 100);
  }
  
  // Draw Pacer
  noStroke();
  fill(pacerColor, 30);
  ellipse(670, 280, pacerSize + 40, pacerSize + 40);
  fill(pacerColor, 150);
  ellipse(670, 280, pacerSize, pacerSize);
  
  // Instruction text centered in the pacer - scales with pacerSize
  fill(50);
  textAlign(CENTER);
  float instructionSize = map(pacerSize, 100, 240, 14, 28);
  textSize(instructionSize);
  text(instruction, 670, 280);
  textAlign(LEFT);
}

void drawMeditationMode() {
  // Narrow profile box on the left
  fill(255);
  rect(20, 80, 350, 340, 15);
  
  fill(50);
  textSize(22);
  text("Breath Stats", 45, 130);
  
  float inhale = sensorData[4] / 1000.0;
  float exhale = sensorData[5] / 1000.0;
  
  textSize(44);
  fill(50);
  text("Inhale: " + int(inhale) + "s", 45, 210);
  text("Exhale: " + int(exhale) + "s", 45, 280);
  
  if (exhale > 0 && inhale > 0) {
    float ratio = exhale / (inhale > 0 ? inhale : 1);
    textSize(28);
    fill(100);
    text("Ratio: 1 : " + int(ratio), 45, 340);
    
    textSize(22);
    if (ratio >= 2.8 && ratio <= 3.5) {
      fill(75, 175, 75);
      text("Perfect Pattern!", 45, 410);
    } else {
      fill(200, 100, 0);
      text("Goal: 1:3 Ratio", 45, 410);
    }
  }

  // Visual Breathing Guide Box
  fill(255);
  rect(400, 80, 540, 340, 15);
  fill(50);
  textSize(22);
  text("Visual Breathing Guide (1:3)", 430, 120);
  
  // Pulsing Orb Logic (8s cycle: 2s inhale, 6s exhale)
  long cycleTime = 8000;
  long timeInCycle = millis() % cycleTime;
  float orbSize = 0;
  String phase = "";
  color phaseColor;
  
  if (timeInCycle < 2000) {
    // Inhale Phase (Expansion)
    phase = "INHALE";
    phaseColor = color(100, 150, 255);
    orbSize = map(timeInCycle, 0, 2000, 80, 220);
  } else {
    // Exhale Phase (Contraction)
    phase = "EXHALE";
    phaseColor = color(75, 175, 75);
    orbSize = map(timeInCycle, 2000, 8000, 220, 80);
  }
  
  // Draw Orb
  noStroke();
  fill(phaseColor, 40);
  ellipse(670, 240, orbSize + 30, orbSize + 30); // Outer glow
  fill(phaseColor, 180);
  ellipse(670, 240, orbSize, orbSize);
  
  // Phase Text
  textAlign(CENTER);
  fill(phaseColor);
  textSize(32);
  text(phase, 670, 380);
  textAlign(LEFT);
}

void drawPSCMode() {

  // Update PSC states
  updatePSCMetrics();

  // ================= LEFT PANEL =================
  fill(255);
  noStroke();
  rect(20, 80, 420, 400, 15);

  fill(40);
  textSize(20);
  text("Physiological State", 40, 115);

  fill(pscColor);
  textSize(48);
  text(pscState, 40, 165);

  fill(80);
  textSize(14);
  text(pscDesc, 40, 190, 380, 60);

  fill(100);
  textSize(12);
  text("Confidence: " + int(confidence) + "%", 40, 260);

  stroke(220);
  line(40, 280, 400, 280);
  noStroke();

  fill(40);
  textSize(18);
  text("ANS Tone", 40, 310);

  fill(ansColor);
  textSize(36);
  text(ansState, 40, 350);

  // Z Score Bars
  drawPSCZScoreBar(40, 380, "HR", zHR, color(220, 70, 70));
  drawPSCZScoreBar(40, 400, "HRV", zHRV, color(70, 160, 220));
  drawPSCZScoreBar(40, 420, "RR", zRR, color(255, 140, 0));
  drawPSCZScoreBar(40, 440, "SpO2", zSpO2, color(0, 180, 120));

  // ================= RIGHT PANEL =================
  fill(255);
  rect(480, 80, 440, 400, 15);

  fill(40);
  textSize(20);
  text("Current Metrics", 500, 115);

  drawStatItem(500, 155, "Heart Rate", sensorData[2], "bpm", color(255, 100, 100));
  drawStatItem(500, 265, "HRV", sensorData[6], "ms", color(70, 160, 220));
  drawStatItem(500, 375, "Resp Rate", sensorData[3], "br/m", color(255, 140, 0));

  // Draw INFO button (top-right, inside translated canvas)
  drawPSCInfoButton();

  // Draw info overlay on top of everything if open
  if (pscHelpOpen) drawPSCInfoPanel();
}

// ===============================
// PSC CLASSIFICATION LOGIC
// ===============================
void updatePSCMetrics() {
  // Compute Z-scores from live sensor data
  computePSCZScores();

  // Classify PSC state
  classifyPSCState();

  // Classify ANS tone
  classifyANSTone();
}

void computePSCZScores() {
  // Using live sensor data
  zHR   = (sensorData[2] - 72) / 6;      // HR: mean=72, std=6
  zHRV  = (sensorData[6] - 50) / 8;      // HRV: mean=50, std=8
  zRR   = (sensorData[3] - 16) / 2;      // RR: mean=16, std=2
  zSpO2 = (sensorData[7] - 98) / 1.2;    // SpO2: mean=98, std=1.2
}

void classifyPSCState() {
  float stressScore = max(0, zHR) + max(0, -zHRV) + max(0, zRR);
  float recoveryScore = max(0, -zHR) + max(0, zHRV) + max(0, -zRR);
  float respScore = max(0, -zSpO2) + max(0, zRR);
  float hypoxicScore = max(0, zHR) + max(0, -zSpO2);
  float dysregScore = abs(zHRV) + abs(zRR);

  float maxScore = max(stressScore,
                  max(recoveryScore,
                  max(respScore,
                  max(hypoxicScore, dysregScore))));

  confidence = constrain(maxScore * 20, 0, 100);

  if (maxScore == stressScore && stressScore > 1.5) {
    pscState = "Acute Stress";
    pscDesc = "Elevated HR, reduced HRV and faster breathing.";
    pscColor = color(220, 70, 70);
  } else if (maxScore == recoveryScore && recoveryScore > 1.5) {
    pscState = "Recovery";
    pscDesc = "Lower HR, strong HRV and slow breathing.";
    pscColor = color(80, 180, 120);
  } else if (maxScore == respScore && respScore > 1.2) {
    pscState = "Respiratory Strain";
    pscDesc = "Oxygen drop with increased respiration.";
    pscColor = color(255, 140, 0);
  } else if (maxScore == hypoxicScore && hypoxicScore > 1.2) {
    pscState = "Hypoxic Stress";
    pscDesc = "Elevated HR with reduced oxygen saturation.";
    pscColor = color(200, 0, 0);
  } else if (maxScore == dysregScore && dysregScore > 2.5) {
    pscState = "Dysregulated";
    pscDesc = "Irregular HRV and respiration patterns.";
    pscColor = color(150, 60, 200);
  } else {
    pscState = "Stable";
    pscDesc = "Physiology within expected range.";
    pscColor = color(100, 200, 100);
    confidence = 40;
  }
}

void classifyANSTone() {
  if (zHRV > 1 && zRR < 0) {
    ansState = "Calm";
    ansColor = color(100, 200, 100);
  } else if (zHRV < -1 && zRR > 0) {
    ansState = "Aroused";
    ansColor = color(220, 80, 80);
  } else {
    ansState = "Balanced";
    ansColor = color(120, 150, 255);
  }
}

// ===============================
// UI HELPER FUNCTIONS
// ===============================
void drawPSCZScoreBar(float x, float y, String label, float z, color c) {

  float barWidth = 200;
  float centerX = x + 80;

  fill(120);
  textSize(12);
  text(label, x, y + 5);

  fill(230);
  rect(centerX, y, barWidth, 12, 4);

  float scaled = constrain(z * 25, -barWidth / 2, barWidth / 2);

  fill(c);

  if (scaled >= 0)
    rect(centerX + barWidth / 2, y, scaled, 12, 4);
  else
    rect(centerX + barWidth / 2 + scaled, y, -scaled, 12, 4);

  fill(150);
  rect(centerX + barWidth / 2, y, 1, 12);

  fill(60);
  textSize(11);
  text(nf(z, 1, 2), centerX + barWidth + 10, y + 10);
}

void drawPSCStat(float x, float y, String label, int val, String unit) {
  fill(100);
  textSize(16);
  text(label, x, y);
  fill(30);
  textSize(24);
  text(val + " " + unit, x + 80, y);
}

void drawStatItem(float x, float y, String label, float val, String unit, color c) {
  fill(255);
  noStroke();
  rect(x, y, 400, 95, 15); // Height reduced to 95 
  
  // Icon/Imagery Logic based on reference image
  String icon = "--";
  if (label.contains("Resting")) icon = "R";
  if (label.contains("Respiratory") || label.contains("Resp")) icon = "B";
  if (label.equals("HRV")) icon = "HRV";
  
  // Icon Circle on the Right (as seen in UI reference)
  fill(c, 40); 
  ellipse(x + 350, y + 47, 55, 55);
  fill(c);
  textAlign(CENTER, CENTER);
  
  if (label.contains("Heart Rate") && heartImg != null) {
    imageMode(CENTER);
    image(heartImg, x + 350, y + 47, 35, 35);
    imageMode(CORNER);
  } else {
    textSize(icon.equals("HRV") ? 18 : 28);
    text(icon, x + 350, y + 45);
  }
  
  // Adjusted Text Positions (Moved Up)
  textAlign(LEFT, TOP);
  fill(120);
  textSize(16); 
  text(label, x + 25, y + 18); // Moved up from y+45 
  
  // Value Position
  fill(30);
  textSize(42); 
  String valText = str(int(val));
  float valWidth = textWidth(valText);
  text(valText, x + 25, y + 38); 
  
  // Unit Position (Anchored exactly after the number)
  fill(160);
  textSize(18);
  // We add +5 for a tiny gap between number and unit
  text(unit, x + 25 + valWidth + 5, y + 54); 
  textAlign(LEFT);
}

void drawZoneBar(float x, float y, float w, float percent) {
  noStroke();
  for (int i=0; i<w; i++) {
    float p = i/(float)w;
    if (p < 0.6) fill(150);      // 0-60% Very Light (Grey)
    else if (p < 0.7) fill(60, 160, 220); // 60-70% Light (Blue)
    else if (p < 0.8) fill(75, 175, 75);  // 70-80% Moderate (Green)
    else if (p < 0.9) fill(240, 150, 50); // 80-90% Hard (Orange)
    else fill(210, 45, 45);               // 90-100% Max (Red)
    rect(x+i, y, 1, 20);
  }
  fill(0);
  float px = x + (w * constrain(percent/100, 0, 1));
  triangle(px, y-5, px-5, y-15, px+5, y-15);
}

void drawZScoreBar(float x, float y, String label, float z, color c) {
  float barMax = 160;
  float midX   = x + 50;

  fill(130);
  textSize(10);
  text(label, x, y + 8);

  fill(235);
  noStroke();
  rect(midX, y, barMax, 10, 3);

  float fillW = constrain(z * (barMax / 4.0), -barMax / 2.0, barMax / 2.0);
  fill(c, 200);
  if (fillW >= 0) rect(midX + barMax / 2.0, y, fillW, 10, 3);
  else            rect(midX + barMax / 2.0 + fillW, y, -fillW, 10, 3);

  fill(160);
  rect(midX + barMax / 2.0, y, 1, 10);

  fill(80);
  textSize(10);
  text((z >= 0 ? "+" : "") + nf(z, 1, 1), midX + barMax + 4, y + 8);
}

void drawCalibrateButton() {
  float bx = width - 180;
  // position the button above the resp graph so it stays visible when the graphs
  // are moved up for the Overview tab.  Use the current y of the respGraph if
  // available, otherwise fall back to the previous hardcoded value.
  float defaultBy = height - 326;
  float by = defaultBy;
  if (respGraph != null) {
    // place the button 60 pixels above the top of the respiration graph
    by = respGraph.y - 60;
  }
  float bw = 160;
  float bh = 38;
  
  boolean hover = (mouseX > bx && mouseX < bx + bw && mouseY > by && mouseY < by + bh);
  
  String buttonText = "CALIBRATE BREATH";
  
  // Display Message or Countdown
  if (isCalibratingResp) {
    int timeLeft = 10 - int((millis() - calibStartTime) / 1000);
    fill(255, 200, 200); // Progress color
    buttonText = "CALIBRATING: " + timeLeft + "s";
  } else if (millis() - calibStartTime < 13000 && calibStartTime > 0) { // Show for 3s after 10s calib
    fill(100, 200, 100);
    buttonText = "CALIBRATED!";
  } else {
    fill(hover ? 200 : 230);
  }
  
  noStroke();
  rect(bx, by, bw, bh, 8);
  
  fill(50);
  textSize(14);
  textAlign(CENTER);
  text(buttonText, bx + bw/2, by + 25);
  textAlign(LEFT);
}

/* 
void drawDevHRButtons() {
  float btnW = 30;
  float btnH = 30;
  float bx1 = width - 180;
  float defaultBy = height - 380;
  float by = defaultBy;
  if (respGraph != null) {
    by = respGraph.y - 100;
  }
  float bx2 = bx1 + btnW + 10;
  
  // Minus Button
  boolean hover1 = mouseX > bx1 && mouseX < bx1 + btnW && mouseY > by && mouseY < by + btnH;
  fill(hover1 ? 200 : 230);
  noStroke();
  rect(bx1, by, btnW, btnH, 5);
  fill(50);
  textSize(18);
  textAlign(CENTER, CENTER);
  text("-", bx1 + btnW/2, by + btnH/2 - 2);
  
  // Plus Button
  boolean hover2 = mouseX > bx2 && mouseX < bx2 + btnW && mouseY > by && mouseY < by + btnH;
  fill(hover2 ? 200 : 230);
  rect(bx2, by, btnW, btnH, 5);
  fill(50);
  text("+", bx2 + btnW/2, by + btnH/2 - 2);
  
  // Label
  textAlign(LEFT, BASELINE);
  textSize(12);
  fill(100);
  text("Dev HR", bx1, by - 5);
}
*/
// ─────────────────────────────────────────────
// PSC INFO BUTTON  (drawn inside translated canvas)
// ─────────────────────────────────────────────
void drawPSCInfoButton() {
  // Position in top-right of the content area (after translate(240,0))
  float bx = 900;   // right side of the 960px content area
  float by = 20;
  float bw = 55;
  float bh = 34;

  boolean hover = (mouseX - 240 > bx && mouseX - 240 < bx + bw &&
                   mouseY > by       && mouseY < by + bh);

  fill(pscHelpOpen ? color(40, 100, 200) : (hover ? color(60, 130, 230) : color(80, 150, 255)));
  noStroke();
  rect(bx, by, bw, bh, 8);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(13);
  text("? INFO", bx + bw / 2, by + bh / 2);
  textAlign(LEFT, BASELINE);
}

// ─────────────────────────────────────────────
// PSC INFO PANEL  (full-screen overlay)
// ─────────────────────────────────────────────
void drawPSCInfoPanel() {
  fill(0, 200);
  noStroke();
  rect(0, 0, width, height);

  float px = 50, py = 90;
  float pw = width - 480, ph = height - 120;
  fill(255);
  rect(px, py, pw, ph, 18);

  // Title bar
  fill(60, 130, 220);
  rect(px, py, pw, 52, 18, 18, 0, 0);
  
  // Close Button
  float closeX = px + pw - 40;
  float closeY = py + 11;
  float closeW = 30;
  float closeH = 30;
  boolean closeHover = (mouseX > closeX && mouseX < closeX + closeW && mouseY > closeY && mouseY < closeY + closeH);
  
  fill(closeHover ? color(255, 100, 100) : color(255, 255, 255, 40));
  noStroke();
  rect(closeX, closeY, closeW, closeH, 6);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(18);
  text("×", closeX + closeW/2, closeY + closeH/2 - 2); // Multiplication sign as X
  
  textAlign(LEFT, CENTER);
  textSize(21);
  text("  PSC Analysis — Quick Guide", px + 10, py + 26);

  float tx = px + 35;
  float ty = py + 70;
  float tw = pw - 70;

  // Intro
  fill(70);
  textSize(15);
  textLeading(22);
  textAlign(LEFT, TOP);
  text("Tracks HR, HRV, Breathing & SpO2 — compares them to your own session history to detect your current body state.", tx, ty, tw, 44);
  ty += 54;

  // Two columns
  float colW = (tw - 20) / 2;
  float col2x = tx + colW + 20;

  fill(40, 110, 200);
  textSize(16);
  text("BODY STATES", tx, ty);
  text("ANS TONE", col2x, ty);
  ty += 24;

  stroke(220);
  line(tx, ty, tx + tw, ty);
  noStroke();
  ty += 10;

  Object[][] states = {
    {"Stable",         color(75, 175, 75),   "All signals normal."},
    {"Acute Stress",   color(255, 50, 50),   "HR up, HRV down, fast breathing."},
    {"Recovery",       color(0, 200, 150),   "HR down, HRV up, slow breathing."},
    {"Resp. Strain",   color(100, 150, 255), "Breathing outside normal range."},
    {"Hypoxic Stress", color(255, 120, 0),   "Low oxygen, heart working harder."},
    {"Dysregulation",  color(200, 100, 255), "HRV & breathing both erratic."},
    {"Indeterminate",  color(150, 150, 150), "Mixed signals, keep monitoring."}
  };

  Object[][] ans = {
    {"Fight / Flight", color(255, 80, 80),   "Stressed — low HRV, fast HR."},
    {"Recovery Mode",  color(75, 200, 150),  "Calm — high HRV, slow HR."},
    {"Balanced",       color(100, 180, 255), "Healthy resting state."},
    {"Dysregulated",   color(200, 100, 255), "No clear dominant branch."}
  };

  float rowH = 32;
  int maxRows = max(states.length, ans.length);

  for (int i = 0; i < maxRows; i++) {
    float ry = ty + i * rowH;

    if (i < states.length) {
      fill((color) states[i][1]);
      ellipse(tx + 7, ry + 10, 14, 14);
      fill(30);
      textSize(15);
      text((String) states[i][0], tx + 22, ry + 2, 125, rowH);
      fill(100);
      textSize(14);
      text((String) states[i][2], tx + 155, ry + 2, colW - 155, rowH);
    }

    if (i < ans.length) {
      fill((color) ans[i][1]);
      ellipse(col2x + 7, ry + 10, 14, 14);
      fill(30);
      textSize(15);
      text((String) ans[i][0], col2x + 22, ry + 2, 125, rowH);
      fill(100);
      textSize(14);
      text((String) ans[i][2], col2x + 155, ry + 2, colW - 155, rowH);
    }
  }

  // Z-score footnote
  float footY = py + ph - 40;
  stroke(220); line(tx, footY, tx + tw, footY); noStroke();
  fill(150); textSize(13); textAlign(LEFT, TOP);
  text("Bars on the left = Z-scores: how far each reading is from YOUR normal. Right = higher, left = lower.", tx, footY + 8, tw, 26);

  // Close hint
  fill(160); textSize(12); textAlign(CENTER, BOTTOM);
  text("Click the × button or ? INFO again to close", px + pw / 2, py + ph - 10);
  textAlign(LEFT, BASELINE);
}
