import processing.serial.*;
import processing.sound.*;
import java.util.*;
import javax.swing.JOptionPane;

Serial port;
boolean serialRunning = true;

// Latest values
float latestH = 0;
float latestC = 0;
float latestO = 0;

// Sound for Calm mode (put ClairDeLune.mp3 in /data)
SoundFile calmSong;
long lastLiveBuzzMs = 0; // Cooldown for live buzzing
boolean pendingBuzz = false; // Flag for thread-safe buzzing

// --- App screens ---
enum Screen { HOME, FITNESS, RESTING, CALM, STRESS }
Screen screen = Screen.HOME;

// Layout
int topPanelH = 170;
int footerH   = 40;
int sidePad   = 100;

// Plot area (for screens that use graphs)
int plotX, plotY, plotW, plotH;

// Global user data
int age;
int maxHR;

// Sessions
FitnessSession fitness;
RestingHRSession resting;
CalmStressSession calm;
CalmStressSession stress;

// --- Buttons (Home) ---
Button btnResting;
Button btnFitness;
Button btnCalm;
Button btnStress;

// --- Buttons (common) ---
Button btnBack;

// Fitness buttons
Button btnFitStart, btnFitStop;

// Resting buttons
Button btnRestStart;

// Calm/Stressed buttons
Button btnCSStart, btnCSStop;

void setup() {
  size(1100, 900);
  surface.setTitle("Wearable Lab UI");

  // Plot area (used by fitness + calm/stress graphs)
  plotX = sidePad;
  plotY = topPanelH + 30;
  plotW = width - 2 * sidePad;
  plotH = 400;

  // Ask age once
  age = askAge();
  maxHR = 220 - age;

  // Sound
  calmSong = new SoundFile(this, "ClairDeLune.mp3"); // in /data

  // Sessions
  fitness = new FitnessSession(maxHR);
  resting = new RestingHRSession(30_000);        // 30s
  calm    = new CalmStressSession("Calm Mode", 60_000, true);   // 60s calm (song)
  stress  = new CalmStressSession("Stressed Mode", 60_000, false); // 60s stress

  // Home buttons
  btnResting = new Button(60, 120, 260, 44, "Resting HR (30s)");
  btnFitness = new Button(60, 180, 260, 44, "Fitness Mode");
  btnCalm    = new Button(60, 240, 260, 44, "Calm Mode (song)");
  btnStress  = new Button(60, 300, 260, 44, "Stressed Mode (60s)");

  // Common
  btnBack = new Button(60, 20, 120, 34, "Back");

  // Fitness buttons
  btnFitStart = new Button(60, 70, 160, 34, "Start Fitness");
  btnFitStop  = new Button(230, 70, 160, 34, "Stop Fitness");

  // Resting
  btnRestStart = new Button(60, 70, 240, 34, "Calculate Resting HR");

  // Calm/Stress
  btnCSStart = new Button(60, 70, 180, 34, "Start");
  btnCSStop  = new Button(250, 70, 180, 34, "Stop");

  // Serial
  println(Arrays.toString(Serial.list()));
  String portName = pickArduinoPort();
  println("Using port:", portName);

  if (portName != null) {
    port = new Serial(this, portName, 115200);
    port.clear();
    port.bufferUntil('\n');
  }
}

void draw() {
  background(252);

  // Update timers (safe to call always)
  resting.tick();
  calm.tick();
  stress.tick();

  // If calm/stress finished, finalize & possibly buzz
  if (calm.justFinished()) onCalmFinished();
  if (stress.justFinished()) onStressFinished();

  // Thread-safe buzzer check
  if (pendingBuzz) {
    if (port != null) {
      port.write('B');
      println(">>> Serial CMD Sent: B <<<");
    }
    pendingBuzz = false;
  }

  switch(screen) {
    case HOME:   drawHome(); break;
    case RESTING: drawResting(); break;
    case FITNESS: drawFitness(); break;
    case CALM:   drawCalmStress(calm); break;
    case STRESS: drawCalmStress(stress); break;
  }

  fill(20);
  textAlign(LEFT, BASELINE);
  textSize(12);
  text("Serial on/off: press 's'", 60, height - 20);
}

void drawHome() {
  textAlign(LEFT, TOP);
  fill(20);
  textSize(22);
  text("Home", 60, 30);

  textSize(14);
  text("Live HR: " + nf(latestH,0,0) + "   O2: " + nf(latestO,0,0) + "%   Conf: " + nf(latestC,0,0), 60, 70);

  float rhr = resting.getRestingHR();
  String rhrText = (rhr < 0) ? "Resting HR: — (measure first)" : ("Resting HR: " + nf(rhr,0,1) + " bpm");
  text(rhrText, 60, 95);

  btnResting.draw(true);
  btnFitness.draw(true);
  btnCalm.draw(rhr >= 0);     // require resting HR first (recommended)
  btnStress.draw(rhr >= 0);   // require resting HR first (recommended)

  fill(60);
  textSize(12);
  if (rhr < 0) text("Tip: measure Resting HR first so Calm/Stressed comparisons work.", 60, 360);
}

