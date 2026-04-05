import processing.serial.*;

Serial myPort;
String val;
float[] sensorData = new float[10];

// Visualization components
Style style;
Heatmap heat;
RealTimeGraph fsrGraph;
RealTimeGraph accelGraph;
RecommendationEngine recEngine;
RecommendationsPanel recPanel;

// Tab Management
int activeTab = 0; // 0 = Dashboard, 1 = Recommendations
float tabHeight = 50;
float[] tabX = new float[2];
float[] tabW = new float[2];

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
  size(1200, 900);
  
  // Try to connect to serial
  String[] ports = Serial.list();
  if (ports.length > 0) {
    myPort = new Serial(this, ports[0], 115200);
    myPort.bufferUntil('\n');
  }

  style = new Style();
  // Initialize components with adjusted positions for tab bar
  heat = new Heatmap(30, 130, 400, 500);
  
  String[] fsrLabels = {"MF", "LF", "MM", "HEEL"};
  fsrGraph = new RealTimeGraph(460, 130, 710, 360, 4, fsrLabels, "FSR SENSOR DATA");
  
  String[] accelLabels = {"AccX", "AccY", "AccZ"};
  accelGraph = new RealTimeGraph(460, 510, 710, 360, 3, accelLabels, "ACCELEROMETER DATA");
  
  // Initialize recommendation system
  recEngine = new RecommendationEngine();
  recPanel = new RecommendationsPanel(450, 600, 710, 270);
  
  startTime = millis();
}

void draw() {
  background(Style.BG);
  
  // Draw header
  drawHeader();
  
  // Draw tabs
  drawTabs();
  
  // Draw content based on active tab
  if (activeTab == 0) {
    drawDashboard();
  } else {
    drawRecommendationsScreen();
  }
}

void drawHeader() {
  fill(Style.PANEL);
  noStroke();
  rect(0, 0, width, 60);
  
  fill(Style.ACCENT);
  textSize(20);
  textAlign(LEFT, CENTER);
  text("SMART-SOLE GAIT ANALYSIS", 30, 30);
}

