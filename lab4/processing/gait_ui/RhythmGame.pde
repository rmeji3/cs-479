// ============================================================
// RhythmGame.pde  –  Step Rhythm Game (Tab: mode 2)
// ============================================================
// Beat circles fall down a lane.  Step (or click the lane)
// when a beat reaches the gold hit-zone line.
// The accelerometer Z-spike from sensorData detects each step.
// ============================================================

import processing.sound.*;

class RhythmGame {

  // ── Timing ──────────────────────────────────────────────
  int[]  bpmPresets  = {60, 80, 100, 120};
  int    bpmIndex    = 1;
  int    bpm         = 80;
  float  beatInterval;       // ms between beats
  float  beatTravelMs = 2200; // ms for a beat to travel the full lane

  boolean isPlaying  = false;
  long    gameStartTime;
  long    nextBeatTarget;    // absolute millis when next beat reaches hit-zone

  // ── Lane geometry (relative coords, inside translate(100,0)) ──
  // Content area: 0..1150 wide, 0..850 tall
  float laneX = 310, laneY = 80, laneW = 230, laneH = 690;
  float hitZoneY;            // Y of the hit-zone line

  // ── Beats ───────────────────────────────────────────────
  ArrayList<Beat> beats = new ArrayList<Beat>();

  // ── Scoring ──────────────────────────────────────────────
  int score = 0, combo = 0, maxCombo = 0;
  int perfectCount = 0, goodCount = 0, missCount = 0;
  static final int PERFECT_MS = 80;
  static final int GOOD_MS    = 150;

  // ── Hit-feedback ─────────────────────────────────────────
  String hitLabel  = "";
  color  hitColor  = 0;
  long   hitTime   = 0;
  float  hitLabelY = 0;

  // ── Visual ───────────────────────────────────────────────
  float beatFlash     = 0;   // 0..1 flashes on each beat tick
  float pendulumAngle = 0;
  float pendulumDir   = 1;

  // ── Step detection ───────────────────────────────────────
  float stepThreshold = 3.0; // m/s² deviation from 9.8G  (user-adjustable)
  boolean inStep      = false;
  long    lastStepTime = 0;
  static final long STEP_COOLDOWN_MS = 220;

  // ── Audio ────────────────────────────────────────────────
  SinOsc  tickOsc;
  boolean soundOK       = false;
  boolean tickPlaying   = false;
  long    tickStartTime = 0;

  // ── Palette ──────────────────────────────────────────────
  final color C_LANE_BG   = color(20,  20,  26 );
  final color C_HIT_ZONE  = color(255, 205, 0  );
  final color C_PERFECT   = color(255, 215, 0  );
  final color C_GOOD      = color(0,   180, 255);
  final color C_MISS      = color(255,  58,  48);
  final color C_BEAT_NEAR = color(255, 215, 0  );
  final color C_BEAT_FAR  = color(80,  130, 255);

  // ════════════════════════════════════════════════════════
  RhythmGame(PApplet parent) {
    hitZoneY = laneY + laneH - 70;
    setBPM(bpmPresets[bpmIndex]);
    initSound(parent);
  }

  void setBPM(int b) {
    bpm = b;
    beatInterval = 60000.0 / bpm;
  }

  void initSound(PApplet parent) {
    try {
      tickOsc = new SinOsc(parent);
      soundOK = true;
    } catch (Exception e) {
      println("Sound lib not found – visual-only mode.");
    }
  }

  // ════════════════════════════════════════════════════════
  //  GAME STATE
  // ════════════════════════════════════════════════════════

  void start() {
    isPlaying     = true;
    gameStartTime = millis();
    // First beat arrives at hit-zone after one full travel time
    nextBeatTarget = millis() + (long)beatTravelMs;
    beats.clear();
    score = 0; combo = 0; maxCombo = 0;
    perfectCount = 0; goodCount = 0; missCount = 0;
    hitLabel = "";
    inStep = false;
  }

