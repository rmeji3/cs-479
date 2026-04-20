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
  
  // MFP Calculation
  // MFP = ((MM + MF) * 100) / (MM + MF + LF + HEEL + 0.001)
  mfpValue = ((mm + mf) * 100.0) / (mm + mf + lf + heel + 0.001);
  
  // Step Detection (Basic threshold on heel/forefoot total pressure)
  float totalPressure = mf + lf + mm + heel;
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
  float cardY = 600;
  float cardW = 400;
  float cardH = 200;

  style.card(cardX, cardY, cardW, cardH, "GAIT METRICS");

  float textX = cardX + 20;
  float textY = cardY + 60;
  float spacing = 28;
  
  textSize(16);
  textAlign(LEFT, TOP);

  // Profile
  fill(Style.TEXT_DIM);
  text("GAIT PROFILE:", textX, textY);
  fill(#E63946);
  textSize(15);
  text(currentProfile.toUpperCase(), textX + 130, textY);

  // Status
  textY += spacing;
  fill(Style.TEXT_DIM);
  textSize(14);
  text("MOTION STATUS:", textX, textY);
  fill(inMotion ? #2ECC71 : #E63946);
  textSize(15);
  text(inMotion ? "IN MOTION" : "STANDING STILL", textX + 130, textY);

  // Step Count
  textY += spacing;
  fill(Style.TEXT_DIM);
  textSize(14);
  text("STEP COUNT:", textX, textY);
  fill(Style.TEXT_MAIN);
  textSize(15);
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
  textSize(14);
  text("CADENCE:", textX, textY);
  fill(Style.TEXT_MAIN);
  textSize(15);
  text(nf(cadence, 1, 1) + " steps/min", textX + 130, textY);

  // MFP Visualization
  textY += spacing;
  fill(Style.TEXT_DIM);
  textSize(14);
  text("MEDIAL FORCE %:", textX, textY);

  float barW = 200;
  float barX = textX + 130;
  float barY = textY + 4;

  // Bar background
  fill(#E2E8F0);
  stroke(#CBD5E0);
  strokeWeight(1);
  rect(barX, barY, barW, 12, 4);
  
  // Bar fill
  fill(Style.ACCENT);
  rect(barX, barY, map(mfpValue, 0, 100, 0, barW), 12, 4);
  
  fill(Style.TEXT_MAIN);
  text(nf(mfpValue, 1, 1) + "%", barX + barW + 10, textY);
}

void mousePressed() {
  // Check if tabs were clicked
  float headerEnd = 60;
  float tabY = headerEnd;
  float tabAreaHeight = 50;
  
  if (mouseY >= tabY && mouseY <= tabY + tabAreaHeight) {
    for (int i = 0; i < 2; i++) {
      if (mouseX >= tabX[i] && mouseX <= tabX[i] + tabW[i]) {
        activeTab = i;
      }
    }
  }
}
