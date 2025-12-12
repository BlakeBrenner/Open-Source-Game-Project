# Testing Procedure

This project uses a manual testing procedure.

---

## Manual Gameplay Tests

### Player Movement
1. Press left/right input.
   - Expected: Player moves horizontally.
2. Press jump while grounded.
   - Expected: Player jumps.
3. Walk off a platform.
   - Expected: Gravity applies and player falls.

---

### Platform Reachability
1. Play multiple runs.
   - Expected: All platforms are reachable without impossible jumps.
2. Purchase jump upgrades.
   - Expected: Platform spacing increases accordingly.

---

### Moving Platforms
1. Stand on a moving platform.
   - Expected: Player moves with the platform.
2. Jump off a moving platform.
   - Expected: Player retains momentum.

---

### Coin System
1. Collect a coin.
   - Expected: Coin disappears and coin counter increments.
2. Collect multiple coins.
   - Expected: UI updates correctly.

---

### Shop System
1. Reach a shop platform or height trigger.
   - Expected: Shop opens only when player is grounded.
2. Navigate shop using left/right.
   - Expected: Selection changes.
3. Purchase upgrade with enough coins.
   - Expected: Coins decrease and upgrade applies.
4. Attempt purchase with insufficient coins.
   - Expected: No purchase occurs.

---

### Hazard Testing
1. Touch spiked platform side.
   - Expected: Player freezes and game over screen appears.

---

### Game Over
1. Fall below camera view.
   - Expected: Game over screen appears.
2. Press reset input.
   - Expected: Game restarts correctly.