  void stop() {
    isPlaying = false;
    beats.clear();
    stopTick();
  }

  // ════════════════════════════════════════════════════════
  //  UPDATE  (called from draw() every frame)
  // ════════════════════════════════════════════════════════

  void update() {
    tickTimeout();
    updatePendulum();
    beatFlash = max(0, beatFlash - 0.035);

    if (!isPlaying) return;

    long now = millis();

    // Spawn upcoming beats
    while (nextBeatTarget - now <= (long)beatTravelMs + 50) {
      beats.add(new Beat(nextBeatTarget));
      nextBeatTarget += (long)beatInterval;
    }

    // Update beat positions, tick sound, miss detection
    for (Beat b : beats) {
      float remaining = b.targetTime - now;
      // y=laneY when remaining=beatTravelMs ; y=hitZoneY when remaining=0
      b.y = hitZoneY - (remaining / beatTravelMs) * laneH;

      // Play metronome tick when beat reaches hit-zone
      if (!b.ticked && remaining <= 0 && remaining > -30) {
        b.ticked  = true;
        beatFlash = 1.0;
        playTick();
      }

      // Miss: beat passed without a step
      if (!b.hit && !b.missed && remaining < -(float)GOOD_MS) {
        b.missed = true;
        onMiss();
      }
    }

    // Prune off-screen beats
    for (int i = beats.size() - 1; i >= 0; i--) {
      if (beats.get(i).y > laneY + laneH + 80) beats.remove(i);
    }
  }

  void updatePendulum() {
    if (isPlaying) {
      float speed = map(bpm, 60, 120, 1.0, 2.4);
      pendulumAngle += speed * pendulumDir;
      if (abs(pendulumAngle) > 44) pendulumDir *= -1;
    }
  }

  // ════════════════════════════════════════════════════════
  //  ACCELEROMETER INPUT  (pass calibrated ax,ay,az)
  // ════════════════════════════════════════════════════════

  void onAccel(float ax, float ay, float az) {
    float mag = sqrt(ax*ax + ay*ay + az*az);
    float dev = abs(mag - 9.8);          // deviation from 1G
    long  now = millis();

    if (!inStep && dev > stepThreshold && (now - lastStepTime) > STEP_COOLDOWN_MS) {
      inStep       = true;
      lastStepTime = now;
      if (isPlaying) detectStep(now);
    } else if (dev < stepThreshold * 0.25) {
      inStep = false;
    }
  }

  void detectStep(long now) {
    Beat  best     = null;
    float bestErr  = Float.MAX_VALUE;

    for (Beat b : beats) {
      if (b.hit || b.missed) continue;
      float err = abs(b.targetTime - now);
      if (err < bestErr && err < 500) {
        bestErr = err;
        best    = b;
      }
    }

    if (best != null) {
      best.hit = true;
      int e    = (int)abs(best.targetTime - now);
      if      (e < PERFECT_MS) onPerfect();
      else if (e < GOOD_MS)    onGood();
      else                     onOk();
    }
  }

  // ════════════════════════════════════════════════════════
  //  SCORING
  // ════════════════════════════════════════════════════════

  void onPerfect() {
    combo++; maxCombo = max(combo, maxCombo);
    score += 100 + combo * 5;
    perfectCount++;
    setFeedback("PERFECT!", C_PERFECT);
  }

  void onGood() {
    combo++; maxCombo = max(combo, maxCombo);
    score += 60 + combo * 2;
    goodCount++;
    setFeedback("GOOD", C_GOOD);
  }

  void onOk() {
    combo = 0;
    score += 15;
    setFeedback("OK", color(100, 200, 255));
  }

  void onMiss() {
    combo = 0;
    missCount++;
    setFeedback("MISS", C_MISS);
  }

  void setFeedback(String s, color c) {
    hitLabel  = s;
    hitColor  = c;
    hitTime   = millis();
    hitLabelY = hitZoneY - 55;
  }

