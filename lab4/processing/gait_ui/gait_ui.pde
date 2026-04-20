import processing.serial.*;
import processing.sound.*;

Serial myPort;
String val;
float[] sensorData = new float[10];

// Visualization components
Style style;
Heatmap heat;
RealTimeGraph fsrGraph;
RealTimeGraph accelGraph;

// Recorded data visualization
StaticGraph recordGraph;
StaticGraph recordAccel;

// Rhythm Game
RhythmGame rhythmGame;

// Sidebar and Mode management
int mode = 0; // 0: Live, 1: Record/Replay, 2: Rhythm Game
ArrayList<float[]> recordedData = new ArrayList<float[]>();
boolean isRecording = false;
long recordStartTime = 0;
long recordDuration  = 0;
int replayIndex = -1;

// Calibrating Accelerometer
float accelOffsetX = 0, accelOffsetY = 0, accelOffsetZ = 0;
boolean isCalibrated = false;

// Gait Analysis
float mfpValue = 0;
float mfpValueSmooth = 0; // Smoothed version
int stepCount = 0;
float cadence = 0;
long startTime;
boolean inStance = false;
float stanceThreshold = 100; // Adjust based on calibration
boolean inMotion = false;
float motionThreshold = 1.0; // Reduced for better sensitivity after filtering
int motionDebounce = 0; // For smoothing stance/motion transitions
int motionDebounceLimit = 15; // Number of frames to confirm state change

// Gait Profiling Buffers
ArrayList<Float> mfpHistory = new ArrayList<Float>();
ArrayList<Float> ffpHistory = new ArrayList<Float>(); // Forefoot Percentage history
int historyLimit = 200; // Increased to ~4 seconds for better smoothing
// Profile tracking
String currentProfile = "Normal";

void setup() {
  size(1250, 850); // Increased size to accommodate sidebar

  // Try to connect to serial - Prefer cu.usbmodem for Arduino
  String[] ports = Serial.list();
  String portName = null;

  if (ports.length > 0) {
    for (String p : ports) {
      if (p.contains("cu.usbmodem")) {
        portName = p;
        break;
      }
    }
    // Fallback if no usbmodem found
    if (portName == null) portName = ports[0];

    println("Connecting to: " + portName);
    myPort = new Serial(this, portName, 115200);
    myPort.bufferUntil('\n');
  }

  style = new Style();
  // Initialize components - Offset by sidebar width (100)
  // Shift Heatmap more to the left and Graphs to the right
  heat = new Heatmap(30, 80, 420, 480);

  String[] fsrLabels = {"MF", "LF", "MM", "HEEL"};
  fsrGraph = new RealTimeGraph(480, 80, 630, 360, 4, fsrLabels, "FSR SENSOR DATA");

  String[] accelLabels = {"AccX", "AccY", "AccZ"};
  accelGraph = new RealTimeGraph(480, 460, 630, 360, 3, accelLabels, "ACCELEROMETER DATA");

  recordGraph = new StaticGraph(480, 80, 630, 400, fsrLabels, "RECORDED GAIT PROFILE");
  recordAccel = new StaticGraph(480, 500, 630, 320, accelLabels, "RECORDED ACCELEROMETER");

  // Rhythm game
  rhythmGame = new RhythmGame(this);

  startTime = millis();
}

void draw() {
  background(Style.BG);

  // Always update rhythm game (handles timing/audio even off-screen)
  rhythmGame.update();

  // Draw Sidebar Tab
  drawSidebar();

  pushMatrix();
  translate(100, 0); // Translate everything after sidebar

  if (mode == 0) {
    // Header
    fill(Style.PANEL);
    noStroke();
    rect(0, 0, width, 60);
    fill(Style.ACCENT);
    textSize(24);
    textAlign(LEFT, CENTER);
    text("SMART-SOLE GAIT ANALYSIS DASHBOARD", 30, 30);
    drawLiveDashboard();

  } else if (mode == 1) {
    // Header
    fill(Style.PANEL);
    noStroke();
    rect(0, 0, width, 60);
    fill(Style.ACCENT);
    textSize(24);
    textAlign(LEFT, CENTER);
    text("SMART-SOLE GAIT ANALYSIS DASHBOARD", 30, 30);
    drawRecordDashboard();

  } else if (mode == 2) {
    rhythmGame.display(style);
  }

  popMatrix();
}

