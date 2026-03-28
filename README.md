# asteroid-dodger

Asteroid-Dodger is a thrilling survival game for AsteroidOS where you
tilt your watch to surf through an ever-denser asteroid field, nailing
near-miss combos for big points. Master the art of close dodges, grab
power-up potions to shift the odds, and climb four difficulty tiers
from relaxed to ruthless. With retro arcade flair, a shader death
sequence, and accelerometer-driven action, this game turns your wrist
into a playground of skill and reflexes.

## Difficulty Tiers

- **Cadet Swerver** — Relaxed density and speed. The original game feel.
- **Captain Slipstreamer** — Faster scroll, tighter asteroid density.
- **Commander Stardust** — Reduced power-up window, rarer invincibility.
- **Major Roadkill** — No invincibility pickup. Godspeed.

Your last-played difficulty is remembered. A per-difficulty leaderboard
on the game over screen tracks your best score and max level across all
four tiers.

## Gameplay Mechanics

- **Random generation** of the asteroid field and power-ups for endless variety.
- **Combo system**: Near-miss dodging within a 2-second window chains into
  multiplied points. A green meter below the score shows the combo window.
- **Level progression**: Every 100 asteroids survived increases speed and density.
- **Shield system**: Start with 2 shields, collect blue power-ups to rebuild up to 10.
- **Highscore tracking**: Stored per difficulty in `~/.config/asteroid-dodger/game.ini`.

## Visuals & Feedback

- **Death shader**: A fatal hit decelerates the field and plays an expanding
  ring shader over the player before the game over screen appears.
- **Background flashes**: Color-coded atmospheric flashes signal game events.
- **Parallax effect**: Slower non-colliding large asteroids add depth.
- **Particle effects**: Score particles grow larger and turn pink at high combo values.
- **Hit feedback**: Player blinks during the 2-second grace invincibility window.
- **Haptic feedback**: Vibration on damage and level advancement.
- **Combo area visualization**: Diamond overlay shows the near-miss detection zone.
- **Dynamic power-up bars**: Each active power-up shows a color-coded duration bar.

## Power-Ups

- **Blue**: Gain +1 shield point (up to 10).
- **Pink**: 10 seconds of invincibility. Stacks with grace period — not available on Major Roadkill.
- **Yellow**: 6-second speed boost with unpredictable "drunk" steering.
- **Green**: 2× score multiplier for 10 seconds.
- **Cyan**: 6-second slow-motion — halves scroll speed and spawn rate.
- **Orange**: Shrink to 50% size, growing back over 6 seconds.
- **Purple**: Auto-fire — 30 shots over 6 seconds destroy asteroids and potions.
- **Red**: Laser swipe — sweeps the screen clear of all objects.

## UI & Controls

- **Tilt to move**: Accelerometer controls horizontal player position.
- **Start screen**: Select difficulty via tap-cycling ValueCycler, then tap Die Now.
- **Calibration**: 2-second hold to set your comfortable neutral tilt position.
- **Pause**: Tap anywhere during play to pause. Tap again to resume.
- **Game over screen**: Shows current run result and full per-difficulty leaderboard.
- **Die Again**: Instantly restarts at current difficulty — no re-calibration needed.
- **Exact crash detection**: `QtShapes` hitbox shaped like the AsteroidOS logo.
- **Debug tools**: FPS counter and graph toggle accessible from the pause screen.

## Tactical Considerations

- Combo chains require consecutive near-misses within 2 seconds. Collecting
  any power-up resets the combo window — weigh the trade-off at high counts.
- Destroying asteroids with auto-fire or laser swipe removes them from the
  level progression count, letting you delay the speed and density ramp.
- Grace period and pink invincibility stack — taking a hit while pink is
  active keeps you protected for both durations.

## Requirements

AsteroidOS 2.0 — Qt 5.15

---

### 2.0 gameplay:
[![Dodger 2.0 on Youtube](https://img.youtube.com/vi/pIDpVahpWv8/0.jpg)](https://www.youtube.com/watch?v=pIDpVahpWv8)

### 1.0 Release video:
https://github.com/user-attachments/assets/99b8f8c5-eea0-4c35-812b-8c7f61858872

### Initial commit gameplay:
https://github.com/user-attachments/assets/14be49db-a2c0-466b-8402-caf0e3f773f0