  // ════════════════════════════════════════════════════════
  //  AUDIO
  // ════════════════════════════════════════════════════════

  void playTick() {
    if (!soundOK) return;
    tickOsc.play(880, 0.55);
    tickPlaying   = true;
    tickStartTime = millis();
  }

  void stopTick() {
    if (soundOK && tickPlaying) { tickOsc.stop(); tickPlaying = false; }
  }

  void tickTimeout() {
    if (tickPlaying && millis() - tickStartTime > 55) stopTick();
  }

  void cleanup() { stopTick(); }

  // ════════════════════════════════════════════════════════
  //  MOUSE  (absolute coords – sidebar at 0..100)
  // ════════════════════════════════════════════════════════
  // All on-screen drawing is at translate(100,0), so
  // absolute X = relative X + 100.

  void mousePressed() {
    int mx = mouseX, my = mouseY;
    final int OFF = 100; // sidebar offset

    // ── BPM preset buttons (controls panel: relX=20, relY=80)
    float bx0 = OFF + 20 + 20, by0 = 80 + 148;
    for (int i = 0; i < bpmPresets.length; i++) {
      if (mx > bx0 + i*60 && mx < bx0 + i*60 + 54 && my > by0 && my < by0 + 34) {
        setBPM(bpmPresets[i]);
        return;
      }
    }

    // ── Start / Stop
    float startX = OFF + 20 + 20, startY = 80 + 196;
    if (mx > startX && mx < startX + 220 && my > startY && my < startY + 50) {
      if (isPlaying) stop(); else start();
      return;
    }

    // ── Sensitivity  – Less  (buttons now at cy+548 to avoid overlap with bar)
    float sensX = OFF + 20 + 20, sensY = 80 + 548;
    if (mx > sensX && mx < sensX + 105 && my > sensY && my < sensY + 30) {
      stepThreshold = max(0.5, stepThreshold - 0.5);
      return;
    }
    // ── Sensitivity  – More
    if (mx > sensX + 115 && mx < sensX + 220 && my > sensY && my < sensY + 30) {
      stepThreshold = min(15.0, stepThreshold + 0.5);
      return;
    }

    // ── Click lane = manual step (for testing without hardware)
    if (mx > OFF + laneX && mx < OFF + laneX + laneW && my > laneY && my < laneY + laneH) {
      if (isPlaying) detectStep(millis());
      return;
    }
  }

  // ════════════════════════════════════════════════════════
  //  DISPLAY
  // ════════════════════════════════════════════════════════

  void display(Style s) {
    // Header bar (mirrors other modes)
    fill(Style.PANEL);
    noStroke();
    rect(0, 0, width - 100, 60);

    fill(Style.ACCENT);
    textSize(24);
    textAlign(LEFT, CENTER);
    text("STEP RHYTHM GAME", 30, 30);

    // Right-hand mode label
    fill(Style.TEXT_DIM);
    textSize(12);
    textAlign(RIGHT, CENTER);
    text("GUITAR HERO  |  WITH YOUR FEET", width - 130, 30);

    drawControlsPanel(s);
    drawBeatLane();
    drawScorePanel(s);
    drawInstructions(s);
  }

  // ── LEFT PANEL  (controls + pendulum) ──────────────────

