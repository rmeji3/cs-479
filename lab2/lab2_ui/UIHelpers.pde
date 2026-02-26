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
  drawStatItem(20, 215, "Resting Heart Rate", restingBPM, "bpm", color(255, 200, 0));
  
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
    rect(240, 225, 150, 25, 5);
    fill(80);
    textSize(11);
    textAlign(CENTER);
    text("RECALCULATE", 315, 242);
    textAlign(LEFT);
    if (btnHover && mousePressed) {
       isRestingBaselineComplete = false;
       restingBaselineStartTime = millis();
    }
  }

  drawStatItem(20, 350, "Respiratory Rate", sensorData[3], "br/m", color(100, 150, 255));
  
  fill(255);
  noStroke();
  rect(450, 80, 480, 390, 15);
  
  fill(50);
  textSize(24); 
  text("Zone Intensity Analysis", 480, 120);
  
  float maxHR = 220 - userAge; 
  float hrPercent = (sensorData[2] / maxHR) * 100;
  
  textSize(18);
  fill(120);
  text("Effort Intensity", 480, 160);
  
  textSize(72); 
  fill(30);
  text(int(hrPercent) + "%", 480, 250);
  
  drawZoneBar(480, 310, 420, hrPercent);
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
  text("HR: " + int(sensorData[2]) + " bpm", 45, 260);
  text("Resp: " + int(sensorData[3]) + " br/m", 45, 305);
  
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
  } else {
    float bpmDiff = sensorData[2] - restingBPM;
    textSize(38);
    if (bpmDiff > 12) {
      fill(255, 50, 50);
      text("STRESSED", 45, 210);
    } else {
      fill(75, 175, 75);
      text("CALM", 45, 210);
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
  
  // Music Indicator
  fill(100, 150, 255);
  textSize(16);
  text("\u266B Now Playing: Clair De Lune", 430, 150);
  
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
  // Stats Panel on the Left
  fill(255);
  rect(20, 80, 350, 390, 15);
  
  fill(50);
  textSize(22);
  text("Core Vitals", 45, 120);
  
  // Vital list
  drawPSCStat(45, 160, "HR", int(sensorData[2]), "bpm");
  drawPSCStat(45, 220, "HRV", int(sensorData[6]), "ms");
  drawPSCStat(45, 280, "SpO2", int(sensorData[7]), "%");
  drawPSCStat(45, 340, "Resp", int(sensorData[3]), "br/m");

  // Diagnostic Panel on the Right
  fill(255);
  rect(400, 80, 540, 390, 15);
  
  fill(50);
  textSize(22);
  text("Physiological State Diagnostic", 430, 120);
  
  // Logic for States
  String state = "Indeterminate";
  String desc = "Analyzing vital patterns...";
  color stateCol = color(150);
  
  float hr = sensorData[2];
  float hrv = sensorData[6];
  float spo2 = sensorData[7];
  float resp = sensorData[3];
  
  if (!isRestingBaselineComplete) {
    state = "Calibrating";
    desc = "Need resting baseline for full analysis.";
  } else if (spo2 < 93) {
    state = "Hypoxic Stress";
    desc = "Low oxygen saturation detected. Oxygen flow may be restricted.";
    stateCol = color(255, 100, 0);
  } else if (spo2 < 94 && hr > 100) {
    state = "Dysregulated State";
    desc = "Impaired homeostasis. Oxygen dropping while heart is racing.";
    stateCol = color(200, 0, 0);
  } else if (hr > restingBPM + 20 && hrv < 35) {
    state = "Acute Stress";
    desc = "High sympathetic arousal. Deep breathing recommended.";
    stateCol = color(255, 50, 50);
  } else if (resp > 28 || resp < 8) {
    state = "Respiratory Strain";
    desc = "Abnormal breathing frequency. Possible hyperventilation.";
    stateCol = color(100, 150, 255);
  } else if (hrv < 25 && hr < restingBPM + 15) {
    state = "Autonomic Imbalance";
    desc = "Low HRV relative to HR. Possible fatigue or overtraining.";
    stateCol = color(200, 100, 255);
  } else if (hr > restingBPM + 5 && hr < restingBPM + 20 && hrv > 45) {
    state = "Recovery";
    desc = "Heart returning to baseline with strong autonomic control.";
    stateCol = color(0, 200, 150);
  } else if (abs(hr - restingBPM) < 10 && hrv > 50 && spo2 >= 96) {
    state = "Rested Stable";
    desc = "Optimal homeostasis. Vagal tone is dominant and healthy.";
    stateCol = color(75, 175, 75);
  }

  // Draw State Box
  noStroke();
  fill(stateCol, 20);
  rect(430, 150, 480, 100, 15);
  
  fill(stateCol);
  textSize(36);
  text(state, 450, 215);
  
  fill(80);
  textSize(18);
  textLeading(24);
  text(desc, 430, 290, 480, 100);
  
  // Mini Visualization (State Intensity)
  stroke(240);
  line(430, 370, 910, 370);
  noStroke();
  fill(stateCol);
  rect(430, 368, map(hrv, 10, 100, 50, 480), 4, 2);
  textSize(12);
  text("Autonomic Recovery Strength", 430, 390);
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
  rect(x, y, 400, 120, 15); 
  
  fill(100);
  textSize(20); 
  text(label, x + 30, y + 45);
  
  fill(30);
  textSize(48); 
  String valText = str(int(val));
  text(valText, x + 30, y + 95);
  
  // Right-aligned unit text
  fill(180);
  textSize(22);
  textAlign(RIGHT);
  text(unit, x + 370, y + 95);
  textAlign(LEFT); // Reset
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

void drawCalibrateButton() {
  float bx = width - 180;
  float by = height - 60;
  float bw = 160;
  float bh = 40;
  
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
