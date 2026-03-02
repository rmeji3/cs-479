import processing.serial.*;
import processing.sound.*;

// Global Variables
Serial myPort;
SoundFile calmMusic;
String serialDataLine;
float[] sensorData = new float[8]; // ecgRaw, fsrRaw, bpm, respRate, inhale, exhale, HRV, SpO2

// Fitness Components
RealTimeGraph fitnessHrGraph;

// PSC Help Dropdown
boolean pscHelpOpen = false;

// UI Components
Sidebar leftSidebar;
RealTimeGraph ecgGraph;
RealTimeGraph respGraph;

// App State and Modes
String currentMode = "Overview";
String prevMode = "Overview";
int userAge = 22; 
boolean isAgeFocused = false;
String ageBuffer = "";

// State Management
boolean isRestingBaselineComplete = false;
long restingBaselineStartTime = 0;
float restingBPM = 0;
float restingResp = 0;

boolean isFitnessActive = false;
long fitnessSessionStartTime = 0;
long respCalibrationTime = 0; 

// Breathing Calibration state
boolean isCalibratingResp = false;
long calibStartTime = 0;
float tempMin = 1024;
float tempMax = 0;
float respInhaleThreshold = 850;
float respExhaleThreshold = 700;

// Visual Theme
color bgColor = color(245, 247, 250);
color sidebarColor = color(210, 255, 210); // Light Mint
color cardBg = color(255);

void setup() {
  size(1200, 800);
  smooth();
  
  // ... Serial setup code remains the same ...
  String[] ports = Serial.list();
  String targetPort = "";
  for (String p : ports) {
    String pLower = p.toLowerCase();
    if (pLower.contains("usb")) targetPort = p;
    else if (pLower.contains("com") && !pLower.contains("incoming")) targetPort = p;
  }
  try {
    if (!targetPort.equals("")) {
      myPort = new Serial(this, targetPort, 115200);
      myPort.bufferUntil('\n');
    }
  } catch (Exception e) {}
  
  // Initialize UI components
  leftSidebar = new Sidebar();
  ecgGraph = new RealTimeGraph(260, 520, 440, 220, "Live ECG Signal", color(100, 150, 255));
  respGraph = new RealTimeGraph(740, 520, 440, 220, "Respiratory (FSR)", color(255, 200, 50));
  
  // New Fitness HR Graph - Slightly narrower (540px)
  fitnessHrGraph = new RealTimeGraph(400, 80, 540, 390, "Heart Rate Trend", color(150), 40, 220);
  fitnessHrGraph.isHrGraph = true;
  fitnessHrGraph.showTimeTicks = true;
  fitnessHrGraph.autoAdjustX = true; // Shows the whole session
  
  // Load Music
  try {
    calmMusic = new SoundFile(this, "ClairDeLune.mp3");
  } catch (Exception e) {
    println("Music file not found: ClairDeLune.mp3");
  }
  
  restingBaselineStartTime = millis();
  
  // Start breathing calibration on startup (10s)
  isCalibratingResp = true;
  calibStartTime = millis();
  tempMin = 1024;
  tempMax = 0;
}

void draw() {
  background(bgColor);
  if (myPort == null) simulateData();
  
  // Music Logic
  if (!currentMode.equals(prevMode)) {
    if (currentMode.equals("Stress Monitoring")) {
      if (calmMusic != null) calmMusic.loop();
    } else if (prevMode.equals("Stress Monitoring")) {
      if (calmMusic != null) calmMusic.stop();
    }
    prevMode = currentMode;
  }
  
  leftSidebar.display();
  
  pushMatrix();
  translate(240, 0); 
  drawHeader();
  
  if (currentMode.equals("Overview")) {
    drawOverview();
    ecgGraph.y = 520;
    respGraph.y = 520;
  } else if (currentMode.equals("Fitness Mode")) {
    drawFitnessMode();
    // Only update the trend graph if the session is ACTIVE
    if (isFitnessActive) {
      fitnessHrGraph.update(sensorData[2]);
    }
    fitnessHrGraph.display();
    
    ecgGraph.y = 560;
    respGraph.y = 560;
  } else if (currentMode.equals("PSC Analysis")) {
    drawPSCMode();
    ecgGraph.y = 520;
    respGraph.y = 520;
  } else {
    if (currentMode.equals("Stress Monitoring")) drawStressMode();
    else if (currentMode.equals("Meditation Monitoring")) drawMeditationMode();
    ecgGraph.y = 520;
    respGraph.y = 520;
  }
  
  popMatrix();
  
  // Waveforms (Absolute Position)
  ecgGraph.display();
  respGraph.display();
  
  // Respiration Calibration Logic (10s window)
  if (isCalibratingResp) {
    long elapsed = millis() - calibStartTime;
    if (elapsed < 10000) {
      // Track peaks and valleys
      if (sensorData[1] > tempMax) tempMax = sensorData[1];
      if (sensorData[1] < tempMin) tempMin = sensorData[1];
      respGraph.setStatus("CALIBRATING...");
    } else {
      // Finish calibration
      isCalibratingResp = false;
      // Set thresholds with a bit of buffer
      float range = tempMax - tempMin;
      if (range > 20) { 
        respInhaleThreshold = tempMin + (range * 0.7);
        respExhaleThreshold = tempMin + (range * 0.3);
        
        // Auto-Scale the graph to the user's range
        respGraph.yMin = max(0, tempMin - 50);
        respGraph.yMax = min(1023, tempMax + 50);
        
        // Sync visual markers
        respGraph.upperThresh = respInhaleThreshold;
        respGraph.lowerThresh = respExhaleThreshold;
      }
      respGraph.setStatus("");
    }
  } else {
    // Regular Status Detection using calibrated thresholds
    if (sensorData[1] > respInhaleThreshold) respGraph.setStatus("Inhaling...");
    else if (sensorData[1] < respExhaleThreshold) respGraph.setStatus("Exhaling...");
    else respGraph.setStatus("");
  }

  ecgGraph.update(sensorData[0]);
  respGraph.update(sensorData[1]);
  
  pscUpdate();
  
  // Calibrate Button
  drawCalibrateButton();
}

