import processing.serial.*;
import java.util.*;
import javax.swing.JOptionPane;

Serial port;
boolean serialRunning = true;

// Latest values from serial
float latestH = 0;
float latestC = 0;
float latestO = 0;

// ---------- Fitness Mode session ----------
FitnessSession session;
Button startBtn;
Button stopBtn;

// Plot area
int plotX = 100, plotY = 200, plotW, plotH;

void setup() {
  size(1100, 1200);
  surface.setTitle("Fitness Mode — Heart Rate Zones");

  plotW = width - 120;
  plotH = height - 170;

  // Ask user age once
  int age = askAge();
  int maxHR = 220 - age;
  session = new FitnessSession(maxHR);

  // Buttons
  startBtn = new Button(60, 20, 160, 34, "Start Fitness");
  stopBtn  = new Button(230, 20, 160, 34, "Stop Fitness");

  // Serial setup
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

  // Top status bar
  drawTopUI();

  // If session running, keep session timer updated
  session.tick();

  // Draw graph
  drawGraph();

  // Footer hints
  fill(20);
  textAlign(LEFT, BASELINE);
  text("Serial: press 's' to toggle reading.  Fitness: click Start/Stop.", 60, height - 12);
}

void drawTopUI() {
  // Buttons
  startBtn.draw(!session.isActive());
  stopBtn.draw(session.isActive());

  // Live readouts
  fill(20);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Live HR: " + nf(latestH, 0, 0) + " bpm", 420, 18);

  textSize(14);
  text("Oxygen: " + nf(latestO, 0, 0) + "%", 420, 40);
  text("Confidence: " + nf(latestC, 0, 0), 420, 60);

  // Session stats
  textAlign(RIGHT, TOP);
  textSize(14);
  String total = formatMs(session.getActiveMs());
  text("test Active time: " + total, width - 60, 18);

  // Time in zones (like Fig 2B)
  int y = 40;
  for (int z = 0; z < 5; z++) {
    Zone zone = Zone.fromIndex(z);
    String t = formatMs(session.getZoneMs(z));
    fill(zone.col);
    rect(width - 320, y + 4, 12, 12);
    fill(20);
    text(zone.label + ": " + t, width - 60, y);
    y += 20;
  }

  // Zone legend header
  fill(20);
  textAlign(RIGHT, TOP);
  text("Zones (time spent)", width - 60, 18);
}

void drawGraph() {
  // Frame
  stroke(200);
  noFill();
  rect(plotX, plotY, plotW, plotH);

  // Axes labels (simple)
  fill(20);
  textAlign(LEFT, TOP);
  textSize(12);
  text("Heart Rate (bpm) vs Time", plotX, plotY - 18);

  // If we have < 2 samples, show message
  if (session.samples.size() < 2) {
    fill(40);
    textAlign(LEFT, TOP);
    text("Click Start Fitness, then do jumping jacks. Click Stop when done.", plotX + 10, plotY + 10);
    return;
  }

  // Determine time window
  long t0 = session.samples.get(0).tMs;
  long t1 = session.samples.get(session.samples.size() - 1).tMs;

  // Prevent divide-by-zero
  if (t1 == t0) t1 = t0 + 1;

  // Y scaling (use a nice range)
  float minHR = session.minHRSeen();
  float maxHR = session.maxHRSeen();
  float pad = max(5, (maxHR - minHR) * 0.15);
  float yMin = max(0, minHR - pad);
  float yMax = maxHR + pad;

  // Draw HR polyline colored by zone (segment-by-segment)
  strokeWeight(3);
  for (int i = 1; i < session.samples.size(); i++) {
    Sample a = session.samples.get(i - 1);
    Sample b = session.samples.get(i);

    // Map time to x
    float ax = map(a.tMs, t0, t1, plotX, plotX + plotW);
    float bx = map(b.tMs, t0, t1, plotX, plotX + plotW);

    // Map hr to y (inverted)
    float ay = map(a.hr, yMin, yMax, plotY + plotH, plotY);
    float by = map(b.hr, yMin, yMax, plotY + plotH, plotY);

    // Color by the *current* zone (b)
    stroke(Zone.fromIndex(b.zoneIdx).col);
    line(ax, ay, bx, by);
  }

  // Draw zone bands lightly in background (optional but nice)
  drawZoneBands(t0, t1, yMin, yMax);

  // Small tick labels
  drawYAxisTicks(yMin, yMax);
  drawXAxisTicks(t0, t1);
}