void drawLiveDashboard() {
  heat.display(style);
  fsrGraph.display(style);
  accelGraph.display(style);
  drawMetrics();
}

void drawRecordDashboard() {
  // Heatmap for replaying frame
  float[] displayData;
  if (isRecording && recordedData.size() > 0) {
    displayData = recordedData.get(recordedData.size()-1);
  } else if (recordGraph.selectedIndex != -1 && recordGraph.selectedIndex < recordedData.size()) {
    displayData = recordedData.get(recordGraph.selectedIndex);
  } else {
    displayData = new float[]{0,0,0,0,0,0,0};
  }

  // Sanitize any persisted NaNs before displaying
  for (int i = 0; i < displayData.length; i++) {
    if (Float.isNaN(displayData[i])) displayData[i] = 0;
  }

  heat.update(displayData[0], displayData[1], displayData[2], displayData[3]);
  heat.display(style);

  // Big graph for selection
  recordGraph.setData(recordedData);
  recordGraph.display(style);

  recordAccel.setData(recordedData);
  recordAccel.display(style);

  // Sync selected index across graphs
  if (recordGraph.selectedIndex != -1) {
    recordAccel.selectedIndex = recordGraph.selectedIndex;
  }

  float controlX = 30;

  // ── STATS CARD (shown after recording stops) ────────────────
  // Sits between heatmap (ends y=560) and buttons (start y=702)
  if (!isRecording && recordedData.size() > 0) {
    float sx = controlX, sy = 565, sw = 420, sh = 128;
    style.card(sx, sy, sw, sh, "RECORDING STATS");

    // Compute stats from recorded data
    float totalMFP  = 0;
    float peakTotal = 0;
    int   recSteps  = 0;
    boolean wasStance = false;

    for (float[] d : recordedData) {
      float mf = d[0], lf = d[1], mm = d[2], heel = d[3];
      float total = mf + lf + mm + heel;
      float mfp   = (mm * 100.0) / (total + 0.01);
      float ffp   = (mf + lf) * 100.0 / (total + 0.01);
      totalMFP  += mfp;
      peakTotal  = max(peakTotal, total);
      // Step detection (same threshold as live mode)
      if (!wasStance && total > stanceThreshold)       { recSteps++; wasStance = true; }
      else if (wasStance && total < stanceThreshold * 0.4) { wasStance = false; }
    }

    float avgMFP   = totalMFP / recordedData.size();
    float durSec   = recordDuration / 1000.0;
    
    // Logic: In-Toe is based primarily on MM pressure
    String profile = "Normal";
    if (avgMFP > 58) profile = "In-Toe";
    else if (avgMFP < 15) profile = "Out-Toe";

    float tx = sx + 20, ty = sy + 62;
    float col2 = sx + 150;
    float spacing = 14;

    textSize(13);
    textAlign(LEFT, TOP);

    fill(Style.TEXT_DIM);  text("DURATION",     tx, ty);
    fill(Style.TEXT_MAIN); text(nf(durSec, 1, 1) + " sec  (" + recordedData.size() + " frames)", col2, ty);
    ty += spacing;

    fill(Style.TEXT_DIM);  text("STEPS",        tx, ty);
    fill(Style.TEXT_MAIN); text(recSteps, col2, ty);
    ty += spacing;

    fill(Style.TEXT_DIM);  text("GAIT PROFILE", tx, ty);
    fill(Style.ACCENT);    text(profile.toUpperCase(), col2, ty);
    ty += spacing;

    fill(Style.TEXT_DIM);  text("AVG MFP",      tx, ty);
    fill(Style.TEXT_MAIN); text(nf(avgMFP, 1, 1) + "%", col2, ty);
  }

  // ── RECORD CONTROLS (always visible, never covered) ────────
  // Buttons fixed at y=702, clear of the stats card (which ends at 693)
  style.button(controlX,       702, 200, 44, isRecording ? "STOP RECORD" : "START RECORD",
               isRecording ? Style.RED : Style.GREEN, false, 100);
  style.button(controlX + 210, 702, 100, 44, "CLEAR", 100, false, 100);

  if (isRecording) {
    fill(Style.RED);
    textSize(13);
    textAlign(LEFT, TOP);
    text("RECORDING ACTIVE", controlX, 756);
  }
}

