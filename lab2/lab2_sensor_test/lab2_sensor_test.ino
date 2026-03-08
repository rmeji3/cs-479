/*
 * Lab 2: Wearable Chest Strap (ECG & Respiration)
 * 
 * Hardware: FireBeetle 328P, AD8232 (ECG), FSR (Respiration)
 * Pins: ECG Output (A0), FSR (A1/S1), LO+ (10), LO- (11)
 * 
 * Requirements:
 * - Calculate Heart Rate (BPM)
 * - Calculate Respiratory Rate
 * - Calculate Inhalation & Exhalation periods
 */

// Pins
const int ad8232LOPlus = 10;
const int ad8232LOMinus = 11;
const int ad8232Output = A0;
const int fsrPin = A1; 
const int ledPin = 13; // Red LED for stress indicator

// Median Filter Buffers (Increased to 5 for better spike rejection)
int ecgM[5] = {512, 512, 512, 512, 512};
int fsrM[5] = {512, 512, 512, 512, 512};
int mIdx = 0;

// Timing & Sampling
unsigned long lastSampleTime = 0;
const int sampleInterval = 10; // 100Hz sampling (10ms)

// ECG / Heart Rate Variables
int ecgThreshold = 600;       // LOWERED: Baseline is ~450, so 600 should catch the peak
unsigned long lastBeatTime = 0;
int bpm = 0;
bool beatDetected = false;
const int bpmAvgSize = 5;     
int beatIntervals[bpmAvgSize];
int beatIndex = 0;

// FSR / Respiration Variables
int fsrUpperThreshold = 850;  
int fsrLowerThreshold = 700;  
unsigned long startInhaleTime = 0;
unsigned long startExhaleTime = 0;
unsigned long lastInhaleStartTime = 0; // Debounce for rate
unsigned long inhaleDuration = 0;
unsigned long exhaleDuration = 0;
float respirationRate = 0;
bool isInhaling = false;

// Auto-Calibration Variables
bool isCalibrating = true;
unsigned long calibrationStartTime = 0;
int calibMin = 1024;
int calibMax = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial); 

  pinMode(ad8232LOPlus, INPUT);
  pinMode(ad8232LOMinus, INPUT);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
  
  Serial.println("--- SYSTEM START: Lab 2 Sensor Test ---");
  calibrationStartTime = millis(); // Start auto-calib on boot
  delay(1000);
}