void drawZoneBands(long t0, long t1, float yMin, float yMax) {
  // bands are in % maxHR:
  // 50-60 (very light), 60-70 (light), 70-80 (moderate), 80-90 (hard), 90-100 (max)
  noStroke();
  for (int z = 0; z < 5; z++) {
    Zone zone = Zone.fromIndex(z);
    float loPct = zone.loPct;
    float hiPct = zone.hiPct;

    float loHR = (loPct / 100.0) * session.maxHR;
    float hiHR = (hiPct / 100.0) * session.maxHR;

    // Map to y coords
    float yTop = map(hiHR, yMin, yMax, plotY + plotH, plotY);
    float yBot = map(loHR, yMin, yMax, plotY + plotH, plotY);

    // If off-screen, skip
    if (yBot < plotY || yTop > plotY + plotH) continue;

    // faint fill
    fill(red(zone.col), green(zone.col), blue(zone.col), 25);
    rect(plotX, yTop, plotW, yBot - yTop);
  }
}

void drawYAxisTicks(float yMin, float yMax) {
  stroke(220);
  fill(60);
  textSize(11);
  textAlign(RIGHT, CENTER);

  int ticks = 5;
  for (int i = 0; i <= ticks; i++) {
    float v = lerp(yMin, yMax, i/(float)ticks);
    float y = map(v, yMin, yMax, plotY + plotH, plotY);
    line(plotX, y, plotX + plotW, y);
    text(nf(v, 0, 0), plotX - 8, y);
  }
}

void drawXAxisTicks(long t0, long t1) {
  stroke(220);
  fill(60);
  textSize(11);
  textAlign(CENTER, TOP);

  int ticks = 5;
  for (int i = 0; i <= ticks; i++) {
    long t = (long)lerp(t0, t1, i/(float)ticks);
    float x = map(t, t0, t1, plotX, plotX + plotW);
    line(x, plotY + plotH, x, plotY + plotH + 5);

    long msFromStart = t - t0;
    text(formatMsShort(msFromStart), x, plotY + plotH + 8);
  }
}

void mousePressed() {
  if (startBtn.isClicked(mouseX, mouseY) && !session.isActive()) {
    session.start();
  }
  if (stopBtn.isClicked(mouseX, mouseY) && session.isActive()) {
    session.stop();
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') serialRunning = !serialRunning;
}

void serialEvent(Serial p) {
  if (!serialRunning) { p.clear(); return; }

  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() == 0) return;

  // Expect: "H:72,C:99,O:98"
  String[] parts = splitTokens(line, ",:");
  if (parts.length >= 6) {
    float h = float(parts[1]);
    float c = float(parts[3]);
    float o = float(parts[5]);

    latestH = h;
    latestC = c;
    latestO = o;

    // If fitness session is active, record sample
    if (session.isActive()) session.addSample(h);
  }
}

// -------------------- Small utilities --------------------

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
    if (input == null) return 20; // default if they cancel
    input = input.trim();
    try {
      int age = Integer.parseInt(input);
      if (age >= 5 && age <= 120) return age;
    } catch (Exception e) {}
  }
}

String formatMs(long ms) {
  long s = ms / 1000;
  long m = s / 60;
  long r = s % 60;
  return nf(m, 0, 0) + "m " + nf(r, 0, 0) + "s";
}

String formatMsShort(long ms) {
  long s = ms / 1000;
  long m = s / 60;
  long r = s % 60;
  return nf(m, 0, 0) + ":" + nf(r, 2, 0);
}

// -------------------- Classes --------------------

class Button {
  int x, y, w, h;
  String label;

  Button(int x, int y, int w, int h, String label) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
  }

  void draw(boolean enabled) {
    boolean hover = isInside(mouseX, mouseY);

    if (!enabled) fill(210);
    else if (hover) fill(235);
    else fill(245);

    stroke(180);
    rect(x, y, w, h, 8);

    fill(20);
    noStroke();
    textAlign(CENTER, CENTER);
    textSize(12);
    text(label, x + w/2, y + h/2);
  }

  boolean isClicked(int mx, int my) {
    return isInside(mx, my);
  }

  boolean isInside(int mx, int my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
}

