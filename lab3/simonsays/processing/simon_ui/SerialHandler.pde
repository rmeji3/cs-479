// ============================================
// SerialHandler.pde - Arduino Communication
// ============================================
// Protocol: BBBBBBBBBBB,FFF\n (11 pad chars)
// Pads 0-9 = game inputs
// Pad 10 = end game button
// Flex bend = game input (index 11 internally)
// ============================================

class SerialHandler {
  PApplet parent;
  Serial port;
  String portName = "";
  boolean[] prevPadState = new boolean[11];
  boolean prevFlexBent = false;

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
      println("No Arduino found. Use mouse to test.");
      isConnected = false;
    }
  }

  void handleEvent(Serial p) {
    String line = p.readStringUntil('\n');
    if (line == null) return;
    line = line.trim();

    if (line.startsWith("SIMON") || line.startsWith("MPR121")) {
      println("Arduino: " + line);
      return;
    }

    int comma = line.indexOf(',');
    if (comma < 11) return; // need 11 pad chars

    String btnStr  = line.substring(0, 11);
    String flexStr = line.substring(comma + 1);

    // Pads 0-9: game inputs
    for (int i = 0; i < 10; i++) {
      boolean now = (btnStr.charAt(i) == '1');
      if (now && !prevPadState[i]) {
        padGrid.flashPad(i);
        game.playerInput(i);
      }
      prevPadState[i] = now;
    }

    // Pad 10: end game button
    boolean endNow = (btnStr.charAt(10) == '1');
    if (endNow && !prevPadState[10]) {
      game.startEndButton();
    }
    prevPadState[10] = endNow;

    // Flex
    try {
      int flexVal = Integer.parseInt(flexStr.trim());
      flexBar.setFlexValue(flexVal);

      boolean bent = flexBar.flexBent;
      if (bent && !prevFlexBent) {
        game.playerInput(10); // flex = input index 10 in game
      }
      prevFlexBent = bent;
    } catch (NumberFormatException e) {}
  }
}