void drawSidebar() {
  fill(Style.PANEL);
  noStroke();
  rect(0, 0, 100, height);

  // Title
  fill(Style.TEXT_DIM);
  textSize(10);
  textAlign(CENTER);
  text("NAVIGATION", 50, 30);

  // LIVE Tab
  style.button(10, 50, 80, 50, "LIVE", Style.ACCENT, mode == 0, 0);

  // RECORD Tab
  style.button(10, 110, 80, 50, "RECORD", Style.ACCENT, mode == 1, 0);

  // RHYTHM Tab
  style.button(10, 170, 80, 50, "RHYTHM", Style.ACCENT, mode == 2, 0);

  if (isRecording) {
    fill(Style.RED, 150 + sin(frameCount*0.1)*100);
    ellipse(80, 110, 10, 10);
  }

  // Rhythm game playing indicator
  if (rhythmGame != null && rhythmGame.isPlaying) {
    fill(color(255,215,0), 160 + sin(frameCount*0.15)*80);
    ellipse(80, 195, 9, 9);
  }

  // Calibration Info at Bottom
  fill(Style.TEXT_DIM);
  textSize(9);
  textAlign(CENTER);
  text("PRESS 'C' TO\nCALIBRATE", 50, height - 30);
  if (isCalibrated) {
    fill(Style.GREEN);
    text("CALIBRATED", 50, height - 50);
  }
}

void mousePressed() {
  if (mouseX < 100) {
    // Sidebar tab clicks
    if (mouseY > 50 && mouseY < 100) {
      mode = 0;
      fsrGraph.clear();
      accelGraph.clear();
    } else if (mouseY > 110 && mouseY < 160) {
      mode = 1;
    } else if (mouseY > 170 && mouseY < 220) {
      mode = 2;
    }
  } else if (mode == 1) {
    // Record buttons fixed at y=702, height=44, sidebar offset=100
    // START/STOP: x=100+30 to 100+230
    if (mouseX > 130 && mouseX < 330 && mouseY > 702 && mouseY < 746) {
      toggleRecording();
    // CLEAR: x=100+240 to 100+340
    } else if (mouseX > 340 && mouseX < 440 && mouseY > 702 && mouseY < 746) {
      clearRecording();
    }
  } else if (mode == 2) {
    rhythmGame.mousePressed();
  }
}

void toggleRecording() {
  isRecording = !isRecording;
  if (isRecording) {
    recordedData.clear();
    recordGraph.selectedIndex = -1;
    recordStartTime = millis();
  } else {
    recordDuration = millis() - recordStartTime;
  }
}

void clearRecording() {
  recordedData.clear();
  recordGraph.selectedIndex = -1;
}