void drawTabs() {
  float headerEnd = 60;
  float tabY = headerEnd;
  float tabAreaHeight = 50;
  
  // Background for tab area
  fill(#F0F0F0);
  rect(0, tabY, width, tabAreaHeight);
  
  // Draw divider
  stroke(#CCCCCC);
  line(0, tabY + tabAreaHeight, width, tabY + tabAreaHeight);
  
  // Tab definitions
  String[] tabNames = {"DASHBOARD", "RECOMMENDATIONS"};
  float tabSpacing = 200;
  
  for (int i = 0; i < 2; i++) {
    tabX[i] = 30 + i * tabSpacing;
    tabW[i] = 180;
    
    // Tab button background
    if (activeTab == i) {
      fill(Style.ACCENT);
    } else {
      fill(#E0E0E0);
    }
    noStroke();
    rect(tabX[i], tabY + 5, tabW[i], 40, 4);
    
    // Tab text
    if (activeTab == i) {
      fill(#FFFFFF);
    } else {
      fill(#666666);
    }
    textSize(14);
    textAlign(CENTER, CENTER);
    text(tabNames[i], tabX[i] + tabW[i]/2, tabY + 25);
  }
}

void drawDashboard() {
  // Display all dashboard components
  heat.display(style);
  fsrGraph.display(style);
  accelGraph.display(style);
  
  // Gait Metrics Display
  drawMetrics();
}

void drawRecommendationsScreen() {
  // Full screen recommendations display
  Recommendation currentRec = recEngine.getRecommendation();
  drawFullRecommendations(currentRec);
}

void drawFullRecommendations(Recommendation rec) {
  // Main container
  float margin = 40;
  float x = margin;
  float y = 120;
  float w = width - 2 * margin;
  float h = height - 160;
  
  // Background card
  fill(Style.PANEL);
  stroke(#CCCCCC);
  strokeWeight(1);
  rect(x, y, w, h, 8);
  
  // Large title
  fill(Style.ACCENT);
  textSize(36);
  textAlign(LEFT, TOP);
  text("PERSONALIZED GAIT RECOMMENDATIONS", x + 30, y + 30);
  
  // Gait pattern section
  stroke(#CCCCCC);
  line(x + 30, y + 85, x + w - 30, y + 85);
  
  fill(Style.ACCENT);
  textSize(22);
  text("Your Gait Pattern:", x + 30, y + 110);
  
  fill(Style.TEXT_MAIN);
  textSize(32);
  text(rec.title, x + 30, y + 155);
  
  // Shoe images section
  float shoeY = y + 250;
  fill(#FF9800);
  textSize(20);
  text("🥾 RECOMMENDED SHOES", x + 50, shoeY);
  
  // Display shoe images in a grid (if available)
  float imgStartY = shoeY + 45;
  float imgWidth = 100;
  float imgHeight = 100;
  float imgSpacing = 130;
  float maxImgsPerRow = 5;
  
  if (rec.shoeImages != null && rec.shoeImages.size() > 0) {
    for (int i = 0; i < min(rec.shoeImages.size(), 5); i++) {
      float imgX = x + 50 + i * imgSpacing;
      float imgY = imgStartY;
      
      // Draw placeholder/image box
      fill(#F5F5F5);
      stroke(#CCCCCC);
      strokeWeight(1);
      rect(imgX, imgY, imgWidth, imgHeight, 4);
      
      // Try to load and display image (NOTE: requires internet connection)
      try {
        PImage img = loadImage(rec.shoeImages.get(i));
        if (img != null) {
          image(img, imgX, imgY, imgWidth, imgHeight);
        } else {
          drawPlaceholderShoe(imgX, imgY, imgWidth, imgHeight);
        }
      }
      catch (Exception e) {
        drawPlaceholderShoe(imgX, imgY, imgWidth, imgHeight);
      }
      
      // Shoe name below image
      fill(Style.TEXT_MAIN);
      textSize(11);
      textAlign(LEFT, TOP);
      String shoeName = rec.shoes.get(i);
      String[] parts = split(shoeName, '(');
      text(parts[0].trim(), imgX, imgY + imgHeight + 8);
    }
  }
  
  // Exercises section
  float exerY = imgStartY + 200;
  fill(#4CAF50);
  textSize(20);
  text("🏃 RECOMMENDED EXERCISES", x + 30, exerY);
  
  fill(Style.TEXT_MAIN);
  textSize(15);
  for (int i = 0; i < rec.exercises.size(); i++) {
    text("• " + rec.exercises.get(i), x + 30, exerY + 40 + i * 35);
  }
  
  // Bottom - Tip section
  float tipY = y + h - 110;
  stroke(#FF9800);
  strokeWeight(2);
  line(x + 30, tipY, x + w - 30, tipY);
  
  fill(#FF9800);
  textSize(20);
  text("⚠️ IMPORTANT TIP", x + 30, tipY + 20);
  
  fill(Style.TEXT_MAIN);
  textSize(15);
  String[] tipLines = wrapText(rec.tip, w - 100, 15);
  for (int i = 0; i < tipLines.length; i++) {
    text(tipLines[i], x + 30, tipY + 55 + i * 25);
  }
}

void drawPlaceholderShoe(float x, float y, float w, float h) {
  // Draw a simple shoe icon placeholder
  fill(#CCCCCC);
  textSize(24);
  textAlign(CENTER, CENTER);
  text("👟", x + w/2, y + h/2);
}

String[] wrapText(String text, float maxWidth, float textSize) {
  ArrayList<String> lines = new ArrayList<String>();
  String[] words = split(text, ' ');
  String currentLine = "";
  
  pushMatrix();
  textSize(textSize);
  for (String word : words) {
    if (textWidth(currentLine + " " + word) < maxWidth) {
      currentLine += " " + word;
    } else {
      if (currentLine.length() > 0) {
        lines.add(currentLine.trim());
      }
      currentLine = word;
    }
  }
  if (currentLine.length() > 0) {
    lines.add(currentLine.trim());
  }
  popMatrix();
  
  String[] result = new String[lines.size()];
  return lines.toArray(result);
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
  
  // Analyze gait pattern for recommendations
  recEngine.analyzeGait(fsrs, mfpValue);
  
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
  float cardY = 650;
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
