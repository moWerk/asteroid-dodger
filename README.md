# asteroid-dodger

Asteroid-Dodger is a thrilling survival game for AsteroidOS where you
tilt your watch to surf through an ever-denser asteroid field, nailing
near-miss combos for big points. Master the art of close dodges, grab
power-up potions to shift the odds, and climb four difficulty tiers
from relaxed to ruthless. With retro arcade flair, a shader death
sequence, and accelerometer-driven action, this game turns your wrist
into a playground of skill and reflexes.

## SailfishOS

This branch is the SailfishOS version of the game. It is built for
Sailfish OS 5.1 on aarch64 and was played on a Jolla C2. The game itself
is the 2.0 watch version described below. This section lists what is
different.

### Only on SailfishOS

- **Power-up callout**: collecting a power-up shouts its name below the
  HUD, in the power-up's colour. Two quick pumps, then it dissolves.
- **Playable cover**: swipe the app away and the round keeps running in
  its tile on the home screen. Tilt still steers. The button on the tile
  pauses and resumes. Inside the app a tap pauses as before.

### Tuned for the larger screen

A phone screen is taller and wider than a watch, and the watch tuning
does not carry over as it is.

- The play field fills the whole screen. A tall field keeps objects in
  view longer, so the object pool grows with the field height (89 instead
  of 40 on the C2).
- Scroll speed is tuned in pixels per frame. It now scales with the screen
  width, which is 1.5 times the watch speed on a 720 px wide phone.
- Power-ups look for a free position only among the asteroids near the
  top edge. Checked against every visible asteroid, a tall field left no
  room and power-ups nearly stopped appearing.
- 20 % fewer power-ups and 20 % more speed-up per level than the presets.
- Asteroid sizes vary from 0.7 to 1.3 instead of 0.8 to 1.2.
- The HUD bars span 70 % of the width and sit below the camera notch. The
  start and game over screens are centred blocks.
- The display stays on only while a round is running.

### Install

Download the RPM from the releases page and install it:

    devel-su pkcon install-local harbour-asteroid-dodger-2.0.0-1.aarch64.rpm

It is aarch64 only. The app runs without sandboxing, so it is for
sideloading and not a store build. Highscores are stored in
`~/.config/net.mowerk/harbour-asteroid-dodger/game.ini`.

### Build

With the Sailfish Platform SDK and a 5.1.0.11 aarch64 target:

    mb2 -t SailfishOS-5.1.0.11-aarch64 build

SailfishOS is on Qt 5.6. The port therefore uses versioned imports, no
`QtQuick.Shapes`, an inline GLSL shader, and small stand-ins for the
AsteroidOS components (`qml/game/Label.qml`, `HighlightBar.qml`,
`Dims.qml`). The Fyodor font and the AsteroidOS logo ship with the app.

### Disclosure for the port

The port was written by an LLM in one evening, directed by the author.
He asked for it, played every build on the phone, found what was wrong
and said how it should be. The model located the causes and wrote the
code. He has not read the port's code. It was tested on one phone.

```
Disclosure: LLMGD-3 · origin O1 (human-directed port, LLM-written; played and steered by the author on one Jolla C2; code not read; self-graded)
LLMGD: v0.2; assurance=A3; flags=U,T; origin={O0:.45,O1:.55}; origin_headline=O1; scope=port(code+assets+packaging+docs); graded-by=claude-fable-5-1; retrieval=author-side
```

The disclosure further down is the older one for the 2.0 rework of the
game itself.

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

AsteroidOS 2.0 — Qt 5.15 (master branch)

Sailfish OS 5.1, aarch64, Qt 5.6 (this branch)

## Disclosure

The 2.0 rework and OOP refactor were heavily LLM-driven. The session
transcripts are long gone, so not one assurance flag can be evidenced —
and per [LLMGD](https://github.com/moWerk/llmgd-specs), what can't be
proven takes the floor. Self-graded to the drowned sub, and worn with a
grin.

```
Disclosure: LLMGD-0 (LLM-driven; transcript lost, nothing provable, floored)
LLMGD: v0.1; origin=O0; assurance=none; scope=code+docs; graded-by=self; retrieval=logs-lost
```

---

### 2.0 gameplay:
[![Dodger 2.0 on Youtube](https://img.youtube.com/vi/pIDpVahpWv8/0.jpg)](https://www.youtube.com/watch?v=pIDpVahpWv8)

### 1.0 Release video:
https://github.com/user-attachments/assets/99b8f8c5-eea0-4c35-812b-8c7f61858872

### Initial commit gameplay:
https://github.com/user-attachments/assets/14be49db-a2c0-466b-8402-caf0e3f773f0