void drawResting() {
  btnBack.draw(true);

  fill(20);
  textAlign(LEFT, TOP);
  textSize(18);
  text("Resting HR (30s baseline)", 60, 20);

  btnRestStart.draw(!resting.isActive() && !fitness.isActive() && !calm.isActive() && !stress.isActive());

  float rhr = resting.getRestingHR();
  textSize(14);
  String rhrText = (rhr < 0) ? "Resting HR: —" : "Resting HR: " + nf(rhr, 0, 1) + " bpm";
  text(rhrText, 60, 120);

  if (resting.isActive()) {
    text("Measuring... " + resting.secondsLeft() + "s left", 60, 145);
  }

  // Tiny live line (optional)
  text("Live HR: " + nf(latestH,0,0), 60, 175);
}

void drawFitness() {
  btnBack.draw(true);

  // Top UI
  btnFitStart.draw(!fitness.isActive());
  btnFitStop.draw(fitness.isActive());

  fill(20);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Fitness Mode (zones)", 60, 20);
  textSize(14);
  text("Live HR: " + nf(latestH,0,0) + " bpm", 420, 20);

  // Right: times in zones
  textAlign(RIGHT, TOP);
  String total = formatMs(fitness.getActiveMs());
  text("Active time: " + total, width - 60, 20);
  text("Zones (time spent)", width - 60, 44);

  int y = 65;
  for (int z = 0; z < 5; z++) {
    Zone zone = Zone.fromIndex(z);
    String t = formatMs(fitness.getZoneMs(z));
    fill(zone.col);
    rect(width - 320, y + 4, 12, 12);
    fill(20);
    text(zone.label + ": " + t, width - 60, y);
    y += 20;
  }

  // Graph
  drawSessionGraph(fitness.samples, maxHR);

  // Hint
  fill(60);
  textAlign(LEFT, TOP);
  textSize(12);
  if (fitness.samples.size() < 2) {
    text("Click Start Fitness, do jumping jacks, then Stop.", plotX, plotY - 18);
  }
}

void drawCalmStress(CalmStressSession cs) {
  btnBack.draw(true);

  fill(20);
  textAlign(LEFT, TOP);
  textSize(18);
  text(cs.title, 60, 20);

  btnCSStart.draw(!cs.isActive());
  btnCSStop.draw(cs.isActive());

  float rhr = resting.getRestingHR();
  textSize(14);
  text("Resting HR: " + ((rhr < 0) ? "—" : nf(rhr,0,1) + " bpm"), 60, 120);
  text("Live HR: " + nf(latestH,0,0) + " bpm", 60, 145);

  if (cs.isActive()) {
    text("Time left: " + cs.secondsLeft() + "s", 60, 170);
  } else if (cs.hasResult()) {
    fill(20);
    text("Avg HR during session: " + nf(cs.avgHr(), 0, 1) + " bpm", 60, 170);
    text(cs.resultText(resting.getRestingHR()), 60, 195);
  }

  // Graph of that session
  drawSessionGraph(cs.samples, maxHR);

  // Little instruction text
  fill(60);
  textSize(12);
  if (cs.isCalm) text("Calm Mode: listen to the song and relax.", 60, 230);
  else text("Stressed Mode: recall a stressful event for 60 seconds.", 60, 230);
}

void drawSessionGraph(ArrayList<Sample> samples, int maxHR) {
  // Frame
  stroke(200);
  noFill();
  rect(plotX, plotY, plotW, plotH);

  fill(20);
  textAlign(LEFT, TOP);
  textSize(12);
  text("Heart Rate (bpm) vs Time", plotX, plotY - 18);

  if (samples.size() < 2) return;

  long t0 = samples.get(0).tMs;
  long t1 = samples.get(samples.size()-1).tMs;
  if (t1 == t0) t1 = t0 + 1;

  float minHR = Float.POSITIVE_INFINITY;
  float maxSeen = Float.NEGATIVE_INFINITY;
  for (Sample s : samples) {
    minHR = min(minHR, s.hr);
    maxSeen = max(maxSeen, s.hr);
  }
  float pad = max(5, (maxSeen - minHR) * 0.15);
  float yMin = max(0, minHR - pad);
  float yMax = maxSeen + pad;

  // Zone bands background
  noStroke();
  for (int z = 0; z < 5; z++) {
    Zone zone = Zone.fromIndex(z);
    float loHR = (zone.loPct / 100.0) * maxHR;
    float hiHR = (zone.hiPct / 100.0) * maxHR;

    float yTop = map(hiHR, yMin, yMax, plotY + plotH, plotY);
    float yBot = map(loHR, yMin, yMax, plotY + plotH, plotY);
    if (yBot < plotY || yTop > plotY + plotH) continue;

    fill(red(zone.col), green(zone.col), blue(zone.col), 25);
    rect(plotX, yTop, plotW, yBot - yTop);
  }

  // Colored line by zone
  strokeWeight(3);
  for (int i = 1; i < samples.size(); i++) {
    Sample a = samples.get(i-1);
    Sample b = samples.get(i);

    float ax = map(a.tMs, t0, t1, plotX, plotX + plotW);
    float bx = map(b.tMs, t0, t1, plotX, plotX + plotW);

    float ay = map(a.hr, yMin, yMax, plotY + plotH, plotY);
    float by = map(b.hr, yMin, yMax, plotY + plotH, plotY);

    stroke(Zone.fromIndex(b.zoneIdx).col);
    line(ax, ay, bx, by);
  }
}