  void drawControlsPanel(Style s) {
    float cx = 20, cy = 80, cw = 260, ch = 690;
    s.card(cx, cy, cw, ch, "CONTROLS");

    // BPM display
    fill(Style.TEXT_DIM);
    textSize(11);
    textAlign(CENTER, TOP);
    text("TEMPO", cx + cw/2, cy + 65);

    fill(Style.ACCENT);
    textSize(38);
    textAlign(CENTER, TOP);
    text(bpm + " BPM", cx + cw/2, cy + 78);

    // BPM preset buttons  (4 buttons, 54px wide, 6px gap)
    for (int i = 0; i < bpmPresets.length; i++) {
      boolean active = (bpm == bpmPresets[i]);
      s.button(cx + 20 + i*60, cy + 148, 54, 34, str(bpmPresets[i]),
               Style.ACCENT, active, 100);
    }

    // Start / Stop
    color btnCol = isPlaying ? Style.RED : Style.GREEN;
    s.button(cx + 20, cy + 196, 220, 50,
             isPlaying ? "STOP" : "START", btnCol, false, 100);

    // Pendulum
    drawPendulum(cx + cw/2, cy + 340, 70);

    // Beat-flash dot
    noStroke();
    fill(C_HIT_ZONE, beatFlash * 220);
    float br = 14 + beatFlash * 12;
    ellipse(cx + cw/2, cy + 440, br*2, br*2);
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(CENTER, TOP);
    text("BEAT", cx + cw/2, cy + 458);

    // Step sensitivity
    fill(Style.TEXT_DIM);
    textSize(11);
    textAlign(LEFT, TOP);
    text("STEP SENSITIVITY", cx + 20, cy + 490);

    // Sensitivity bar (more = more sensitive = lower threshold)
    float barX = cx + 20, barY = cy + 508, barW = cw - 40, barH = 10;
    fill(Style.DARK);
    rect(barX, barY, barW, barH, 5);
    float fill_w = map(stepThreshold, 15.0, 0.5, 0, barW);
    fill(Style.ACCENT);
    rect(barX, barY, fill_w, barH, 5);

    fill(Style.TEXT_MAIN);
    textSize(12);
    textAlign(CENTER, TOP);
    text("Threshold: " + nf(stepThreshold, 1, 1) + " m/s2", cx + cw/2, cy + 524);

    // Buttons BELOW the text (no overlap with bar at cy+508)
    s.button(cx + 20, cy + 548, 105, 30, "- Less",  100, false, 100);
    s.button(cx + 135, cy + 548, 105, 30, "+ More", 100, false, 100);

    // Sound status
    noStroke();
    fill(soundOK ? Style.GREEN : Style.RED);
    textSize(11);
    textAlign(CENTER, TOP);
    text(soundOK ? "Audio: ON" : "Audio: OFF  (install Sound lib)",
         cx + cw/2, cy + 592);

    // Hint
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(CENTER, TOP);
    text("Click the lane to simulate a step", cx + cw/2, cy + 614);
    text("(useful without hardware)", cx + cw/2, cy + 628);

    // Calibration reminder
    if (!isPlaying) {
      fill(color(255,165,0));
      textSize(10);
      text("Tip: Press 'C' to calibrate accel first", cx + cw/2, cy + 650);
    }
  }

  void drawPendulum(float cx, float cy, float arm) {
    float ang = radians(pendulumAngle);
    float bx  = cx + sin(ang) * arm;
    float by  = cy + cos(ang) * arm;

    stroke(Style.TEXT_DIM);
    strokeWeight(2);
    line(cx, cy, bx, by);
    noStroke();

    // Bob: gold when beat is close
    color bobCol = (beatFlash > 0.6 && isPlaying) ? C_HIT_ZONE : (isPlaying ? Style.ACCENT : Style.DARK);
    fill(bobCol);
    ellipse(bx, by, 18, 18);

    // Pivot dot
    fill(Style.TEXT_DIM);
    ellipse(cx, cy, 8, 8);
    strokeWeight(1);
  }

  // ── CENTER  (beat lane) ─────────────────────────────────

