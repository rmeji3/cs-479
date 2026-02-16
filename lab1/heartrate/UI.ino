// import processing.serial.*;

// Serial myPort;

// int heartRate = 0;
// int spo2 = 0;
// int confidence = 0;

// ArrayList<Integer> history = new ArrayList<Integer>(); //port, heartrate, spo2, confidence, history

// void setup() {
//   size(900, 600);
//   background(20);

//   println(Serial.list()); // Find your COM port index

//   myPort = new Serial(this, Serial.list()[0], 115200);
//   myPort.bufferUntil('\n'); 
// }

// void draw() {
//   background(20);

//   drawDashboard();
//   drawChart();
// }

// void serialEvent(Serial p) {
//   String data = p.readStringUntil('\n'); //read "78,89,45 \n"
//   if (data != null) {
//     data = trim(data);
//     String[] values = split(data, ',');

//     if (values.length == 3) {
//       heartRate = int(values[0]);
//       spo2 = int(values[1]);
//       confidence = int(values[2]);

//       history.add(heartRate); //add to history
//       if (history.size() > 200) {
//         history.remove(0);
//       }
//     }
//   }
// }

// void drawDashboard() {
//   fill(255);
//   textSize(32);
//   text("Heart Rate: " + heartRate + " BPM", 50, 80);
//   text("SpO2: " + spo2 + "%", 50, 120);
//   text("Confidence: " + confidence + "%", 50, 160);

//   drawZone();
// }

// void drawZone() {
//   int age = 21; // change to input later
//   float maxHR = 220 - age;
//   float percent = (heartRate / maxHR) * 100;

//   String zone = "";
//   color zoneColor;

//   if (percent < 50) {
//     zone = "Rest";
//     zoneColor = color(0, 150, 255);
//   } else if (percent < 70) {
//     zone = "Moderate";
//     zoneColor = color(0, 255, 0);
//   } else if (percent < 85) {
//     zone = "Intense";
//     zoneColor = color(255, 165, 0);
//   } else {
//     zone = "Maximum";
//     zoneColor = color(255, 0, 0);
//   }

//   fill(zoneColor);
//   textSize(28);
//   text("Zone: " + zone, 50, 220);
// }

// void drawChart() {
//   stroke(255);
//   noFill();

//   beginShape();
//   for (int i = 0; i < history.size(); i++) {
//     float x = map(i, 0, 200, 0, width);
//     float y = map(history.get(i), 40, 180, height - 50, 250);
//     vertex(x, y);
//   }
//   endShape();
// }

