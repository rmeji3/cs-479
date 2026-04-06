import processing.serial.*;

Serial myPort;
String val;
float[] sensorData = new float[10];

// Visualization components
Style style;
Heatmap heat;
RealTimeGraph fsrGraph;
RealTimeGraph accelGraph;

// Sidebar and Mode management
int mode = 0; // 0: Live, 1: Record/Replay
ArrayList<float[]> recordedData = new ArrayList<float[]>();
boolean isRecording = false;
int replayIndex = -1;

// Calibrating Accelerometer
float accelOffsetX = 0, accelOffsetY = 0, accelOffsetZ = 0;
boolean isCalibrated = false;

// Gait Analysis
float mfpValue = 0;
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
int historyLimit = 100; // ~2 seconds of data at 50Hz

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
  heat = new Heatmap(130, 80, 400, 500);
  
  String[] fsrLabels = {"MF", "LF", "MM", "HEEL"};
  fsrGraph = new RealTimeGraph(560, 80, 650, 360, 4, fsrLabels, "FSR SENSOR DATA");
  
  String[] accelLabels = {"AccX", "AccY", "AccZ"};
  accelGraph = new RealTimeGraph(560, 460, 650, 360, 3, accelLabels, "ACCELEROMETER DATA");
  
  startTime = millis();
}

void draw() {
  background(Style.BG);
  
  // Draw Sidebar Tab
  drawSidebar();
  
  pushMatrix();
  translate(100, 0); // Translate everything after sidebar
  
  // Sidebar/Header background
  fill(Style.PANEL);
  noStroke();
  rect(0, 0, width, 60);
  
  // Dashboard Header
  fill(Style.ACCENT);
  textSize(24);
  textAlign(LEFT, CENTER);
  text("SMART-SOLE GAIT ANALYSIS DASHBOARD", 30, 30);
  
  // Use recorded data if in replay mode
  if (mode == 1 && replayIndex >= 0 && replayIndex < recordedData.size()) {
      float[] d = recordedData.get(replayIndex);
      heat.update(d[0], d[1], d[2], d[3]);
      // Graphs update differently in replay mode - they show the whole history
  }

  // Display components
  heat.display(style);
  fsrGraph.display(style);
  accelGraph.display(style);
  
  // Gait Metrics Display
  drawMetrics();
  
  popMatrix();
}

void drawSidebar() {
  fill(Style.PANEL);
  noStroke();
  rect(0, 0, 100, height);
  
  // Title
  fill(Style.TEXT_DIM);
  textSize(10);
  textAlign(CENTER);
  text("MODE", 50, 30);
  
  // LIVE Tab
  fill(mode == 0 ? Style.ACCENT : 40);
  rect(10, 50, 80, 40, 5);
  fill(mode == 0 ? 0 : 200);
  textSize(14);
  text("LIVE", 50, 75);
  
  // RECORD Tab
  fill(mode == 1 ? Style.ACCENT : 40);
  rect(10, 100, 80, 40, 5);
  fill(isRecording ? Style.RED : (mode == 1 ? 0 : 200));
  text("RECORD", 50, 125);
  
  if (mode == 1) {
      // Show controls for replay
      fill(255);
      textSize(10);
      text("REC: R", 50, 160);
      text("CLR: X", 50, 175);
      
      if (recordedData.size() > 0) {
          fill(Style.TEXT_DIM);
          text(recordedData.size() + " frms", 50, 200);
      }
  }
}

void mousePressed() {
    if (mouseX < 100) {
        if (mouseY > 50 && mouseY < 90) mode = 0;
        if (mouseY > 100 && mouseY < 140) mode = 1;
    } else if (mode == 1) {
        // Handle clicking on the graph for replay in mode 1
        // Simplified: map x coordinate on the graph area to replayIndex
        if (mouseX > 560 && mouseX < 1210 && mouseY > 80 && mouseY < 440) {
            replayIndex = (int)map(mouseX, 560, 1210, 0, recordedData.size()-1);
            replayIndex = constrain(replayIndex, 0, recordedData.size()-1);
        }
    }
}

void serialEvent(Serial p) {
  val = p.readStringUntil('\n');
  if (val != null) {
    val = trim(val);
    String[] parts = split(val, ',');
    if (parts.length >= 10) {
      for (int i = 0; i < 10; i++) {
        sensorData[i] = float(parts[i]);
      }
      
      // Calibrate accelerometer (apply offsets)
      float ax = sensorData[4] - accelOffsetX;
      float ay = sensorData[5] - accelOffsetY;
      float az = sensorData[6] - accelOffsetZ;
      
      float[] currentFrameDatas = {sensorData[0], sensorData[1], sensorData[2], sensorData[3], ax, ay, az};
      
      if (mode == 1 && isRecording) {
          recordedData.add(currentFrameDatas);
          // Auto-limit to prevent memory lag
          if (recordedData.size() > 2000) recordedData.remove(0);
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
    isRecording = !isRecording;
    if (isRecording) {
      recordedData.clear();
      replayIndex = -1;
    }
  } else if (key == 'x' || key == 'X') {
    recordedData.clear();
    replayIndex = -1;
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
  mfpValue = ((mm + mf) * 100.0) / (mm + mf + lf + heel + 0.001);
  
  // Add to rolling history for profile evaluation
  mfpHistory.add(mfpValue);
  if (mfpHistory.size() > historyLimit) mfpHistory.remove(0);
  
  // Step Detection (Basic threshold on total pressure)
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
  
  // Refined profiles based on Medial Force Percentage
  // Typical Normal: 45-55%
  // Pronation: > 60% (Heavier focus on medial side)
  // Supination: < 40% (Heavier focus on lateral side)
  if (avgMFP > 58) {
    currentProfile = "Pronation";
  } else if (avgMFP < 42) {
    currentProfile = "Supination";
  } else {
    currentProfile = "Normal";
  }
}

void drawMetrics() {
  float cardX = 30;
  float cardY = 600;
  float cardW = 400;
  float cardH = 220;
  
  style.card(cardX, cardY, cardW, cardH, "GAIT METRICS");
  
  float textX = cardX + 20;
  float textY = cardY + 60;
  float spacing = 28;
  
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
  
  // Bar fill
  fill(Style.ACCENT);
  rect(barX, barY, map(mfpValue, 0, 100, 0, barW), 12, 4);
  
  // Percentage label - Move below the bar to keep within box bounds
  fill(Style.TEXT_MAIN);
  textSize(12);
  textAlign(CENTER, TOP);
  text(nf(mfpValue, 1, 1) + "%", barX + (map(mfpValue, 0, 100, 0, barW)), barY + 16);
  
  // Reset alignment for other UI elements
  textAlign(LEFT, TOP);
}
