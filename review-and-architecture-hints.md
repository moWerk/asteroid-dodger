# Review and architecture hints: Asteroid Dodger for SailfishOS

For anyone reviewing the `sailfishos` branch: where the code comes from, how it is laid out, what is worth reading and what is boilerplate.

## Where the code comes from

The app is the AsteroidOS watch app on `master`. This branch forks from it at `9643d40`, and its commits are the SailfishOS port. The reliable view of what the port changed:

    git diff 9643d40 sailfishos -- qml src rpm '*.pro' '*.desktop'

Many port edits carry a `SailfishOS:` comment, but not all of them. Each commit message says what changed, why, and what was not checked, and ends with an LLMGD line grading it.

The port was written by an LLM (Claude), directed and tested by the author, who has not read the code. Everything here is a prototype until a reviewer owns it. That is the point of this file.

## Architecture

- `qml/harbour-asteroid-dodger.qml`: the Silica `ApplicationWindow`. It sizes `Dims` from the screen width, then loads the app (`game/main.qml`). When the app goes to the background, the same item is moved into the cover and scaled down, so the home screen tile shows it live. The same shell is used in all eight ports.
- `qml/game/Dims.qml`, `Label.qml`, `HighlightBar.qml`, `Icon.qml`, `PageHeader.qml`, `ValueCycler.qml`, `IntSelector.qml`, `DeviceSpecs.qml` (whichever exist here): small stand-ins for AsteroidOS's `org.asteroid.controls` and `org.asteroid.utils`, so the watch QML runs unchanged where possible. Each is a few dozen lines.
- `qml/game/main.qml` (about 1900 lines) is the game: state, timers, world, HUD, and functions from line ~1258. `docs/ARCHITECTURE.md` (from the AsteroidOS side) describes the component split: `Balance.qml` (all tuning and difficulty presets), `PreGamePage.qml`, `GameOverPage.qml` and `DeathShader.qml`.
- `qml/game/DodgerStorage.qml`: QML singleton for high scores and the chosen difficulty, kept in dconf (`/apps/harbour-asteroid-dodger`). It replaced a C++ QSettings class with the same API.
- Packaging: pure QML, no binary. `Exec=sailfish-qml harbour-asteroid-dodger` (package `libsailfishapp-launcher`), the `.pro` is `TEMPLATE = aux` with plain `INSTALLS`, and the spec is `BuildArch: noarch` with an xz payload (rpm 4.14 on SailfishOS 3.4 can not unpack the zstd of newer SDKs).

## Read these first

1. `git diff` of `qml/game/main.qml` against the fork point: the tall screen layout, the accelerometer handling and QtFeedback haptics in place of AsteroidOS's ngfd.
2. `DodgerStorage.qml`: the never-lower rules for records, and the string keys built from the difficulty name.
3. The `Accelerometer` in `main.qml`: `active` includes the calibration phase. On SailfishOS 3.4 the sensor was inactive during calibration, and the ship stuck to one edge (fixed in 2.0.2).

## Skim

Stand-ins, icons, `img/`, the packaging files.

## Worth questioning

- Permissions: `Camera`, not `Sensors`. The Jolla Store refuses Sensors, and SailfishOS's `Camera.permission` includes `Sensors.permission`. The camera is never opened. The validator passes with 0 errors.
- Scores from versions before 2.1.0 (QSettings) are not migrated to dconf.

## How it was tested

By the author, by playing it on a Jolla C2 (SailfishOS 5.1), the Jolla Tablet (4.6, x86) and a Jolla 1 (3.4, 32-bit ARM), with the same noarch package on all three. Before each handover, the LLM checked builds, package contents and start logs on those devices.

There are no automated tests; the on-device checks are listed in the commit messages.
