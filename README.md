# toadTIMER

A premium Pomodoro timer for Android & iOS, built with **Flutter**.

[![CI](https://github.com/dukeoftoad/toadTIMER/actions/workflows/ci.yml/badge.svg)](https://github.com/dukeoftoad/toadTIMER/actions/workflows/ci.yml)
[![Android debug build](https://github.com/dukeoftoad/toadTIMER/actions/workflows/android-debug-build.yml/badge.svg)](https://github.com/dukeoftoad/toadTIMER/actions/workflows/android-debug-build.yml)
[![Release](https://github.com/dukeoftoad/toadTIMER/actions/workflows/release.yml/badge.svg)](https://github.com/dukeoftoad/toadTIMER/actions/workflows/release.yml)

> CI runs automatically on every push to main.

- **State management practice** — a single Riverpod `StateNotifier` state machine (`lib/state/timer_notifier.dart`) drives every transition: `idle → running → paused → complete → next mode`. The UI layer stays dumb; side effects (chime, exact alarms, Quick-Settings tile sync) hang off the same transitions.
- **Notifications** — `flutter_local_notifications` + `timezone`: when a session starts, an **exact alarm** (`exactAllowWhileIdle`) is scheduled for its end time, so the alert fires even if the app is backgrounded or the screen is off. Pausing/resetting cancels the pending alarm.
- **Quick Tile** — a real Android **Quick Settings tile** (`ToadTileService.kt`, "Toad Focus"). Tap it from the notification shade: it flips state, drops a pending action into SharedPreferences and opens the app, which consumes the action on resume and starts/stops a focus session. (iOS has no Quick-Tile equivalent; the channel no-ops there.)
- **Premium dark design** — toad-pond dark theme, gradient sweep progress ring (CustomPainter), animated segmented mode tabs, cycle dots, quick-tile grid, stats (sessions today / focus minutes / streak / all-time), session log and a settings bottom sheet.

## Features

| | |
|---|---|
| Modes | Focus / Short Break / Long Break with a configurable long-break cycle |
| Quick Tiles (in-app) | 15 Sprint · 25 Classic · 50 Deep Work · 90 Marathon · 5 Break · 15 Reset — one tap launches instantly, mid-flow |
| Auto-start | Toggle auto-start for breaks and/or focus |
| Sound | Bundled two-tone chime (Web-Audio-style arpeggio, generated 44.1 kHz WAV) |
| Stats | Sessions today, focus minutes, day streak, all-time — persisted via `shared_preferences` |
| Settings | Duration sliders, cycle length, auto-start switches, sound & notification toggles, clear-log |
| App icon | Generated toad mascot, wired via `flutter_launcher_icons` |
| Premium dial | 60 dial ticks, inner hairline, breathing glow while running, glowing arc tip, per-second digit slide transitions, press-scale + haptic feedback on every control |
| Tests & CI | Unit-tested state machine, streak logic and repositories; GitHub Actions for lint, tests, debug builds and tag releases |

## Project layout

```
lib/
├── main.dart                  # bootstrap: services init, seeded ProviderScope
├── app.dart                   # MaterialApp + dark theme
├── core/                      # constants (presets, palette), theme, utils
├── models/                    # TimerMode, TimerSettings, SessionLog, TimerState
├── data/                      # settings / stats repositories (SharedPreferences JSON)
├── services/                  # notification_service, sound_service, tile_service
├── state/                     # providers.dart (settings/stats/messenger) + timer_notifier.dart
├── widgets/                   # ring, tabs, dots, controls, quick tiles, stats, history, settings sheet
└── screens/home_screen.dart   # composition + lifecycle observer

test/
├── timer_notifier_test.dart   # the full Pomodoro state machine (fake clock)
├── core_utils_test.dart       # formatClock, dayKey, relativeTime, calcStreak
├── models_test.dart           # settings/log/state serialization + copyWith
├── stats_state_test.dart      # stats aggregation, repositories, 200-entry cap
└── widget_test.dart           # framework smoke test

android/app/src/main/
├── AndroidManifest.xml        # POST_NOTIFICATIONS, exact alarms, QS tile service
└── kotlin/dev/toad/toadtimer/
    ├── MainActivity.kt        # "dev.toad.toadtimer/tile" MethodChannel
    └── ToadTileService.kt     # Quick Settings TileService
assets/
├── icon/toad_icon.png         # mascot (also the launcher icon source)
└── sounds/chime.wav           # completion chime

.github/workflows/
├── ci.yml                     # lint + unit tests on every push / PR
├── android-debug-build.yml    # debug APK artifact on main / manual
└── release.yml                # tag-triggered release with APK + AAB
```

## Getting started

The repository intentionally ships only the source that differs from a default
Flutter template (`lib/`, `pubspec.yaml`, `assets/`, the Android manifest and
Kotlin files). Regenerate the platform scaffolding on your machine:

```bash
# 1. Generate android/ + ios/ scaffolding around the existing files.
#    Existing files are NOT overwritten — the manifest and Kotlin sources stay.
flutter create --org dev.toad --project-name toadtimer --platforms android,ios .

# 2. Fetch dependencies
flutter pub get

# 3. Generate launcher icons from the mascot
dart run flutter_launcher_icons

# 4. Run it
flutter run
```

> Requires Flutter 3.22+ (Dart 3.4+). `google_fonts` fetches Inter / JetBrains
> Mono on first launch and caches them.

## Running the tests

```bash
flutter test                 # full suite
flutter test --coverage      # lcov report in coverage/
flutter analyze              # static analysis (rules from analysis_options.yaml)
```

The state-machine tests inject a fake wall clock into `TimerNotifier`, so
session completion, long-break cycling and tile actions are simulated
deterministically — no real waiting.

## Continuous integration

| Workflow | File | Trigger | What it does |
| --- | --- | --- | --- |
| CI | `.github/workflows/ci.yml` | push to `main`, PRs, manual | `flutter analyze` + `flutter test --coverage` (coverage artifact) |
| Android debug build | `.github/workflows/android-debug-build.yml` | push to `main`, manual | restores platform scaffolding, applies icons, builds a debug APK, uploads it as an artifact |
| Release | `.github/workflows/release.yml` | tag push `v*.*.*` | lint + test gates, builds release APK + AAB, publishes a GitHub Release with auto notes |

### Cutting a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The Release workflow attaches `toadtimer-v1.0.0.apk` and `.aab` to the
release page. Builds are signed with the debug keystore until you wire real
signing: add repository secrets (`ANDROID_KEYSTORE_B64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) and
a decode step in `release.yml` before the build.

### Why `flutter create .` in the workflows?

The repo intentionally vendors only the source that differs from a default
Flutter template. `flutter create --platforms android,ios --org dev.toad .`
regenerates the missing Gradle files on the runner **without overwriting**
the committed manifest, Kotlin sources, lib/ or test/ files (existing files
are skipped), so CI can build straight from a clean checkout.

## Enabling the Quick Tile

1. Run the app once (it registers `ToadTileService`).
2. Pull down the notification shade twice → **edit / long-press** the tiles.
3. Drag **Toad Focus** into the active tiles.
4. Tap it → a focus session starts immediately with the app's default focus
   length; tap again while running → the session pauses.

## Notes on permissions

- **POST_NOTIFICATIONS** — requested at runtime (Android 13+).
- **SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM** — exact session-end alarms in
  Doze. `USE_EXACT_ALARM` is accepted for alarm/timer apps on Play; if you
  target other categories, remove it and rely on the user-granted
  `SCHEDULE_EXACT_ALARM` fallback.
- **iOS** — notifications request permission on first toggle; there is no
  Quick Tile; the tile channel is a safe no-op.

## Pushing to GitHub

```bash
git remote add origin https://github.com/<you>/toadtimer.git
git push -u origin main
```

Or hand a fine-grained PAT to your assistant and let it push for you.

## Architecture in one paragraph

`TimerNotifier` holds an immutable `TimerState` (mode, status, remaining,
wall-clock `endAt`, cycle position, override). A 250 ms ticker computes
remaining time from `endAt`, so the countdown never drifts even when the OS
throttles background timers — on resume it re-syncs from the wall clock.
Completion transitions write a `SessionLog`, bump the cycle, pick the next
mode (short vs. long break), honor auto-start settings, fire the chime +
snackbar, and resync the Quick-Settings tile. Settings and history persist
through tiny repository classes over `shared_preferences`.
