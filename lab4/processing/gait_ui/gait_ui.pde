import processing.serial.*;

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
  heat = new Heatmap(30, 80, 420, 520);
  
  String[] fsrLabels = {"MF", "LF", "MM", "HEEL"};
  fsrGraph = new RealTimeGraph(480, 80, 630, 360, 4, fsrLabels, "FSR SENSOR DATA");
  
  String[] accelLabels = {"AccX", "AccY", "AccZ"};
  accelGraph = new RealTimeGraph(480, 460, 630, 360, 3, accelLabels, "ACCELEROMETER DATA");

  recordGraph = new StaticGraph(480, 80, 630, 400, fsrLabels, "RECORDED GAIT PROFILE");
  recordAccel = new StaticGraph(480, 500, 630, 320, accelLabels, "RECORDED ACCELEROMETER");
  
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
  
  if (mode == 0) {
    drawLiveDashboard();
  } else {
    drawRecordDashboard();
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
  
  heat.update(displayData[0], displayData[1], displayData[2], displayData[3]);
  heat.display(style);

  // Big graph for selection
  recordGraph.setData(recordedData);
  recordGraph.display(style);
  
  recordAccel.setData(recordedData);
  recordAccel.display(style);
  
  // Replay frame indicator and RECORD CONTROLS moved to left side under heatmap
  float controlX = 30;
  float controlY = 620;

  if (recordGraph.selectedIndex != -1) {
    recordAccel.selectedIndex = recordGraph.selectedIndex;
    fill(Style.ACCENT);
    textSize(20);
    textAlign(LEFT, TOP);
    text("SELECTED DATA", controlX, controlY);
    
    // Summary of that point
    float[] d = recordedData.get(recordGraph.selectedIndex);
    fill(255);
    textSize(14);
    text("MF: " + (int)d[0] + " LF: " + (int)d[1] + " MM: " + (int)d[2] + " HEEL: " + (int)d[3], controlX, controlY + 30);
  }

  // Record Controls Column
  style.button(controlX, controlY + 70, 180, 50, isRecording ? "STOP RECORD" : "START RECORD", isRecording ? Style.RED : Style.GREEN, false, 100);
  style.button(controlX + 190, controlY + 70, 100, 50, "CLEAR", 100, false, 100);
  
  if (isRecording) {
    fill(Style.RED);
    textAlign(LEFT, CENTER);
    text("RECORDING ACTIVE", controlX, controlY + 140);
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
  
  if (isRecording) {
    fill(Style.RED, 150 + sin(frameCount*0.1)*100);
    ellipse(80, 110, 10, 10);
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
        if (mouseY > 50 && mouseY < 100) {
          mode = 0;
          fsrGraph.clear();
          accelGraph.clear();
        }
        if (mouseY > 110 && mouseY < 160) mode = 1;
    } else if (mode == 1) {
        // Record buttons (relative to translated coordinates - controlX=30, controlY=620)
        // 100 is the sidebar translation
        if (mouseX > 100 + 30 && mouseX < 100 + 210 && mouseY > 620 + 70 && mouseY < 620 + 70 + 50) {
            toggleRecording();
        } else if (mouseX > 100 + 220 && mouseX < 100 + 320 && mouseY > 620 + 70 && mouseY < 620 + 70 + 50) {
            clearRecording();
        }
    }
}

void toggleRecording() {
  isRecording = !isRecording;
  if (isRecording) {
      recordedData.clear();
      recordGraph.selectedIndex = -1;
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
  
  // Instantaneous Medial Force Percentage Calculation
  // Media side is MM (Medial Midfoot) and MF (Medial Forefoot)
  // Total side is all 4 sensors
  float rawMFP = ((mm + mf) * 100.0) / (mm + mf + lf + heel + 0.01);
  mfpValue = rawMFP;
  
  // Exponential Moving Average (EMA) for smoother display
  // alpha of 0.1 means 10% new value, 90% old value
  float alpha = 0.08; 
  mfpValueSmooth = (alpha * rawMFP) + ((1 - alpha) * mfpValueSmooth);
  
  // Add raw value to history for longer-term profiling
  mfpHistory.add(rawMFP);
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
