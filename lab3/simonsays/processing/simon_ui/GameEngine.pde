// ============================================
// GameEngine.pde - Simon Says Logic
// ============================================
// States:
//   IDLE     → waiting for player to start
//   SHOWING  → playing the pattern sequence
//   WAITING  → player's turn to repeat
//   SUCCESS  → level cleared, brief pause
//   FAIL     → wrong input, game over
//
// Inputs 0-9 = pad presses, 10 = flex bend.
// Each level adds one step. Speed increases.
// ============================================

class GameEngine {
  static final int IDLE    = 0;
  static final int SHOWING = 1;
  static final int WAITING = 2;
  static final int SUCCESS = 3;
  static final int FAIL    = 4;

  int state = IDLE;
  int level = 0;
  int score = 0;
  int highScore = 0;

  // Sequence
  ArrayList<Integer> sequence = new ArrayList<Integer>();
  int showIndex   = 0;
  int playerIndex = 0;

  // Timing
  long stateTimer;
  boolean inGap = false;
  int baseShowMs  = 600;   // duration each step is lit
  int baseGapMs   = 300;   // gap between steps
  int successMs   = 1200;  // pause after level complete
  int failDisplayMs = 2500;

  // Flex introduces at this level
  int flexStartLevel = 1;

  // --- Game flow ---

  void startGame() {
    level = 1;
    score = 0;
    sequence.clear();
    addStep();
    startShowing();
  }

  void addStep() {
    int maxInput = (level >= flexStartLevel) ? 11 : 10;
    int step = int(random(maxInput)); // 0-9 pads, 10 = flex
    sequence.add(step);
  }

  void startShowing() {
    state = SHOWING;
    showIndex = 0;
    inGap = false;
    stateTimer = millis();

    // Clear all lights
    padGrid.clearAll();
    flexBar.setLit(false);
  }

  // --- Update (call every frame) ---

  void update() {
    switch (state) {
      case SHOWING:
        updateShowing();
        break;
      case SUCCESS:
        if (millis() - stateTimer > successMs) {
          level++;
          addStep();
          startShowing();
        }
        break;
      case FAIL:
        // Wait for restart
        break;
    }
  }

  void updateShowing() {
    long elapsed = millis() - stateTimer;

    // Speed increases with level
    int showMs = max(baseShowMs - (level - 1) * 25, 200);
    int gapMs  = max(baseGapMs  - (level - 1) * 15, 100);

    if (!inGap) {
      // Currently showing a step
      int currentStep = sequence.get(showIndex);

      // Light up the current step
      if (currentStep < 10) {
        padGrid.setLit(currentStep, true);
      } else {
        flexBar.setLit(true);
      }

      // Play sound for this step
      if (elapsed < 50) {
        soundManager.play(currentStep);
      }

      if (elapsed >= showMs) {
        // Turn off
        if (currentStep < 10) {
          padGrid.setLit(currentStep, false);
        } else {
          flexBar.setLit(false);
        }
        inGap = true;
        stateTimer = millis();
      }
    } else {
      // In gap between steps
      if (elapsed >= gapMs) {
        showIndex++;
        if (showIndex >= sequence.size()) {
          // Done showing — player's turn
          state = WAITING;
          playerIndex = 0;
        } else {
          inGap = false;
          stateTimer = millis();
        }
      }
    }
  }

  // --- Player input ---

  void playerInput(int inputIndex) {
    if (state == IDLE) {
      startGame();
      return;
    }

    if (state != WAITING) return;

    int expected = sequence.get(playerIndex);

    if (inputIndex == expected) {
      // Correct!
      soundManager.play(inputIndex);

      // Flash the pressed pad/flex
      if (inputIndex < 10) {
        padGrid.flashPad(inputIndex);
      } else {
        flexBar.flash();
      }

      playerIndex++;

      if (playerIndex >= sequence.size()) {
        // Level complete!
        score += level * 10;
        if (score > highScore) highScore = score;
        state = SUCCESS;
        stateTimer = millis();
        padGrid.flashAll();
      }
    } else {
      // Wrong!
      state = FAIL;
      stateTimer = millis();
      if (score > highScore) highScore = score;
      soundManager.playFail();
    }
  }

  void restart() {
    state = IDLE;
    padGrid.clearAll();
    flexBar.setLit(false);
  }

  // Physical pad 10: START when idle/failed, END when playing
  void startEndButton() {
    if (state == IDLE || state == FAIL) {
      startGame();
    } else {
      // End game mid-play
      if (score > highScore) highScore = score;
      state = FAIL;
      stateTimer = millis();
      padGrid.clearAll();
      flexBar.setLit(false);
      println("Game ended by player. Score: " + score);
    }
  }

  // --- Status text ---

  String getStatusText() {
    switch (state) {
      case IDLE:    return "Press any pad to start";
      case SHOWING: return "Watch the pattern...";
      case WAITING:
        return "Your turn!  " + playerIndex + " / " + sequence.size();
      case SUCCESS: return "Correct! ✓";
      case FAIL:    return "Wrong! Game Over — Click to restart";
      default:      return "";
    }
  }

  color getStatusColor() {
    switch (state) {
      case SUCCESS: return color(80, 255, 120);
      case FAIL:    return color(255, 80, 80);
      case SHOWING: return color(255, 220, 80);
      case WAITING: return color(100, 200, 255);
      default:      return color(160, 160, 170);
    }
  }
}
