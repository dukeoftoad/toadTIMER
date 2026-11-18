import 'package:flutter_test/flutter_test.dart';

import 'package:toadtimer/models/session_log.dart';
import 'package:toadtimer/models/timer_mode.dart';
import 'package:toadtimer/models/timer_settings.dart';
import 'package:toadtimer/models/timer_state.dart';

void main() {
  group('TimerSettings', () {
    test('defaults match the classic pomodoro setup', () {
      const settings = TimerSettings.defaults();
      expect(settings.focusMin, 25);
      expect(settings.shortMin, 5);
      expect(settings.longMin, 15);
      expect(settings.longEvery, 4);
      expect(settings.autoStartBreaks, true);
      expect(settings.autoStartFocus, false);
      expect(settings.soundOn, true);
      expect(settings.notifyOn, false);
    });

    test('minutesFor maps each mode', () {
      const settings = TimerSettings.defaults();
      expect(settings.minutesFor(TimerMode.focus), 25);
      expect(settings.minutesFor(TimerMode.shortBreak), 5);
      expect(settings.minutesFor(TimerMode.longBreak), 15);
    });

    test('json roundtrip preserves every field', () {
      const settings = TimerSettings(
        focusMin: 50,
        shortMin: 10,
        longMin: 20,
        longEvery: 6,
        autoStartBreaks: false,
        autoStartFocus: true,
        soundOn: false,
        notifyOn: true,
      );
      final restored = TimerSettings.fromJson(settings.toJson());
      expect(restored.focusMin, 50);
      expect(restored.shortMin, 10);
      expect(restored.longMin, 20);
      expect(restored.longEvery, 6);
      expect(restored.autoStartBreaks, false);
      expect(restored.autoStartFocus, true);
      expect(restored.soundOn, false);
      expect(restored.notifyOn, true);
    });

    test('fromJson falls back to defaults on malformed values', () {
      final settings = TimerSettings.fromJson({
        'focusMin': 'not-a-number',
        'shortMin': 4.7, // numeric -> rounded
        'longEvery': true, // wrong type -> fallback
      });
      expect(settings.focusMin, 25);
      expect(settings.shortMin, 5);
      expect(settings.longEvery, 4);
    });

    test('copyWith overrides only provided fields', () {
      const base = TimerSettings.defaults();
      final next = base.copyWith(focusMin: 45, autoStartFocus: true);
      expect(next.focusMin, 45);
      expect(next.autoStartFocus, true);
      expect(next.shortMin, base.shortMin);
      expect(next.longMin, base.longMin);
      expect(next.autoStartBreaks, base.autoStartBreaks);
    });
  });

  group('SessionLog', () {
    test('json roundtrip preserves mode, minutes and timestamp', () {
      final log = SessionLog(
        mode: TimerMode.longBreak,
        minutes: 15,
        at: DateTime.fromMillisecondsSinceEpoch(1700000060000),
      );
      final restored = SessionLog.fromJson(log.toJson());
      expect(restored.mode, TimerMode.longBreak);
      expect(restored.minutes, 15);
      expect(restored.at.millisecondsSinceEpoch, 1700000060000);
    });

    test('fromJson falls back to focus for unknown modes', () {
      final log = SessionLog.fromJson({'mode': 'mystery', 'minutes': 25, 'at': 0});
      expect(log.mode, TimerMode.focus);
    });
  });

  group('TimerState.copyWith', () {
    test('clearEndAt nulls the wall-clock target', () {
      const state = TimerState();
      final withEnd = state.copyWith(
        status: TimerStatus.running,
        endAt: DateTime(2024, 1, 1),
      );
      expect(withEnd.endAt, isNotNull);

      final cleared = withEnd.copyWith(clearEndAt: true);
      expect(cleared.endAt, isNull);
    });

    test('clearOverride nulls the quick-tile override', () {
      const state = TimerState();
      final overridden = state.copyWith(overrideMinutes: 15);
      expect(overridden.overrideMinutes, 15);

      final cleared = overridden.copyWith(clearOverride: true);
      expect(cleared.overrideMinutes, isNull);
    });

    test('unspecified fields are preserved', () {
      const state = TimerState(
        mode: TimerMode.shortBreak,
        status: TimerStatus.paused,
        remaining: 123,
        cyclePosition: 2,
        overrideMinutes: 15,
      );
      final same = state.copyWith(remaining: 100);
      expect(same.mode, TimerMode.shortBreak);
      expect(same.status, TimerStatus.paused);
      expect(same.cyclePosition, 2);
      expect(same.overrideMinutes, 15);
      expect(same.remaining, 100);
    });

    test('status helpers reflect the current status', () {
      const idle = TimerState();
      expect(idle.isIdle, true);
      expect(idle.isRunning, false);
      expect(idle.isPaused, false);

      final running = idle.copyWith(status: TimerStatus.running);
      expect(running.isRunning, true);

      final paused = idle.copyWith(status: TimerStatus.paused);
      expect(paused.isPaused, true);
    });
  });
}