class Sample {
  long tMs;
  float hr;
  int zoneIdx;

  Sample(long tMs, float hr, int zoneIdx) {
    this.tMs = tMs;
    this.hr = hr;
    this.zoneIdx = zoneIdx;
  }
}

class FitnessSession {
  int maxHR;

  boolean active = false;
  long startMs = 0;
  long stopMs = 0;

  ArrayList<Sample> samples = new ArrayList<Sample>();

  // Time in zones (ms)
  long[] zoneMs = new long[5];

  // For time accounting between samples
  long lastSampleMs = 0;
  int lastZoneIdx = 0;

  FitnessSession(int maxHR) {
    this.maxHR = maxHR;
  }

  void start() {
    active = true;
    samples.clear();
    Arrays.fill(zoneMs, 0);
    startMs = millis();
    lastSampleMs = 0;
  }

  void stop() {
    active = false;
    stopMs = millis();
    // Close out zone time up to stop moment
    if (lastSampleMs != 0) {
      long now = millis();
      zoneMs[lastZoneIdx] += (now - lastSampleMs);
    }
  }

  void tick() {
    // nothing required here besides letting draw() run
  }

  void addSample(float hr) {
    // ignore junk values
    if (hr < 20 || hr > 250) return;

    long now = millis();

    int z = zoneIndexForHR(hr);
    samples.add(new Sample(now, hr, z));

    // Update zone time using delta from previous sample
    if (lastSampleMs != 0) {
      long dt = now - lastSampleMs;
      zoneMs[lastZoneIdx] += dt;
    }
    lastSampleMs = now;
    lastZoneIdx = z;
  }

  int zoneIndexForHR(float hr) {
    float pct = (hr * 100.0) / maxHR;

    // clamp
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;

    // Based on Fig 2A:
    // Very light: 50-60
    // Light: 60-70
    // Moderate: 70-80
    // Hard: 80-90
    // Maximum: 90-100
    if (pct >= 90) return 4;
    if (pct >= 80) return 3;
    if (pct >= 70) return 2;
    if (pct >= 60) return 1;
    return 0; // 0 covers <60 too (keeps it simple)
  }

  boolean isActive() { return active; }

  long getActiveMs() {
    if (active) return millis() - startMs;
    if (startMs == 0) return 0;
    return stopMs - startMs;
  }

  long getZoneMs(int idx) {
    // While active, show “live” time including the current unfinished segment
    long t = zoneMs[idx];
    if (active && lastSampleMs != 0 && idx == lastZoneIdx) {
      t += (millis() - lastSampleMs);
    }
    return t;
  }

  float minHRSeen() {
    float m = Float.POSITIVE_INFINITY;
    for (Sample s : samples) m = min(m, s.hr);
    return (m == Float.POSITIVE_INFINITY) ? 0 : m;
  }

  float maxHRSeen() {
    float m = Float.NEGATIVE_INFINITY;
    for (Sample s : samples) m = max(m, s.hr);
    return (m == Float.NEGATIVE_INFINITY) ? 0 : m;
  }
}

enum Zone {
  VERY_LIGHT(0, "Very Light (50–60%)", 50, 60, 0xFFA0A0A0),
  LIGHT(1, "Light (60–70%)",           60, 70, 0xFF50A0FF),
  MODERATE(2, "Moderate (70–80%)",     70, 80, 0xFF46B45A),
  HARD(3, "Hard (80–90%)",             80, 90, 0xFFFFAA3C),
  MAXIMUM(4, "Maximum (90–100%)",      90, 100, 0xFFF05050);

  int idx;
  String label;
  float loPct, hiPct;
  int col;

  Zone(int idx, String label, float loPct, float hiPct, int col) {
    this.idx = idx;
    this.label = label;
    this.loPct = loPct;
    this.hiPct = hiPct;
    this.col = col;
  }

  static Zone fromIndex(int i) {
    for (Zone z : values()) if (z.idx == i) return z;
    return VERY_LIGHT;
  }
}