void serialEvent(Serial p) {
  val = p.readStringUntil('\n');
  if (val != null) {
    val = trim(val);
    String[] parts = split(val, ',');
    if (parts.length >= 10) {
      for (int i = 0; i < 10; i++) {
        float v = 0;
        try {
          v = Float.parseFloat(parts[i]);
        } catch (Exception e) {
          v = 0;
        }
        if (Float.isNaN(v)) v = 0;
        sensorData[i] = v;
      }

      // Calibrate accelerometer (apply offsets) and guard against NaN
      float ax = sensorData[4] - accelOffsetX;
      float ay = sensorData[5] - accelOffsetY;
      float az = sensorData[6] - accelOffsetZ;
      if (Float.isNaN(ax)) ax = 0;
      if (Float.isNaN(ay)) ay = 0;
      if (Float.isNaN(az)) az = 0;

      // Sanitize FSRs before storing frame
      float s0 = Float.isNaN(sensorData[0]) ? 0 : sensorData[0];
      float s1 = Float.isNaN(sensorData[1]) ? 0 : sensorData[1];
      float s2 = Float.isNaN(sensorData[2]) ? 0 : sensorData[2];
      float s3 = Float.isNaN(sensorData[3]) ? 0 : sensorData[3];
      float[] currentFrameDatas = {s0, s1, s2, s3, ax, ay, az};

      if (mode == 1 && isRecording) {
          recordedData.add(currentFrameDatas);
          // Auto-limit to prevent memory lag
          if (recordedData.size() > 2000) recordedData.remove(0);
      }

      // Feed accel data to rhythm game regardless of active mode
      // (lets you play while peeking at live data)
      if (rhythmGame != null) {
        rhythmGame.onAccel(ax, ay, az);
      }

      // Update visualizations in LIVE mode OR while RECORDING
      if (mode == 0 || (mode == 1 && isRecording)) {
          heat.update(sensorData[0], sensorData[1], sensorData[2], sensorData[3]);

          float[] fsrs = {sensorData[0], sensorData[1], sensorData[2], sensorData[3]};
          fsrGraph.addData(fsrs);

          float[] accels = {ax, ay, az};
          accelGraph.addData(accels);

          // Analysis
          calculateGaitMetrics(fsrs, accels);
      }
    }
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    calibrateAccel();
  } else if (key == 'r' || key == 'R') {
    toggleRecording();
  } else if (key == 'x' || key == 'X') {
    clearRecording();
  }
}

void calibrateAccel() {
  // Simple calibration: assume flat, level surface
  // Vertical acceleration (az) should be ~9.8 on many sensors (or 0 if gravity compensated)
  // Let's zero all axes for now and rely on delta from current state
  accelOffsetX = sensorData[4];
  accelOffsetY = sensorData[5];
  accelOffsetZ = sensorData[6] - 9.8; // Calibrate Z relative to 1G
  isCalibrated = true;
  println("Accelerometer Calibrated! Offsets: " + accelOffsetX + ", " + accelOffsetY + ", " + accelOffsetZ);
}

void calculateGaitMetrics(float[] fsrs, float[] accels) {
  float mf = fsrs[0];
  float lf = fsrs[1];
  float mm = fsrs[2];
  float heel = fsrs[3];

  // Total side is all 4 sensors
  float totalPressure = mm + mf + lf + heel;

  // Final corrected logic for In-Toe/Out-Toe:
  // MM heavy = In-Toe, LF heavy = Out-Toe.
  // Tip-Toe = MF heavy (front focus).
  
  // Percentage = (Medial sensors / total) * 100
  // MF is technically medial but for this specific classification we'll use MM for In-Toe focus
  float rawMFP = (mm * 100.0) / (totalPressure + 0.01);
  mfpValue = rawMFP;

  // Forefoot Percentage (FFP) for Tip-Toe detection
  // MF and LF are the front sensors
  float rawFFP = ((mf + lf) * 100.0) / (totalPressure + 0.01);

  // Exponential Moving Average (EMA) for smoother display
  // alpha of 0.1 means 10% new value, 90% old value
  float alpha = 0.08;
  mfpValueSmooth = (alpha * rawMFP) + ((1 - alpha) * mfpValueSmooth);

  // Add raw values to history for longer-term profiling
  mfpHistory.add(rawMFP);
  ffpHistory.add(rawFFP);
  if (mfpHistory.size() > historyLimit) mfpHistory.remove(0);
  if (ffpHistory.size() > historyLimit) ffpHistory.remove(0);

  // Step Detection (Basic threshold on total pressure)
  if (!inStance && totalPressure > stanceThreshold) {
    inStance = true;
    stepCount++;
  } else if (inStance && totalPressure < stanceThreshold * 0.4) { // Slightly lower release threshold for cleaner steps
    inStance = false;
  }

  // Cadence (over time since start)
  float minutesPassed = (millis() - startTime) / 60000.0;
  if (minutesPassed > 0 && stepCount > 0) {
    cadence = stepCount / minutesPassed;
  }

  // Motion Detection with Smoothing (Debouncing)
  float accelMag = sqrt(sq(accels[0]) + sq(accels[1]) + (sq(accels[2]))); // Magnitude including gravity
  float deviation = abs(accelMag - 9.8); // Magnitude deviation from 1G gravity

  if (deviation > motionThreshold) {
    motionDebounce++;
    if (motionDebounce > motionDebounceLimit) {
      inMotion = true;
      motionDebounce = motionDebounceLimit; // Cap it
      updateGaitProfile();
    }
  } else {
    motionDebounce--;
    if (motionDebounce < -motionDebounceLimit) {
      inMotion = false;
      motionDebounce = -motionDebounceLimit;
    }
  }
}

