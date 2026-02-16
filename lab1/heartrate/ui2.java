import processing.serial.*;
import org.gicentre.utils.stat.*;   // giCentre Utils

Serial port;
boolean running = true;

// Ring buffers
final int N = 800;
float[] bufH = new float[N];   // HeartRate
float[] bufC = new float[N];   // Confidence
float[] bufO = new float[N];   // Oxygen
int idx = 0;

// Reordered arrays for plotting (newest at right)
float[] xPlot = new float[N];
float[] hPlot = new float[N];
float[] cPlot = new float[N];
float[] oPlot = new float[N];

// Charts (3 series drawn on same axes)
XYChart chartH, chartC, chartO;

// Y range tracking
float yMin = 0, yMax = 250;

void setup() {
  size(900, 460);
  surface.setTitle("Serial Multi Graph — HeartRate / Confidence / Oxygen");

  println(java.util.Arrays.toString(Serial.list()));
  String portName = null;
  for (String s : Serial.list()) {
    if (s.toLowerCase().contains("usb") || s.toLowerCase().contains("com")) {
      portName = s;
    }
  }
println("Using port:", portName);
port = new Serial(this, portName, 115200);

  // x domain 0..N-1
  for (int i = 0; i < N; i++) xPlot[i] = i;

  chartH = new XYChart(this);
  chartC = new XYChart(this);
  chartO = new XYChart(this);

  chartH.setData(xPlot, hPlot);
  chartC.setData(xPlot, cPlot);
  chartO.setData(xPlot, oPlot);

  // Axes (only one needs to show axes/labels)
  chartH.showXAxis(true);
  chartH.showYAxis(true);
  chartH.setXAxisLabel("Time (samples)");
  chartH.setYAxisLabel("Value");

  // Styles: lines only
  chartH.setPointSize(0);
  chartH.setLineColour(color(220, 60, 80));   // red
  chartH.setLineWidth(2);

  chartC.setPointSize(0);
  chartC.setLineColour(color(30, 120, 220));  // blue
  chartC.setLineWidth(2);

  chartO.setPointSize(0);
  chartO.setLineColour(color(40, 170, 90));   // green
  chartO.setLineWidth(2);

  // Fixed X range for scrolling look
  chartH.setMinX(0); chartH.setMaxX(N-1);
  chartC.setMinX(0); chartC.setMaxX(N-1);
  chartO.setMinX(0); chartO.setMaxX(N-1);
}

void draw() {
  background(252);

  // Reorder ring buffers so newest is on the right
  for (int i = 0; i < N; i++) {
    int j = (idx + i) % N;
    hPlot[i] = bufH[j];
    cPlot[i] = bufC[j];
    oPlot[i] = bufO[j];
  }

  // Update data
  chartH.setData(xPlot, hPlot);
  chartC.setData(xPlot, cPlot);
  chartO.setData(xPlot, oPlot);

  // Y range hint
  float pad = max(1, (yMax - yMin) * 0.1);
  float minY = yMin - 0.02 * pad;
  float maxY = yMax + 0.02 * pad;

  chartH.setMinY(minY); chartH.setMaxY(maxY);
  chartC.setMinY(minY); chartC.setMaxY(maxY);
  chartO.setMinY(minY); chartO.setMaxY(maxY);

  // Draw all charts on same plot area
  int plotX = 60, plotY = 30, plotW = width - 80, plotH = height - 80;
  chartH.draw(plotX, plotY, plotW, plotH);
  chartC.draw(plotX, plotY, plotW, plotH);
  chartO.draw(plotX, plotY, plotW, plotH);

  // Legend + HUD
  noStroke();
  fill(220, 60, 80); rect(plotX, 8, 12, 12);
  fill(20); text("HeartRate", plotX + 18, 18);

  fill(30, 120, 220); rect(plotX + 110, 8, 12, 12);
  fill(20); text("Confidence", plotX + 128, 18);

  fill(40, 170, 90); rect(plotX + 230, 8, 12, 12);
  fill(20); text("Oxygen", plotX + 248, 18);

  fill(20);
  text("Press 's' to start/stop. yMin=" + nf(yMin, 0, 1) + "  yMax=" + nf(yMax, 0, 1),
       plotX, height - 12);
}

void keyPressed() {
  if (key == 's' || key == 'S') running = !running;
}

void serialEvent(Serial p) {
  if (!running) { p.clear(); return; }

  String line = p.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  if (line.length() == 0) return;

  // Expect like: "H:75,C:90,O:50"
  // splitTokens with ",:" turns it into: ["H","75","C","90","O","50"]
  String[] parts = splitTokens(line, ",:");
  if (parts.length >= 6) {
    float h = float(parts[1]);
    float c = float(parts[3]);
    float o = float(parts[5]);

    bufH[idx] = h;
    bufC[idx] = c;
    bufO[idx] = o;

    idx = (idx + 1) % N;

    yMin = min(yMin, min(h, min(c, o)));
    yMax = max(yMax, max(h, max(c, o)));
  }
}
