// ─────────────────────────────────────────────────────────────────────────────
// PSCClassifier.pde
// Physiological State Classifier (PSC) + ANS State Classifier
//
// Implements the 3-step pipeline:
//   Step 1 – Per-session rolling normalization (z-score)
//   Step 2 – Short-window feature extraction (5–10 min)
//   Step 3 – Pattern mapping → classified state
//
// Also implements the ANS classifier:
//   Sympathetic vs parasympathetic dominance → 4 output modes
// ─────────────────────────────────────────────────────────────────────────────

// ── CONSTANTS ──────────────────────────────────────────────────────────────
final int PSC_WINDOW      = 600;   // ~10 min at ~1 Hz effective update rate (frames/60)
final int PSC_SHORT_WIN   = 150;   // ~5 min short window for features (frames/60 * 30)
final int PSC_SAMPLE_EVERY = 60;   // Sample every 60 frames (~1 Hz at 60 fps)

// ── RING BUFFERS (raw values, sampled at ~1 Hz) ────────────────────────────
float[] pscHR   = new float[PSC_WINDOW];
float[] pscHRV  = new float[PSC_WINDOW];
float[] pscSpO2 = new float[PSC_WINDOW];
float[] pscRR   = new float[PSC_WINDOW];  // Respiratory Rate (br/min)
int pscIdx      = 0;
int pscCount    = 0;   // How many samples collected so far

// ── CURRENT CLASSIFIED OUTPUTS ─────────────────────────────────────────────
String pscState     = "Calibrating";
String pscDesc      = "Collecting baseline data...";
color  pscColor     = color(150);

String ansState     = "Calibrating";
String ansDesc      = "";
color  ansColor     = color(150);

// ── EXTRACTED FEATURES (updated each classification cycle) ─────────────────
float featHRSlope   = 0;   // HR trend slope (z-score units / sample)
float featHRVVar    = 0;   // HRV variance
float featRRVar     = 0;   // Respiration variability
float featSpO2Stab  = 0;   // SpO2 stability (inverse of std)
float featHRHRVCorr = 0;   // HR–HRV correlation (should be negative when healthy)
float featHRVChaos  = 0;   // HRV chaos proxy: ratio of short-window var to long-window var
float featRRChaos   = 0;   // RR chaos proxy

// ── Z-SCORE NORMALIZATION BUFFERS (rolling mean & std) ─────────────────────
float zHR   = 0, zHRV = 0, zSpO2 = 0, zRR = 0;  // Most recent z-scores

// ── PUBLIC UPDATE FUNCTION ─────────────────────────────────────────────────
// Call once per draw() — internally throttles to PSC_SAMPLE_EVERY frames
void pscUpdate() {
  if (frameCount % PSC_SAMPLE_EVERY != 0) return;

  // 1. Store new sample in ring buffer
  pscHR  [pscIdx] = sensorData[2];
  pscHRV [pscIdx] = sensorData[6];
  pscSpO2[pscIdx] = sensorData[7];
  pscRR  [pscIdx] = sensorData[3];

  pscIdx = (pscIdx + 1) % PSC_WINDOW;
  if (pscCount < PSC_WINDOW) pscCount++;

  // Need at least 30 samples (~30 s) before classifying
  if (pscCount < 30) return;

  // 2. Compute rolling z-scores (whole buffer as session baseline)
  zHR   = zScore(pscHR,   pscCount);
  zHRV  = zScore(pscHRV,  pscCount);
  zSpO2 = zScore(pscSpO2, pscCount);
  zRR   = zScore(pscRR,   pscCount);

  // 3. Extract features from short window
  int swLen = min(pscCount, PSC_SHORT_WIN);
  extractFeatures(swLen);

  // 4. Classify
  classifyPSC();
  classifyANS();
}

