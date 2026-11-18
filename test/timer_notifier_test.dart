import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toadtimer/models/timer_mode.dart';
import 'package:toadtimer/models/timer_settings.dart';
import 'package:toadtimer/state/providers.dart';
import 'package:toadtimer/state/timer_notifier.dart';

/// Unit tests for the toadTIMER Pomodoro state machine.
///
/// The wall clock is injected (`clock:`) so session completion can be
/// simulated deterministically by moving [fakeNow] forward and calling
/// tick() — no real waiting, no drift.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The tile bridge is a plain MethodChannel; mock it so tile actions can be
  // staged exactly like the Android Quick Settings tile would.
  String? pendingTileAction;
  const tileChannel = MethodChannel('dev.toad.toadtimer/tile');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(tileChannel, (call) async {
    if (call.method == 'consumePendingAction') return pendingTileAction;
    return null; // setTileActive etc. succeed silently
  });

  late DateTime fakeNow;
  late ProviderContainer container;

  // Sound/notifications are disabled so no platform audio/notification
  // plugins are exercised — the state machine under test stays pure Dart.
  const testSettings = TimerSettings(
    focusMin: 25,
    shortMin: 5,
    longMin: 15,
    longEvery: 4,
    autoStartBreaks: true,
    autoStartFocus: false,
    soundOn: false,
    notifyOn: false,
  );

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsController.withInitial(testSettings),
        ),
        statsProvider.overrideWith(
          (ref) => StatsController.withInitial(const StatsState([])),
        ),
        timerProvider.overrideWith(
          (ref) {
            final notifier = TimerNotifier(ref, clock: () => fakeNow);
            ref.listen<TimerSettings>(settingsProvider, (_, __) {
              notifier.onSettingsChanged();
            });
            return notifier;
          },
        ),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    pendingTileAction = null;
    fakeNow = DateTime(2024, 1, 8, 9, 0);
    container = buildContainer();
  });

  tearDown(() {
    container.dispose();
  });

  TimerNotifier get notifier => container.read(timerProvider.notifier);
  TimerState get state => container.read(timerProvider);

  /// Simulates one completed session of [minutes] via a quick-start override.
  void runSession(int minutes) {
    notifier.quickStart(TimerMode.focus, minutes);
    fakeNow = fakeNow.add(Duration(minutes: minutes, seconds: 1));
    notifier.tick();
  }

  group('initial state', () {
    test('starts idle in focus mode at 25:00', () {
      expect(state.mode, TimerMode.focus);
      expect(state.isIdle, true);
      expect(state.remaining, 25 * 60);
      expect(state.endAt, isNull);
      expect(state.cyclePosition, 0);
      expect(state.overrideMinutes, isNull);
    });
  });

  group('start / pause / reset', () {
    test('start() runs from the wall-clock target and ticks drift-free', () {
      notifier.start();

      expect(state.isRunning, true);
      expect(state.endAt, isNotNull);
      expect(state.remaining, 25 * 60);

      fakeNow = fakeNow.add(const Duration(seconds: 10));
      notifier.tick();
      expect(state.remaining, 25 * 60 - 10);

      fakeNow = fakeNow.add(const Duration(seconds: 5));
      notifier.tick();
      expect(state.remaining, 25 * 60 - 15);
    });

    test('pause() freezes the remaining time and clears endAt', () {
      notifier.start();
      fakeNow = fakeNow.add(const Duration(seconds: 42));
      notifier.pause();

      expect(state.isPaused, true);
      expect(state.endAt, isNull);
      expect(state.remaining, 25 * 60 - 42);

      // time passes but the clock stays frozen while paused
      fakeNow = fakeNow.add(const Duration(minutes: 3));
      notifier.tick();
      expect(state.remaining, 25 * 60 - 42);
    });

    test('start() after pause resumes from the frozen remaining', () {
      notifier.start();
      fakeNow = fakeNow.add(const Duration(seconds: 30));
      notifier.pause();
      notifier.start();

      expect(state.isRunning, true);
      expect(state.endAt, fakeNow.add(Duration(seconds: 25 * 60 - 30)));
    });

    test('reset() returns to the settings duration and clears overrides', () {
      notifier.quickStart(TimerMode.focus, 15);
      notifier.pause();
      notifier.reset();

      expect(state.isIdle, true);
      expect(state.mode, TimerMode.focus);
      expect(state.remaining, 25 * 60);
      expect(state.overrideMinutes, isNull);
    });

    test('start() is a no-op while already running', () {
      notifier.start();
      final firstEndAt = state.endAt;
      fakeNow = fakeNow.add(const Duration(seconds: 5));
      notifier.start();
      expect(state.endAt, firstEndAt);
    });
  });

  group('selectMode', () {
    test('switches mode and reloads the settings duration', () {
      notifier.selectMode(TimerMode.shortBreak);
      expect(state.mode, TimerMode.shortBreak);
      expect(state.isIdle, true);
      expect(state.remaining, 5 * 60);
    });

    test('cancels a running session', () {
      notifier.start();
      fakeNow = fakeNow.add(const Duration(seconds: 100));
      notifier.selectMode(TimerMode.longBreak);

      expect(state.mode, TimerMode.longBreak);
      expect(state.isIdle, true);
      expect(state.remaining, 15 * 60);
    });
  });

  group('quickStart', () {
    test('launches a one-shot override session immediately', () {
      notifier.quickStart(TimerMode.focus, 15);

      expect(state.isRunning, true);
      expect(state.mode, TimerMode.focus);
      expect(state.overrideMinutes, 15);
      expect(state.remaining, 15 * 60);
      expect(state.endAt, fakeNow.add(const Duration(minutes: 15)));
    });

    test('tick() keeps the countdown honest mid-session', () {
      notifier.quickStart(TimerMode.focus, 15);
      fakeNow = fakeNow.add(const Duration(seconds: 10));
      notifier.tick();
      expect(state.remaining, 15 * 60 - 10);
    });
  });

  group('skip', () {
    test('does not log a session and hops to the break', () {
      notifier.skip();

      expect(state.mode, TimerMode.shortBreak);
      expect(container.read(statsProvider).history, isEmpty);
      // skip from an idle focus auto-starts the break (autoStartBreaks: true)
      expect(state.isRunning, true);
    });

    test('from a break returns to focus without touching the cycle', () {
      runSession(25); // focus done -> short break, cycle 1
      expect(state.cyclePosition, 1);

      notifier.skip();
      expect(state.mode, TimerMode.focus);
      expect(state.cyclePosition, 1);
      expect(container.read(statsProvider).history.length, 1);
    });
  });

  group('session completion', () {
    test('a finished focus session is logged and auto-starts the break', () {
      runSession(25);

      expect(state.mode, TimerMode.shortBreak);
      expect(state.isRunning, true); // autoStartBreaks
      expect(state.overrideMinutes, isNull); // override consumed
      expect(state.remaining, 5 * 60);
      expect(state.cyclePosition, 1);

      final history = container.read(statsProvider).history;
      expect(history.length, 1);
      expect(history.single.mode, TimerMode.focus);
      expect(history.single.minutes, 25);
    });

    test('a finished break returns to focus and goes idle (no auto-start)', () {
      runSession(25);
      fakeNow = fakeNow.add(const Duration(minutes: 5, seconds: 1));
      notifier.tick();

      expect(state.mode, TimerMode.focus);
      expect(state.isIdle, true); // autoStartFocus disabled
      expect(state.remaining, 25 * 60);
      expect(state.cyclePosition, 1);
    });

    test('the fourth focus session rolls into the long break', () {
      for (var i = 1; i <= 4; i++) {
        runSession(25);
        expect(container.read(statsProvider).history.length, i);

        if (i < 4) {
          expect(state.mode, TimerMode.shortBreak);
          expect(state.cyclePosition, i);
          notifier.skip(); // jump past the break to the next focus round
          expect(state.mode, TimerMode.focus);
        } else {
          expect(state.mode, TimerMode.longBreak);
          expect(state.cyclePosition, 4);
          expect(state.remaining, 15 * 60);
        }
      }

      // completing the long break resets the cycle
      fakeNow = fakeNow.add(const Duration(minutes: 15, seconds: 1));
      notifier.tick();
      expect(state.mode, TimerMode.focus);
      expect(state.cyclePosition, 0);
      expect(state.isIdle, true);
    });

    test('history timestamps use the injected clock', () {
      runSession(25);
      final log = container.read(statsProvider).history.single;
      expect(log.at, fakeNow);
    });
  });

  group('liveQuickTileProvider', () {
    test('flags Classic while a default 25-minute focus is staged', () {
      final live = container.read(liveQuickTileProvider);
      expect(live, isNotNull);
      expect(live!.minutes, 25);
      expect(live.mode, TimerMode.focus);
    });

    test('flags Deep Work during a 50-minute quick start', () {
      notifier.quickStart(TimerMode.focus, 50);
      expect(container.read(liveQuickTileProvider)!.minutes, 50);
    });

    test('returns null for non-preset durations', () {
      notifier.quickStart(TimerMode.focus, 18);
      expect(container.read(liveQuickTileProvider), isNull);
    });
  });

  group('settings changes', () {
    test('refresh the idle duration when focus length changes', () async {
      expect(state.remaining, 25 * 60);

      await container
          .read(settingsProvider.notifier)
          .update(container.read(settingsProvider).copyWith(focusMin: 50));
      // let the provider listener propagate
      await Future<void>.delayed(Duration.zero);

      expect(state.remaining, 50 * 60);
    });

    test('do not clobber a running session', () async {
      notifier.start();
      fakeNow = fakeNow.add(const Duration(seconds: 60));

      await container
          .read(settingsProvider.notifier)
          .update(container.read(settingsProvider).copyWith(focusMin: 50));
      await Future<void>.delayed(Duration.zero);

      expect(state.isRunning, true);
      // the wall-clock target was never touched — a tick re-syncs against it
      notifier.tick();
      expect(state.remaining, 25 * 60 - 60);
    });
  });

  group('resync (Quick Tile + wall-clock catch-up)', () {
    test('consumes a pending start_focus action into a running session',
        () async {
      pendingTileAction = 'start_focus';
      await notifier.resync();

      expect(state.isRunning, true);
      expect(state.mode, TimerMode.focus);
      expect(state.overrideMinutes, 25);
      expect(state.remaining, 25 * 60);

      // the pending action is consumed exactly once
      pendingTileAction = null;
      await notifier.resync();
      expect(state.remaining, 25 * 60);
    });

    test('consumes a pending stop action as a pause', () async {
      notifier.start();
      pendingTileAction = 'stop';
      await notifier.resync();

      expect(state.isPaused, true);
    });

    test('catches the countdown up with the wall clock after resuming',
        () async {
      notifier.quickStart(TimerMode.focus, 15);
      fakeNow = fakeNow.add(const Duration(seconds: 70));

      await notifier.resync();
      expect(state.remaining, 15 * 60 - 70);
    });
  });
}