void updateGaitProfile() {
  if (mfpHistory.size() < 20) return; // Need some data first

  // Average history for profiling
  float avgMFP = 0;
  for (float val : mfpHistory) avgMFP += val;
  avgMFP /= mfpHistory.size();
  
  float avgFFP = 0;
  for (float val : ffpHistory) avgFFP += val;
  avgFFP /= ffpHistory.size();

  // Refined profiles based on Medial Force Percentage and Forefoot Percentage
  // Typical Normal: 45-55%
  // In-Toe: > 60% (Heavier focus on medial side)
  // Out-Toe: < 40% (Heavier focus on lateral side)
  // Tip-Toe: > 75% on forefoot (MF + LF)
  if (avgFFP > 75) {
    currentProfile = "Tip-Toe";
  } else if (avgMFP > 58) {
    currentProfile = "In-Toe";
  } else if (avgMFP < 42) {
    currentProfile = "Out-Toe";
  } else {
    currentProfile = "Normal";
  }
}

void drawMetrics() {
  float cardX = 30;
  float cardY = 572;   // 12px gap below heatmap (which now ends at 560)
  float cardW = 400;
  float cardH = 200;

  style.card(cardX, cardY, cardW, cardH, "GAIT METRICS");

  float textX = cardX + 20;
  float textY = cardY + 60;
  float spacing = 20;

  textSize(16);
  textAlign(LEFT, TOP);

  // Profile
  fill(Style.TEXT_DIM);
  text("GAIT PROFILE:", textX, textY);
  fill(Style.ACCENT);
  text(currentProfile.toUpperCase(), textX + 130, textY);

  // Status
  textY += spacing;
  fill(Style.TEXT_DIM);
  text("MOTION STATUS:", textX, textY);
  fill(inMotion ? Style.GREEN : Style.RED);
  text(inMotion ? "IN MOTION" : "STANDING STILL", textX + 130, textY);

  // Step Count
  textY += spacing;
  fill(Style.TEXT_DIM);
  text("STEP COUNT:", textX, textY);
  fill(Style.TEXT_MAIN);
  text(stepCount, textX + 130, textY);

  // Calibration Prompt
  textY += spacing;
  fill(Style.TEXT_DIM);
  text("ACCEL CAL:", textX, textY);
  fill(isCalibrated ? Style.GREEN : Style.RED);
  text(isCalibrated ? "DONE" : "Press 'C' to Calibrate", textX + 130, textY);

  // Cadence
  textY += spacing;
  fill(Style.TEXT_DIM);
  text("CADENCE:", textX, textY);
  fill(Style.TEXT_MAIN);
  text(nf(cadence, 1, 1) + " steps/min", textX + 130, textY);

  // MFP Visualization
  textY += spacing;
  fill(Style.TEXT_DIM);
  text("MEDIAL FORCE %:", textX, textY);

  float barW = 200;
  float barX = textX + 130;
  float barY = textY + 4;

  // Bar background
  fill(40);
  rect(barX, barY, barW, 12, 4);

  // Bar fill - Use Smoothed Value
  fill(Style.ACCENT);
  rect(barX, barY, map(mfpValueSmooth, 0, 100, 0, barW), 12, 4);

  // Percentage label - Move to the right of the bar
  fill(Style.TEXT_MAIN);
  textSize(14);
  textAlign(LEFT, CENTER);
  text(nf(mfpValueSmooth, 1, 1) + "%", barX + barW + 10, barY + 6);

  // Reset alignment for other UI elements
  textAlign(LEFT, TOP);
}