// ── STEP 1: Z-score of the most recent value vs rolling session buffer ──────
float zScore(float[] buf, int n) {
  float mu = 0;
  int start = (pscIdx - n + PSC_WINDOW) % PSC_WINDOW;
  for (int i = 0; i < n; i++) {
    mu += buf[(start + i) % PSC_WINDOW];
  }
  mu /= n;
  float sigma = 0;
  for (int i = 0; i < n; i++) {
    float d = buf[(start + i) % PSC_WINDOW] - mu;
    sigma += d * d;
  }
  sigma = sqrt(sigma / n);
  float recent = buf[(pscIdx - 1 + PSC_WINDOW) % PSC_WINDOW];
  return (sigma > 0.001) ? (recent - mu) / sigma : 0;
}

// ── Helper: variance of last n samples from a ring buffer ──────────────────
float ringVar(float[] buf, int n) {
  int start = (pscIdx - n + PSC_WINDOW) % PSC_WINDOW;
  float mu = 0;
  for (int i = 0; i < n; i++) mu += buf[(start + i) % PSC_WINDOW];
  mu /= n;
  float v = 0;
  for (int i = 0; i < n; i++) {
    float d = buf[(start + i) % PSC_WINDOW] - mu;
    v += d * d;
  }
  return v / n;
}

// ── Helper: slope (least-squares) of last n samples from a ring buffer ──────
float ringSlope(float[] buf, int n) {
  int start = (pscIdx - n + PSC_WINDOW) % PSC_WINDOW;
  float sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (int i = 0; i < n; i++) {
    float x = i;
    float y = buf[(start + i) % PSC_WINDOW];
    sumX  += x;
    sumY  += y;
    sumXY += x * y;
    sumX2 += x * x;
  }
  float denom = n * sumX2 - sumX * sumX;
  return (abs(denom) > 0.001) ? (n * sumXY - sumX * sumY) / denom : 0;
}

// ── Helper: Pearson correlation between last n samples of two ring buffers ──
float ringCorr(float[] bufA, float[] bufB, int n) {
  int start = (pscIdx - n + PSC_WINDOW) % PSC_WINDOW;
  float muA = 0, muB = 0;
  for (int i = 0; i < n; i++) {
    muA += bufA[(start + i) % PSC_WINDOW];
    muB += bufB[(start + i) % PSC_WINDOW];
  }
  muA /= n; muB /= n;
  float num = 0, dA = 0, dB = 0;
  for (int i = 0; i < n; i++) {
    float a = bufA[(start + i) % PSC_WINDOW] - muA;
    float b = bufB[(start + i) % PSC_WINDOW] - muB;
    num += a * b;
    dA  += a * a;
    dB  += b * b;
  }
  float denom = sqrt(dA * dB);
  return (denom > 0.001) ? num / denom : 0;
}

// ── STEP 2: Extract features ────────────────────────────────────────────────
void extractFeatures(int swLen) {
  featHRSlope   = ringSlope(pscHR,   swLen);
  featHRVVar    = ringVar(pscHRV,    swLen);
  featRRVar     = ringVar(pscRR,     swLen);
  featSpO2Stab  = 1.0 / max(0.01, sqrt(ringVar(pscSpO2, swLen)));
  featHRHRVCorr = ringCorr(pscHR, pscHRV, swLen);

  float longHRVVar = ringVar(pscHRV, pscCount);
  float longRRVar  = ringVar(pscRR,  pscCount);
  featHRVChaos = (longHRVVar > 0.001) ? ringVar(pscHRV, min(swLen, 30)) / longHRVVar : 1;
  featRRChaos  = (longRRVar  > 0.001) ? ringVar(pscRR,  min(swLen, 30)) / longRRVar  : 1;
}

