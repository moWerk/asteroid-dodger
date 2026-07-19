# asteroid-dodger architecture

Living document — updated in the same commit as every structural change
(shared discipline rule 2). Current state of the OOP refactor; sections
appear as extractions land.

## Components

```
main.qml          application root: game state properties, page flow,
                  system timers, and (for now) the world/HUD monolith
                  still awaiting extraction
Balance.qml       ALL gameplay tuning + difficulty presets. QtObject,
                  no signals. apply(name) writes the six difficulty-
                  dependent tunables and returns the preset; root-side
                  effects of a difficulty switch (scroll speed reset,
                  persistence, powerup weight table) stay in main.qml's
                  applyDifficulty()
ValueCycler.qml   tap-to-cycle selector control
DeathShader.qml   self-contained death effect; pre-baked qsb shader in
                  shaders/ (source beside it)
```

## Interfaces

Primitives-only between components; signals for write-back (house
pattern). Balance is read via `balance.<prop>` bindings; the only write
path is `balance.apply(name)`.

## Refactor process

Machine-drafted refactor (Claude, disclosed per project governance —
see DEVELOPMENT.md). Behavior-preserving extractions in single-concern
commits; each commit message states what did NOT change. Verified by
build + on-watch smoke test at each milestone (no automated UI test
suite exists; the smoke record substitutes, per test discipline).
