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
    }
  }

  // Maintain a consistent sampling rate (100Hz)
  if (currentTime - lastSampleTime >= sampleInterval) {
    lastSampleTime = currentTime;

    // --- 1. SENSOR READINGS ---
    int rawValue = analogRead(ad8232Output);
    static float ecgFiltered = 512;
    
    // Glitch Filter: If it jumps too fast (noise), ignore the spike
    if (abs(rawValue - ecgFiltered) < 300) { 
      // Smoother EMA (0.2 = more smoothing)
      ecgFiltered = (0.2 * rawValue) + (0.8 * ecgFiltered);
    }
    int ecgRaw = (int)ecgFiltered;
    
    int rawFsr = analogRead(fsrPin);
    static float fsrFiltered = 512;
    if (abs(rawFsr - fsrFiltered) < 400) {
      fsrFiltered = (0.15 * rawFsr) + (0.85 * fsrFiltered);
    }
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

      // Add to rolling average buffer
      beatIntervals[beatIndex] = rawBpm;
      beatIndex = (beatIndex + 1) % bpmAvgSize;

      // Calculate Average BPM
      long sum = 0;
      for (int i = 0; i < bpmAvgSize; i++) sum += beatIntervals[i];
      bpm = sum / bpmAvgSize;

    } else if (ecgRaw < (ecgThreshold - 50)) {
      // Sensitivity reset - lower it more to ensure we clear the peak
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
    /* 
     * Format: ECG_RAW, FSR_RAW, BPM, RESP_RATE, INHALE_MS, EXHALE_MS
     */
    Serial.print(ecgRaw);           Serial.print(",");
    Serial.print(fsrRaw);           Serial.print(",");
    Serial.print(bpm);              Serial.print(",");
    Serial.print(respirationRate);  Serial.print(",");
    Serial.print(inhaleDuration);   Serial.print(",");
    Serial.println(exhaleDuration);
  }
}