// ── STEP 3: Pattern mapping → PSC state ─────────────────────────────────────
void classifyPSC() {
  float hr   = sensorData[2];
  float hrv  = sensorData[6];
  float spo2 = sensorData[7];
  float resp = sensorData[3];

  if (spo2 < 93) {
    if (hr > 100) {
      setPSC("Dysregulated State",
             "O2 critically low while HR is racing — severe homeostatic failure.",
             color(200, 0, 0));
      return;
    }
    setPSC("Hypoxic Stress",
           "SpO2↓ + RR↑ pattern detected. Check airway / altitude.",
           color(255, 100, 0));
    return;
  }

  if (spo2 < 95 && zRR > 1.0) {
    setPSC("Respiratory Strain",
           "SpO2↓ + rapid breathing. Possible hyperventilation or airway strain.",
           color(100, 150, 255));
    return;
  }

  if (resp > 28 || resp < 8) {
    setPSC("Respiratory Strain",
           "Breathing frequency outside normal range (8–28 br/min).",
           color(100, 150, 255));
    return;
  }

  if (featHRVChaos > 2.5 && featRRChaos > 2.5) {
    setPSC("Autonomic Dysregulation",
           "HRV chaotic + RR chaotic — nervous system regulation is disrupted.",
           color(200, 100, 255));
    return;
  }

  if (zHR > 1.5 && spo2 < 96) {
    setPSC("Hypoxic Stress",
           "HR↑ + SpO2 declining. Monitor oxygen and slow breathing.",
           color(255, 120, 0));
    return;
  }

  if (zHR > 1.0 && zHRV < -1.0 && zRR > 0.5) {
    setPSC("Acute Stress",
           "HR↑ + HRV↓ + RR↑: strong sympathetic activation. Try box breathing.",
           color(255, 50, 50));
    return;
  }

  if (hrv < 25 && zHR < 0.5) {
    setPSC("Autonomic Imbalance",
           "Low HRV at near-resting HR — possible fatigue or vagal suppression.",
           color(220, 130, 255));
    return;
  }

  if (zHR < -0.5 && zHRV > 0.5 && zRR < 0) {
    setPSC("Recovery",
           "HR↓ + HRV↑ + RR↓: parasympathetic rebound — body is recovering well.",
           color(0, 200, 150));
    return;
  }

  if (abs(zHR) < 0.5 && abs(zHRV) < 0.8 && hrv > 45 && spo2 >= 96) {
    setPSC("Rested Stable",
           "All signals stable: HR, HRV, SpO2, RR within normal session range.",
           color(75, 175, 75));
    return;
  }

  setPSC("Indeterminate",
         "Signal patterns are mixed. Continue monitoring for clearer state.",
         color(150));
}

void setPSC(String s, String d, color c) {
  pscState = s; pscDesc = d; pscColor = c;
}

// ── ANS Classifier ──────────────────────────────────────────────────────────
void classifyANS() {
  float hrv  = sensorData[6];
  float hr   = sensorData[2];
  float resp = sensorData[3];

  float symScore = 0;
  symScore += (zHR   > 0.8)  ?  1 : (zHR   < -0.8)  ? -1 : 0;
  symScore += (zHRV  < -0.8) ?  1 : (zHRV  >  0.8)  ? -1 : 0;
  symScore += (zRR   > 0.8)  ?  1 : (zRR   < -0.8)  ? -1 : 0;
  symScore += (hrv < 30) ?  0.5 : (hrv > 60) ? -0.5 : 0;

  if (symScore >= 2) {
    setANS("Fight / Flight Mode",
           "Low HRV + high HR + rapid RR → sympathetic dominance.",
           color(255, 80, 80));
  } else if (symScore <= -2) {
    setANS("Recovery Mode",
           "High HRV + low HR + slow RR → parasympathetic dominance.",
           color(75, 200, 150));
  } else if (featHRVChaos > 2.0 || featRRChaos > 2.0) {
    setANS("Dysregulated Mode",
           "Neither sympathetic nor parasympathetic is clearly dominant.",
           color(200, 100, 255));
  } else {
    setANS("Balanced Mode",
           "Autonomic tone is balanced — no strong dominance in either branch.",
           color(100, 180, 255));
  }
}

void setANS(String s, String d, color c) {
  ansState = s; ansDesc = d; ansColor = c;
}

float pscDataReadiness() {
  return min(1.0, pscCount / 30.0);
}
