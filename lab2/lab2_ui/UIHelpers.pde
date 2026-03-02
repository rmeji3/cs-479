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
    
    if (btnHover && mousePressed && frameCount % 15 == 0) {
      isFitnessActive = !isFitnessActive;
      if (isFitnessActive) {
        fitnessSessionStartTime = millis();
        fitnessHrGraph.resetSession();
      }
    }
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
  } else {
    // Recalculate Button - Positioned in the Resting HR Box (starting at y=215)
    boolean btnHover = (mouseX-240 > 240 && mouseX-240 < 390 && mouseY > 225 && mouseY < 255);
    fill(btnHover ? 230 : 255, 150);
    stroke(200);
    rect(240, 170, 150, 25, 5);
    fill(80);
    textSize(11);
    textAlign(CENTER);
    text("RECALCULATE", 315, 190);
    textAlign(LEFT);
    if (btnHover && mousePressed) {
       isRestingBaselineComplete = false;
       restingBaselineStartTime = millis();
    }
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
  rect(20, 80, 350, 390, 15);
  
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
  rect(20, 80, 350, 390, 15);
  
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
        // PLAY MUSIC IF STRESSED
        if (calmMusic != null && !calmMusic.isPlaying()) {
          calmMusic.loop(); 
      }  
    } else {
      fill(75, 175, 75);
      text("CALM", 45, 210);
      
      // STOP MUSIC IF CALM
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
  rect(400, 80, 540, 390, 15);
  fill(50);
  textSize(22);
  text("Relaxation Space", 430, 120);
  
  if (calmMusic != null && calmMusic.isPlaying()) {
    fill(100, 150, 255);
    textSize(16);
    text("\u266B Now Playing: Clair De Lune", 430, 150);
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
  
  fill(50);
  textAlign(CENTER);
  textSize(24);
  text(instruction, 670, 440);
  textAlign(LEFT);
}

void drawMeditationMode() {
  // Narrow profile box on the left
  fill(255);
  rect(20, 80, 350, 390, 15);
  
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
  rect(400, 80, 540, 390, 15);
  fill(50);
  textSize(22);
  text("Visual Breathing Guide (1:3)", 430, 130);
  
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
  ellipse(670, 280, orbSize + 30, orbSize + 30); // Outer glow
  fill(phaseColor, 180);
  ellipse(670, 280, orbSize, orbSize);
  
  // Phase Text
  textAlign(CENTER);
  fill(phaseColor);
  textSize(32);
  text(phase, 670, 440);
  textAlign(LEFT);
}

void drawPSCMode() {
  // ── LEFT PANEL: Core Vitals + z-scores + features ────────────────────────
  fill(255);
  noStroke();
  rect(20, 80, 350, 390, 15);

  fill(50);
  textSize(20);
  text("Core Vitals", 45, 118);

  drawPSCStat(45, 155, "HR",   int(sensorData[2]), "bpm");
  drawPSCStat(45, 205, "HRV",  int(sensorData[6]), "ms");
  drawPSCStat(45, 255, "SpO2", int(sensorData[7]), "%");
  drawPSCStat(45, 305, "Resp", int(sensorData[3]), "br/m");

  float readiness = pscDataReadiness();
  if (readiness >= 1.0) {
    fill(120);
    textSize(11);
    text("Session z-scores", 45, 337);
    drawZScoreBar(45, 345, "HR",   zHR,   color(255, 100, 100));
    drawZScoreBar(45, 365, "HRV",  zHRV,  color(100, 200, 150));
    drawZScoreBar(45, 385, "SpO2", zSpO2, color(100, 150, 255));
    drawZScoreBar(45, 405, "RR",   zRR,   color(255, 200, 50));
    
    fill(120);
    textSize(11);
    String slopeLabel = (featHRSlope > 0.05) ? "HR trending UP" : (featHRSlope < -0.05) ? "HR trending DOWN" : "HR stable";
    text(slopeLabel, 45, 450);
  } else {
    fill(200);
    textSize(13);
    text("Collecting baseline: " + int(readiness * 100) + "%", 45, 350);
    noStroke();
    fill(220);
    rect(45, 360, 280, 10, 5);
    fill(100, 200, 150);
    rect(45, 360, 280 * readiness, 10, 5);
  }

  // ── RIGHT PANEL: PSC State + ANS State ────────────────────────────────────
  fill(255);
  noStroke();
  rect(400, 80, 540, 390, 15);

  // ─ PSC Header + Help Button ────────────────────────────────────────────────
  fill(50);
  textSize(18);
  text("Physiological State (PSC)", 425, 118);

  boolean helpHover = (mouseX - 240 > 660 && mouseX - 240 < 760 && mouseY > 22 && mouseY < 52);
  noStroke();
  fill(pscHelpOpen ? color(80, 140, 220) : (helpHover ? color(200) : color(230)));
  rect(660, 22, 100, 30, 8);
  fill(pscHelpOpen ? 255 : 60);
  textSize(13);
  textAlign(CENTER);
  text(pscHelpOpen ? "✕ Close" : "? Help", 710, 42);
  textAlign(LEFT);

  // PSC State box
  noStroke();
  fill(pscColor, 25);
  rect(420, 130, 500, 90, 12);
  fill(pscColor);
  textSize(32);
  text(pscState, 435, 185);

  fill(80);
  textSize(14);
  textLeading(20);
  text(pscDesc, 420, 240, 500, 70);
  textLeading(12);

  stroke(230);
  line(420, 318, 920, 318);
  noStroke();

  fill(50);
  textSize(18);
  text("ANS State Classifier", 425, 345);

  fill(ansColor, 25);
  rect(420, 355, 500, 72, 12);
  fill(ansColor);
  textSize(26);
  text(ansState, 435, 390);

  fill(80);
  textSize(13);
  text(ansDesc, 435, 415);

  stroke(230);
  line(420, 448, 920, 448);
  noStroke();
  fill(pscColor);
  float barW = map(sensorData[6], 10, 100, 20, 498);
  rect(420, 450, constrain(barW, 20, 498), 5, 2);
  fill(140);
  textSize(11);
  text("Autonomic Recovery Strength  (HRV: " + int(sensorData[6]) + " ms)", 420, 470);

  // ── Help Dropdown Overlay (drawn last so it sits on top) ──────────────────
  if (pscHelpOpen) drawPSCHelpOverlay();
}

void drawPSCHelpOverlay() {
  noStroke();
  
  fill(255, 252);
  rect(20, 80, 920, 435, 15);
  
  fill(80, 140, 220);
  rect(20, 80, 920, 6, 15);
  
  fill(30);
  textSize(20);
  textAlign(LEFT);
  text("How to read this screen — plain and simple", 45, 120);
  
  // ── SECTION 1 ──────────────────────────────────────────────────────────────
  fill(80, 140, 220);
  rect(45, 135, 4, 85);
  fill(30);
  textSize(14);
  text("The two outputs", 58, 153);
  fill(90);
  textSize(12);
  textLeading(18);
  text("PHYSIOLOGICAL STATE tells you what your body is doing right now.", 58, 172);
  text("ANS STATE tells you which part of your nervous system is in charge.", 58, 190);
  text("Both update live — just watch them change.", 58, 208);
  textLeading(12);

  // ── SECTION 2: PSC state table ─────────────────────────────────────────────
  fill(30);
  textSize(14);
  text("What each state means", 45, 238);
  
  String[][] rows = {
    {"Rested Stable",           "🟢", "Everything is calm. Your body is happy."},
    {"Recovery",                "🔵", "Coming down from activity. Body is healing."},
    {"Acute Stress",            "🔴", "Heart rate up, breathing fast. You're stressed."},
    {"Respiratory Strain",      "🟡", "Breathing is too fast or too slow. Focus on slowing it down."},
    {"Hypoxic Stress",          "🟠", "Oxygen level dropping. Breathe slower and deeper."},
    {"Dysregulated State",      "🔴", "Oxygen low AND heart racing — most severe. Rest immediately."},
    {"Autonomic Imbalance",     "🟣", "Low HRV at rest — possible fatigue or overtraining."},
    {"Autonomic Dysregulation", "🟣", "Signals are erratic — nervous system is unstable."},
  };
  
  float rowY = 255;
  for (int i = 0; i < rows.length; i++) {
    if (i % 2 == 0) {
      fill(245);
      noStroke();
      rect(45, rowY - 13, 880, 20, 4);
    }
    fill(30);
    textSize(12);
    text(rows[i][0], 55, rowY);
    text(rows[i][1], 240, rowY);
    fill(80);
    text(rows[i][2], 265, rowY);
    rowY += 22;
  }

  // ── SECTION 3: ANS modes ────────────────────────────────────────────────────
  float col2X = 490;
  fill(80, 140, 220);
  rect(col2X, 135, 4, 85);
  fill(30);
  textSize(14);
  text("ANS modes — which side is winning?", col2X + 13, 153);
  fill(90);
  textSize(12);
  textLeading(18);
  text("Your nervous system has two modes that compete:", col2X + 13, 172);
  text("STRESS mode (sympathetic) vs REST mode (parasympathetic).", col2X + 13, 190);
  text("The ANS box tells you which one is currently dominant.", col2X + 13, 208);
  textLeading(12);

  String[][] ansModes = {
    {"Fight / Flight", "🔴", "Stress mode is on. Heart up, breathing up."},
    {"Recovery Mode",  "🟢", "Rest mode is on. Heart calm, breathing slow."},
    {"Balanced Mode",  "🔵", "Neither side is dominant. You're neutral."},
    {"Dysregulated",   "🟣", "Can't tell — signals are too chaotic."},
  };
  
  rowY = 255;
  for (int i = 0; i < ansModes.length; i++) {
    if (i % 2 == 0) {
      fill(245);
      noStroke();
      rect(col2X + 10, rowY - 13, 415, 20, 4);
    }
    fill(30);
    textSize(12);
    text(ansModes[i][0], col2X + 20, rowY);
    text(ansModes[i][1], col2X + 155, rowY);
    fill(80);
    text(ansModes[i][2], col2X + 180, rowY);
    rowY += 22;
  }

  // ── SECTION 4: The bars ─────────────────────────────────────────────────────
  fill(30);
  textSize(13);
  text("The small bars on the left (HR / HRV / SpO2 / RR)", 45, 447);
  fill(90);
  textSize(12);
  text("Each bar shows if that signal is higher or lower than YOUR average for this session.", 45, 463);
  text("Bar goes right = rising above your normal.   Bar goes left = dropping below your normal.", 45, 479);
  text("The app learns your baseline as you use it — comparisons are personal to you, not a population average.", 45, 495);

  fill(140);
  textSize(11);
  textAlign(RIGHT);
  text("Click  ? Help  again or click outside to close", 930, 508);
  textAlign(LEFT);
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
  String icon = "️";
  if (label.contains("Resting")) icon = " ";
  if (label.contains("Respiratory") || label.contains("Resp")) icon = " ";
  
  // Icon Circle on the Right (as seen in UI reference)
  fill(c, 40); 
  ellipse(x + 350, y + 47, 55, 55);
  fill(c);
  textSize(28);
  textAlign(CENTER, CENTER);
  text(icon, x + 350, y + 45);
  
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
  float by = height - 326;
  float bw = 160;
  float bh = 38;
  
  boolean hover = (mouseX > bx && mouseX < bx + bw && mouseY > by && mouseY < by + bh);
  
  // Display Message or Countdown
  if (isCalibratingResp) {
    int timeLeft = 10 - int((millis() - calibStartTime) / 1000);
    fill(255, 100, 100);
    textSize(14);
    textAlign(RIGHT);
    text("CALIBRATING: " + timeLeft + "s", width - 20, height - 70);
    textAlign(LEFT);
    fill(255, 200, 200); // Progress color
  } else if (millis() - calibStartTime < 13000 && calibStartTime > 0) { // Show for 3s after 10s calib
    fill(75, 175, 75);
    textSize(14);
    textAlign(RIGHT);
    text("BREATHING CALIBRATED!", width - 20, height - 70);
    textAlign(LEFT);
    fill(100, 200, 100);
  } else {
    fill(hover ? 200 : 230);
  }
  
  noStroke();
  rect(bx, by, bw, bh, 8);
  
  fill(50);
  textSize(14);
  textAlign(CENTER);
  text(isCalibratingResp ? "CALIBRATING..." : "CALIBRATE BREATH", bx + bw/2, by + 25);
  textAlign(LEFT);
}