  void drawBeatLane() {
    // Outer shadow
    noStroke();
    for (int i = 4; i > 0; i--) {
      fill(0, 0, 0, 12);
      rect(laneX - i*3, laneY - i*3, laneW + i*6, laneH + i*6, 14 + i);
    }

    // Lane background
    fill(C_LANE_BG);
    rect(laneX, laneY, laneW, laneH, 10);

    // Subtle guide lines
    stroke(45, 45, 58);
    strokeWeight(1);
    for (int i = 1; i < 4; i++) {
      float gy = laneY + i * (laneH / 4.0);
      line(laneX + 18, gy, laneX + laneW - 18, gy);
    }
    noStroke();

    // Top beat-spawn flash
    if (beatFlash > 0.02) {
      fill(C_HIT_ZONE, beatFlash * 90);
      rect(laneX, laneY, laneW, 8, 10);
    }

    // Draw each beat
    for (Beat b : beats) {
      if (b.y < laneY - 40 || b.y > laneY + laneH + 60) continue;
      drawBeat(b);
    }

    // Hit-zone glow (pulsing)
    float pulse = 18 + 8 * sin(frameCount * 0.09);
    fill(C_HIT_ZONE, 22 + 10 * sin(frameCount * 0.09));
    rect(laneX, hitZoneY - pulse, laneW, pulse * 2);

    // Hit-zone line
    stroke(C_HIT_ZONE);
    strokeWeight(3);
    line(laneX + 10, hitZoneY, laneX + laneW - 10, hitZoneY);
    noStroke();

    // Side arrows
    fill(C_HIT_ZONE, 200);
    triangle(laneX + 2,  hitZoneY - 8, laneX + 2,  hitZoneY + 8, laneX + 13, hitZoneY);
    triangle(laneX + laneW - 2, hitZoneY - 8, laneX + laneW - 2, hitZoneY + 8, laneX + laneW - 13, hitZoneY);

    // Hit zone center marker: two small downward triangles (like feet)
    float mx = laneX + laneW / 2;
    fill(C_HIT_ZONE, 180);
    triangle(mx - 18, hitZoneY - 7, mx - 4,  hitZoneY - 7, mx - 11, hitZoneY + 5);
    triangle(mx + 4,  hitZoneY - 7, mx + 18, hitZoneY - 7, mx + 11, hitZoneY + 5);

    // Floating hit feedback
    if (millis() - hitTime < 650) {
      float prog  = (millis() - hitTime) / 650.0;
      float alpha = 255 * (1 - prog);
      float yOff  = -45 * prog;
      fill(red(hitColor), green(hitColor), blue(hitColor), alpha);
      textSize(19);
      textAlign(CENTER, CENTER);
      text(hitLabel, laneX + laneW / 2, hitLabelY + yOff);
    }

    // "Paused" overlay
    if (!isPlaying) {
      fill(C_LANE_BG, 165);
      rect(laneX, laneY, laneW, laneH, 10);
      fill(255, 210);
      textAlign(CENTER, CENTER);
      textSize(15);
      text("Press START\nto play", laneX + laneW / 2, laneY + laneH / 2);
    }
  }

  void drawBeat(Beat b) {
    noStroke();
    if (b.hit) {
      // Hit burst
      fill(50, 220, 100, 170);
      rect(laneX + 18, b.y - 14, laneW - 36, 28, 14);
    } else if (b.missed) {
      fill(C_MISS, 100);
      rect(laneX + 18, b.y - 14, laneW - 36, 28, 14);
    } else {
      float t = constrain((b.y - laneY) / laneH, 0, 1);
      color bc = lerpColor(C_BEAT_FAR, C_BEAT_NEAR, t);
      fill(bc);
      rect(laneX + 18, b.y - 14, laneW - 36, 28, 14);

      // Inner label
      fill(255, 200);
      textSize(11);
      textAlign(CENTER, CENTER);
      text("STEP", laneX + laneW / 2, b.y);
    }
  }

  // ── RIGHT PANEL  (score) ────────────────────────────────

