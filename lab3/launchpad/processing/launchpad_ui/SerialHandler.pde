// ============================================
// SerialHandler.pde - Arduino Communication
// ============================================

class SerialHandler {
  PApplet parent;
  Serial port;
  String portName = "";

  SerialHandler(PApplet parent) {
    this.parent = parent;
  }

  void connect() {
    String[] ports = Serial.list();
    println("--- Available Serial Ports ---");
    for (int i = 0; i < ports.length; i++) {
      println("  [" + i + "] " + ports[i]);
    }

    for (String p : ports) {
      if (p.contains("cu.usbmodem") || p.startsWith("COM")) {
        portName = p;
        break;
      }
    }

    if (!portName.equals("")) {
      try {
        port = new Serial(parent, portName, 115200);
        port.bufferUntil('\n');
        isConnected = true;
        println("Connected to: " + portName);
      } catch (Exception e) {
        println("ERROR: Could not connect to " + portName);
        isConnected = false;
      }
    } else {
      println("No Arduino found. Use mouse to test UI.");
      isConnected = false;
    }
  }

  void handleEvent(Serial p) {
    String line = p.readStringUntil('\n');
    if (line == null) return;
    line = line.trim();

    if (line.startsWith("LAUNCHPAD") || line.startsWith("MPR121")) {
      println("Arduino: " + line);
      return;
    }

    int comma = line.indexOf(',');
    if (comma < 10) return;

    String btnStr  = line.substring(0, 10);
    String flexStr = line.substring(comma + 1);

    // Update pads
    for (int i = 0; i < 10; i++) {
      boolean nowPressed = (btnStr.charAt(i) == '1');
      boolean wasPressed = padGrid.isPadPressed(i);

      padGrid.setPadState(i, nowPressed);

      if (nowPressed && !wasPressed) {
        soundManager.play(i);
        loopRecorder.recordPad(i);
      }
    }

    // Update loop recorder with flex value
    try {
      int flexVal = Integer.parseInt(flexStr.trim());
      loopRecorder.updateFlex(flexVal);
    } catch (NumberFormatException e) {
      // ignore
    }
  }
}