void onCalmFinished() {
  // Stop song
  if (calmSong.isPlaying()) calmSong.stop();
}

void onStressFinished() {
  // If stress detected -> buzz twice
  float rhr = resting.getRestingHR();
  if (stress.isStressed(rhr)) {
    println("Session Finished: Stress detected! (Avg: " + nf(stress.avgHr(),0,1) + " vs Resting: " + nf(rhr,0,1) + ")");
    buzzTwice();
  } else {
    println("Session Finished: No significant stress detected.");
  }
}

void buzzTwice() {
  pendingBuzz = true;
  println(">>> BUZZER REQUESTED <<<");
}

void mousePressed() {
  if (screen == Screen.HOME) {
    if (btnResting.isClicked(mouseX, mouseY)) screen = Screen.RESTING;
    else if (btnFitness.isClicked(mouseX, mouseY)) screen = Screen.FITNESS;
    else if (btnCalm.isClicked(mouseX, mouseY) && resting.getRestingHR() >= 0) screen = Screen.CALM;
    else if (btnStress.isClicked(mouseX, mouseY) && resting.getRestingHR() >= 0) screen = Screen.STRESS;
    return;
  }

  // Back
  if (btnBack.isClicked(mouseX, mouseY)) {
    // stop any active mode when leaving
    if (fitness.isActive()) fitness.stop();
    if (resting.isActive()) resting.finish();
    if (calm.isActive()) calm.stop();
    if (stress.isActive()) stress.stop();
    if (calmSong.isPlaying()) calmSong.stop();

    screen = Screen.HOME;
    return;
  }

  // Resting screen
  if (screen == Screen.RESTING) {
    if (btnRestStart.isClicked(mouseX, mouseY) && !resting.isActive()) resting.start();
    return;
  }

  // Fitness screen
  if (screen == Screen.FITNESS) {
    if (btnFitStart.isClicked(mouseX, mouseY) && !fitness.isActive()) fitness.start();
    if (btnFitStop.isClicked(mouseX, mouseY) && fitness.isActive()) fitness.stop();
    return;
  }

  // Calm / Stress screens
  if (screen == Screen.CALM) {
    if (btnCSStart.isClicked(mouseX, mouseY) && !calm.isActive()) {
      calm.start();
      calmSong.play();
    }
    if (btnCSStop.isClicked(mouseX, mouseY) && calm.isActive()) {
      calm.stop();
      if (calmSong.isPlaying()) calmSong.stop();
    }
    return;
  }

  if (screen == Screen.STRESS) {
    if (btnCSStart.isClicked(mouseX, mouseY) && !stress.isActive()) stress.start();
    if (btnCSStop.isClicked(mouseX, mouseY) && stress.isActive()) stress.stop();
    return;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') serialRunning = !serialRunning;
  if (key == 'b' || key == 'B') {
    println("Manual buzzer test...");
    buzzTwice();
  }
}

void serialEvent(Serial p) {
  if (!serialRunning) { p.clear(); return; }

  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() == 0) return;

  String[] parts = splitTokens(line, ",:");
  if (parts.length >= 6) {
    float h = float(parts[1]);
    float c = float(parts[3]);
    float o = float(parts[5]);

    latestH = h;
    latestC = c;
    latestO = o;

    // Feed sessions that are active
    if (resting.isActive()) resting.addSample(h, c);
    if (fitness.isActive()) fitness.addSample(h);
    if (calm.isActive()) calm.addSample(h, c, maxHR);
    if (stress.isActive()) {
      stress.addSample(h, c, maxHR);
      
      // LIVE BUZZ: If current HR is significantly above resting
      float rhr = resting.getRestingHR();
      if (rhr >= 0 && (h - rhr) >= 5) { // Updated to match the user's always-buzz threshold
        if (millis() - lastLiveBuzzMs > 5000) { // Cooldown of 5 seconds
          println("Live Stress Detected: HR " + nf(h,0,0) + " (Resting: " + nf(rhr,0,0) + ")");
          buzzTwice();
          lastLiveBuzzMs = millis();
        }
      }
    }
  }
}

// Utilities
String pickArduinoPort() {
  String portName = null;
  for (String s : Serial.list()) {
    String low = s.toLowerCase();
    if (low.contains("usb") || low.contains("com")) portName = s;
  }
  return portName;
}

int askAge() {
  while (true) {
    String input = JOptionPane.showInputDialog("Enter your age (for max HR = 220 - age):");
    if (input == null) return 20;
    input = input.trim();
    try {
      int a = Integer.parseInt(input);
      if (a >= 5 && a <= 120) return a;
    } catch (Exception e) {}
  }
}

String formatMs(long ms) {
  long s = ms / 1000;
  long m = s / 60;
  long r = s % 60;
  return nf(m, 0, 0) + "m " + nf(r, 0, 0) + "s";
}