void keyPressed() {
  if (isAgeFocused) {
    if (key >= '0' && key <= '9') {
      ageBuffer += key;
    } else if (key == BACKSPACE && ageBuffer.length() > 0) {
      ageBuffer = ageBuffer.substring(0, ageBuffer.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      if (ageBuffer.length() > 0) {
        userAge = int(ageBuffer);
      }
      isAgeFocused = false;
      ageBuffer = "";
    }
  }
}

void mousePressed() {
  // Check if clicking age box in sidebar
  float ageY = height - 80;
  if (mouseX < 220 && mouseY > ageY - 30 && mouseY < ageY + 30) {
    isAgeFocused = true;
    ageBuffer = str(userAge);
  } else {
    isAgeFocused = false;
  }
  
  // PSC Help button
  if (currentMode.equals("PSC Analysis")) {
    if (mouseX > 900 && mouseX < 1000 && mouseY > 22 && mouseY < 52) {
      pscHelpOpen = !pscHelpOpen;
    } else if (pscHelpOpen) {
      boolean insidePanel = (mouseX > 260 && mouseX < 1180 && mouseY > 80 && mouseY < 640);
      if (!insidePanel) pscHelpOpen = false;
    }
  }
  
  // Check if clicking Calibrate Button (Bottom Right: 1030-1180, 750-790)
  if (mouseX > width - 180 && mouseX < width - 20 && mouseY > height - 60 && mouseY < height - 20) {
    if (!isCalibratingResp) {
      isCalibratingResp = true;
      calibStartTime = millis();
      tempMin = 1024;
      tempMax = 0;
      if (myPort != null) myPort.write('c'); 
    }
  }
}

void serialEvent(Serial p) {
  try {
    serialDataLine = p.readStringUntil('\n');
    if (serialDataLine != null) {
      serialDataLine = trim(serialDataLine);
      String[] list = split(serialDataLine, ',');
      
      // Only process if we have a full packet (at least 6 items)
      if (list.length >= 6) {
        float[] temp = new float[list.length];
        boolean valid = true;
        
        for (int i = 0; i < list.length; i++) {
          temp[i] = float(list[i]);
          if (Float.isNaN(temp[i])) valid = false;
        }
        
        if (valid) {
          for (int i = 0; i < min(list.length, 8); i++) {
            sensorData[i] = temp[i];
          }
        }
      }
    }
  } catch (Exception e) {
    // Ignore malformed lines to prevent spikes
  }
}

void simulateData() {
  // Realistic ECG simulation (Narrow spike at 80bpm)
  float bpmSim = 80;
  float period = (60.0/bpmSim) * 60; // frames at 60fps
  float t = frameCount % period;
  float pulse = 0;
  if (t < 5) pulse = map(t, 0, 5, 0, 400); // R-peak
  else if (t < 10) pulse = map(t, 5, 10, 400, 0);
  
  sensorData[0] = 512 + pulse + random(-5, 5); 
  sensorData[1] = 512 + sin(frameCount * 0.02) * 100; // Smoother breathing
  sensorData[2] = bpmSim; 
  sensorData[3] = 16;  
  sensorData[4] = 2000; 
  sensorData[5] = 6000; 
  sensorData[6] = 45; 
  sensorData[7] = 98;
}