void loop() {
  unsigned long currentTime = millis();

  // Handle Calibration Command from Processing
  if (Serial.available() > 0) {
    char cmd = Serial.read();
      if (cmd == 'c') {
        isCalibrating = true;
        calibrationStartTime = currentTime;
        calibMin = 1024;
        calibMax = 0;
      } else if (cmd == 'S') {
        digitalWrite(ledPin, HIGH); // Stress detected: LED ON
      } else if (cmd == 'N') {
        digitalWrite(ledPin, LOW);  // Calm detected: LED OFF
      }
    }

  // Maintain a consistent sampling rate (100Hz)
  if (currentTime - lastSampleTime >= sampleInterval) {
    lastSampleTime += sampleInterval; // Fixed-interval timing (prevents drift/bursts)

    // --- 1. SENSOR READINGS WITH 5-POINT MEDIAN ---
    int rawValue = analogRead(ad8232Output);
    int rawFsr = analogRead(fsrPin);

    // a. Store in 5-sample buffer
    ecgM[mIdx] = rawValue;
    fsrM[mIdx] = rawFsr;
    mIdx = (mIdx + 1) % 5;

    // b. Calculate 5-point Median (Extremely robust against bursts of noise)
    int ecgMedian = getMedian5(ecgM);
    int fsrMedian = getMedian5(fsrM);

    // c. Adaptive Low-Pass (Alpha)
    static float ecgFiltered = -1.0; 
    if (ecgFiltered < 0) ecgFiltered = ecgMedian; 
    // Chase R-peaks quickly, but slow down for everything else
    float ecgAlpha = (abs(ecgMedian - (int)ecgFiltered) < 150) ? 0.2 : 0.1;
    ecgFiltered = (ecgAlpha * ecgMedian) + ((1.0 - ecgAlpha) * ecgFiltered);
    int ecgRaw = (int)ecgFiltered;
    
    static float fsrFiltered = -1.0;
    if (fsrFiltered < 0) fsrFiltered = fsrMedian; 
    float fsrAlpha = 0.1; // Smoother respiration
    fsrFiltered = (fsrAlpha * fsrMedian) + ((1.0 - fsrAlpha) * fsrFiltered);
    int fsrRaw = (int)fsrFiltered;

    // --- 2. AUTO-CALIBRATION LOGIC ---
    static int ecgMax = 0;
    if (isCalibrating) {
      if (currentTime - calibrationStartTime < 10000) {
        if (fsrRaw > calibMax) calibMax = fsrRaw;
        if (fsrRaw < calibMin) calibMin = fsrRaw;
        if (ecgRaw > ecgMax) ecgMax = ecgRaw;
        
        // Flash LED or Send status to Processing
        static int fCount = 0;
        //if (fCount++ % 30 == 0) Serial.println("DEBUG:CALIBRATING");
      } else {
        isCalibrating = false;
        
        // Calibrate Respiration
        int range = calibMax - calibMin;
        if (range > 50) { 
          fsrUpperThreshold = calibMin + (range * 0.75); // Inhale Trigger
          fsrLowerThreshold = calibMin + (range * 0.35); // Exhale Trigger
        }
        
        // Calibrate ECG (Set threshold to 85% of max peak)
        if (ecgMax > 550) {
            ecgThreshold = ecgMax * 0.85;
        }
        ecgMax = 0; // Reset for next time
      }
    }

    // --- 3. HEART RATE CALCULATION ---
    // Detect R-peak (Spike above threshold)
    // Refractory period increased to 500ms (max 120 BPM) 
    // If you are exercising and hit >120 BPM, lower this to 400 or 300.
    if (ecgRaw > ecgThreshold && !beatDetected && (currentTime - lastBeatTime > 500)) {
      unsigned long beatInterval = currentTime - lastBeatTime;
      lastBeatTime = currentTime;
      beatDetected = true;

      // Calculate instantaneous BPM
      int rawBpm = 60000 / beatInterval;

      // BPM Outlier Guard: If heart rate jumps > 40% in one beat, it's likely noise
      bool isLeap = (bpm > 0 && abs(rawBpm - bpm) > (bpm * 0.4));
      
      if (!isLeap || rawBpm < 220) {
        beatIntervals[beatIndex] = rawBpm;
        beatIndex = (beatIndex + 1) % bpmAvgSize;

        long sum = 0;
        for (int i = 0; i < bpmAvgSize; i++) sum += beatIntervals[i];
        bpm = sum / bpmAvgSize;
      }

    } else if (ecgRaw < (ecgThreshold - 60)) {
      beatDetected = false;
    }

    // --- 4. RESPIRATORY RATE CALCULATION ---
    // Inhalation: FSR value rising (strap tightening)
    // Added a 1.5s lockout (lastInhaleStartTime) to prevent "double counting"
    if (fsrRaw > fsrUpperThreshold && !isInhaling && (currentTime - lastInhaleStartTime > 1500)) {
      if (startExhaleTime > 0) {
        exhaleDuration = currentTime - startExhaleTime;
        // Total breath time = Inhale + Exhale
        float totalBreathTime = (float)(currentTime - lastInhaleStartTime) / 1000.0;
        if (totalBreathTime > 0) {
          respirationRate = 60.0 / totalBreathTime;
        }
      }
      startInhaleTime = currentTime;
      lastInhaleStartTime = currentTime;
      isInhaling = true;
    } 
    // Exhalation: FSR value falling (strap loosening)
    else if (fsrRaw < fsrLowerThreshold && isInhaling) {
      inhaleDuration = currentTime - startInhaleTime;
      startExhaleTime = currentTime;
      isInhaling = false;
    }

    // --- 4. SERIAL OUTPUT FOR PROCESSING ---
    if (digitalRead(ad8232LOPlus) == HIGH || digitalRead(ad8232LOMinus) == HIGH) {
      // In Leads-Off state, the ECG value is usually just noise/railed.
      // We send a specific flag or just 0s so the UI can detect it.
      Serial.print(0);                Serial.print(","); // ECG 0
      Serial.print(fsrRaw);           Serial.print(","); // FSR still works
      Serial.print(0);                Serial.print(","); // BPM 0
      Serial.print(respirationRate, 1); Serial.print(","); 
      Serial.print(inhaleDuration);   Serial.print(",");
      Serial.println(exhaleDuration);
      
      // Optional: Print a human-readable message to Serial for debugging (Comment out for Processing)
      // Serial.println("--- LEADS OFF detected ---");
    } else {
      Serial.print(ecgRaw);           Serial.print(",");
      Serial.print(fsrRaw);           Serial.print(",");
      Serial.print(bpm);              Serial.print(",");
      Serial.print(respirationRate, 1); Serial.print(","); 
      Serial.print(inhaleDuration);   Serial.print(",");
      Serial.println(exhaleDuration);
    }
  }
}

// ── HELPER: 5-POINT MEDIAN ─────────────────────────────────────────────────
// Performs a simple insertion sort on a local copy to return the central value
int getMedian5(int* p) {
  int sortBuf[5];
  for (int i=0; i<5; i++) sortBuf[i] = p[i];
  
  // Minimal Sort
  for (int i = 1; i < 5; i++) {
    int key = sortBuf[i];
    int j = i - 1;
    while (j >= 0 && sortBuf[j] > key) {
      sortBuf[j + 1] = sortBuf[j];
      j = j - 1;
    }
    sortBuf[j + 1] = key;
  }
  return sortBuf[2]; // Return the middle element
}
