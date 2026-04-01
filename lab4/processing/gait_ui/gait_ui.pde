import processing.serial.*;

Serial myPort;
String val;
float[] sensorData = new float[10];

// Visualization components
Style style;
Heatmap heat;
RealTimeGraph fsrGraph;
RealTimeGraph accelGraph;

// Gait Analysis
float mfpValue = 0;
int stepCount = 0;
float cadence = 0;
long startTime;
boolean inStance = false;
float stanceThreshold = 100; // Adjust based on calibration
boolean inMotion = false;
float motionThreshold = 1.5; // Threshold for accelerometer magnitude differentiation

// Profile tracking
String currentProfile = "Normal";
ArrayList<Float> mfpValues = new ArrayList<Float>();

void setup() {
  size(1200, 850);
  
  // Try to connect to serial
  String[] ports = Serial.list();
  if (ports.length > 0) {
    myPort = new Serial(this, ports[0], 115200);
    myPort.bufferUntil('\n');
  }

  style = new Style();
  // Initialize components
  heat = new Heatmap(30, 80, 400, 500);
  
  String[] fsrLabels = {"MF", "LF", "MM", "HEEL"};
  fsrGraph = new RealTimeGraph(460, 80, 710, 360, 4, fsrLabels, "FSR SENSOR DATA");
  
  String[] accelLabels = {"AccX", "AccY", "AccZ"};
  accelGraph = new RealTimeGraph(460, 460, 710, 360, 3, accelLabels, "ACCELEROMETER DATA");
  
  startTime = millis();
}

void draw() {
  background(Style.BG);
  
  // Sidebar/Header background
  fill(Style.PANEL);
  noStroke();
  rect(0, 0, width, 60);
  
  // Dashboard Header
  fill(Style.ACCENT);
  textSize(24);
  textAlign(LEFT, CENTER);
  text("SMART-SOLE GAIT ANALYSIS DASHBOARD", 30, 30);
  
  // Display components
  heat.display(style);
  fsrGraph.display(style);
  accelGraph.display(style);
  
  // Gait Metrics Display
  drawMetrics();
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
      
      // Update visualizations
      heat.update(sensorData[0], sensorData[1], sensorData[2], sensorData[3]);
      
      float[] fsrs = {sensorData[0], sensorData[1], sensorData[2], sensorData[3]};
      fsrGraph.addData(fsrs);
      
      float[] accels = {sensorData[4], sensorData[5], sensorData[6]};
      accelGraph.addData(accels);
      
      // Analysis
      calculateGaitMetrics(fsrs, accels);
    }
  }
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
  } else if (inStance && totalPressure < stanceThreshold * 0.5) {
    inStance = false;
  }
  
  // Cadence (over time since start)
  float minutesPassed = (millis() - startTime) / 60000.0;
  if (minutesPassed > 0) {
    cadence = stepCount / minutesPassed;
  }
  
  // Motion Detection
  float accelMag = sqrt(sq(accels[0]) + sq(accels[1]) + sq(accels[2]));
  // Subtracting gravity (~9.8) and looking for variance
  if (abs(accelMag - 9.8) > motionThreshold) {
    inMotion = true;
  } else {
    inMotion = false;
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
  
  fill(Style.TEXT_MAIN);
  text(nf(mfpValue, 1, 1) + "%", barX + barW + 10, textY);
}