  void drawScorePanel(Style s) {
    float sx = laneX + laneW + 30, sy = 80, sw = 260, sh = 690;
    s.card(sx, sy, sw, sh, "SCORE");

    // Big score
    fill(Style.ACCENT);
    textSize(50);
    textAlign(CENTER, TOP);
    text(score, sx + sw/2, sy + 62);

    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(CENTER, TOP);
    text("POINTS", sx + sw/2, sy + 118);

    // Combo
    if (combo >= 2) {
      fill(C_PERFECT);
      textSize(22);
      textAlign(CENTER, TOP);
      text("x" + combo + " COMBO", sx + sw/2, sy + 138);
      // Sparkle
      fill(C_PERFECT, 40 + 30*sin(frameCount*0.35));
      ellipse(sx + sw/2, sy + 152, 80 + 8*sin(frameCount*0.2), 20);
    }

    // Divider
    stroke(Style.DARK);
    strokeWeight(1);
    line(sx + 18, sy + 172, sx + sw - 18, sy + 172);
    noStroke();

    // Judgment rows
    drawJudgRow(sx + 18, sy + 188, sw - 36, "PERFECT", perfectCount, C_PERFECT);
    drawJudgRow(sx + 18, sy + 248, sw - 36, "GOOD",    goodCount,    C_GOOD);
    drawJudgRow(sx + 18, sy + 308, sw - 36, "MISS",    missCount,    C_MISS);

    stroke(Style.DARK);
    line(sx + 18, sy + 372, sx + sw - 18, sy + 372);
    noStroke();

    // ── Bottom section: accuracy ring + grade + max combo ──
    int total = perfectCount + goodCount + missCount;
    float acc = total > 0 ? (perfectCount + goodCount) * 100.0 / total : 0;

    // Accuracy ring (centered in panel)
    float ringX = sx + sw / 2, ringY = sy + 450;
    drawAccRing(ringX, ringY, 50, acc);

    // Accuracy % inside ring
    color accCol = acc > 90 ? C_PERFECT : (acc > 70 ? C_GOOD : C_MISS);
    fill(accCol);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(nf(acc, 1, 1) + "%", ringX, ringY - 5);
    fill(Style.TEXT_DIM);
    textSize(9);
    textAlign(CENTER, CENTER);
    text("ACCURACY", ringX, ringY + 11);

    // Grade badge – bottom left of ring, well clear of it
    String grade = acc >= 95 ? "S" : (acc >= 85 ? "A" : (acc >= 70 ? "B" : (acc >= 50 ? "C" : "D")));
    color  gCol  = acc >= 95 ? C_PERFECT : (acc >= 85 ? C_GOOD : (acc >= 70 ? color(80,200,80) : Style.TEXT_DIM));
    // Draw grade pill background
    noStroke();
    fill(gCol, 25);
    rect(sx + 18, sy + 510, 60, 44, 8);
    fill(gCol);
    textSize(36);
    textAlign(CENTER, CENTER);
    text(grade, sx + 48, sy + 532);

    // Max combo – right of grade pill
    fill(Style.TEXT_DIM);
    textSize(10);
    textAlign(LEFT, TOP);
    text("MAX COMBO", sx + 92, sy + 516);
    fill(Style.TEXT_MAIN);
    textSize(24);
    text(maxCombo, sx + 92, sy + 530);

    // Elapsed time – bottom center
    if (isPlaying) {
      long secs = (millis() - gameStartTime) / 1000;
      fill(Style.TEXT_DIM);
      textSize(11);
      textAlign(CENTER, TOP);
      text((secs/60) + ":" + nf((int)(secs%60), 2), sx + sw/2, sy + 570);
    }
  }

  void drawJudgRow(float x, float y, float w, String label, int count, color c) {
    // Color dot
    noStroke();
    fill(c);
    ellipse(x + 6, y + 20, 11, 11);

    fill(Style.TEXT_DIM);
    textSize(11);
    textAlign(LEFT, TOP);
    text(label, x + 18, y + 12);

    fill(c);
    textSize(22);
    text(count, x + 18, y + 26);

    // Mini count-bar
    float maxC  = max(1, perfectCount + goodCount + missCount);
    float barW  = map(count, 0, maxC, 0, w - 80);
    fill(c, 35);
    rect(x + 78, y + 32, w - 80, 7, 4);
    fill(c, 190);
    rect(x + 78, y + 32, barW, 7, 4);
  }

  void drawAccRing(float cx, float cy, float r, float pct) {
    stroke(Style.DARK);
    strokeWeight(7);
    noFill();
    arc(cx, cy, r*2, r*2, -HALF_PI, -HALF_PI + TWO_PI, OPEN);

    color ac = pct > 90 ? C_PERFECT : (pct > 70 ? C_GOOD : C_MISS);
    stroke(ac);
    if (pct > 0) arc(cx, cy, r*2, r*2, -HALF_PI, -HALF_PI + radians(pct * 3.6), OPEN);
    noStroke();
  }

  // ── FAR RIGHT  (how-to-play) ────────────────────────────

  void drawInstructions(Style s) {
    float ix = laneX + laneW + 30 + 260 + 20;
    float iy = 80, iw = width - 100 - ix - 20, ih = 690;
    if (iw < 100) return;  // not enough room, skip

    s.card(ix, iy, iw, ih, "HOW TO PLAY");

    float tx = ix + 18, ty = iy + 68;
    float lh = 22;

    fill(Style.TEXT_MAIN);
    textSize(13);
    textAlign(LEFT, TOP);

    text("Beats fall from the top of", tx, ty);           ty += lh;
    text("the lane toward the gold line.", tx, ty);       ty += lh * 1.6;
    text("Step when a beat reaches", tx, ty);             ty += lh;
    text("the gold hit zone at the bottom.", tx, ty);     ty += lh * 1.6;
    text("The accelerometer in your", tx, ty);            ty += lh;
    text("smart sole detects the impact", tx, ty);        ty += lh;
    text("and scores each step.", tx, ty);                ty += lh * 1.5;

    // Tips list – right under the instructions
    fill(Style.HOVER);
    rect(tx, ty, iw - 36, 100, 8);
    fill(Style.TEXT_DIM);
    textSize(11);
    text("Tips:", tx + 10, ty + 10);
    fill(Style.TEXT_MAIN);
    text("- Press 'C' to calibrate accel first", tx + 10, ty + 28);
    text("- Click the lane if no hardware", tx + 10, ty + 44);
    text("- Adjust sensitivity if steps miss", tx + 10, ty + 60);
    text("- Lower threshold = more sensitive", tx + 10, ty + 76);
    ty += 116;

    // Divider
    stroke(Style.DARK);
    strokeWeight(1);
    line(tx, ty, tx + iw - 36, ty);
    noStroke();
    ty += 14;

    // Judgment guide at the bottom
    drawJudgeGuide(tx, ty, iw - 36);
  }

  void drawJudgeGuide(float x, float y, float w) {
    color[] cols   = {C_PERFECT, C_GOOD, C_MISS};
    String[] labs  = {"PERFECT", "GOOD", "MISS"};
    String[] times = {"< " + PERFECT_MS + " ms", "< " + GOOD_MS + " ms", "> " + GOOD_MS + " ms"};
    int[] pts      = {100, 60, 0};

    for (int i = 0; i < 3; i++) {
      float ry = y + i * 36;
      noStroke();
      fill(cols[i], 30);
      rect(x, ry, w, 30, 6);
      fill(cols[i]);
      ellipse(x + 10, ry + 15, 10, 10);
      fill(cols[i]);
      textSize(13);
      textAlign(LEFT, CENTER);
      text(labs[i], x + 22, ry + 15);
      fill(Style.TEXT_DIM);
      textSize(11);
      textAlign(RIGHT, CENTER);
      text(times[i] + "  +" + pts[i] + "pts", x + w - 8, ry + 15);
    }
  }
}

// ════════════════════════════════════════════════════════════
//  Beat data class
// ════════════════════════════════════════════════════════════

class Beat {
  long    targetTime; // absolute millis when beat should reach hit-zone
  float   y;
  boolean hit    = false;
  boolean missed = false;
  boolean ticked = false;

  Beat(long t) { targetTime = t; }
}
