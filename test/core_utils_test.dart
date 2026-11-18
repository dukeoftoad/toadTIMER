import 'package:flutter_test/flutter_test.dart';

import 'package:toadtimer/core/utils.dart';
import 'package:toadtimer/models/session_log.dart';
import 'package:toadtimer/models/timer_mode.dart';

void main() {
  group('formatClock', () {
    test('formats seconds as mm:ss', () {
      expect(formatClock(0), '00:00');
      expect(formatClock(5), '00:05');
      expect(formatClock(65), '01:05');
      expect(formatClock(599), '09:59');
      expect(formatClock(600), '10:00');
      expect(formatClock(1500), '25:00');
      // minutes keep counting past one hour (no hour rollover by design)
      expect(formatClock(3600), '60:00');
    });

    test('clamps negative input to zero', () {
      expect(formatClock(-1), '00:00');
      expect(formatClock(-90), '00:00');
    });
  });

  group('dayKey', () {
    test('formats a date as YYYY-MM-DD with zero padding', () {
      expect(dayKey(DateTime(2024, 1, 8)), '2024-01-08');
      expect(dayKey(DateTime(2024, 12, 31)), '2024-12-31');
      expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('relativeTime', () {
    test('describes recency buckets', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(seconds: 30))), 'just now');
      expect(relativeTime(now.subtract(const Duration(minutes: 5))), '5 min ago');
      expect(relativeTime(now.subtract(const Duration(hours: 3))), '3 h ago');
      expect(relativeTime(now.subtract(const Duration(days: 2))), '2 d ago');
    });
  });

  group('calcStreak', () {
    SessionLog focusOn(DateTime at) =>
        SessionLog(mode: TimerMode.focus, minutes: 25, at: at);

    test('is zero for an empty history', () {
      expect(calcStreak(const []), 0);
    });

    test('counts a single session today', () {
      final streak = calcStreak([focusOn(DateTime.now())]);
      expect(streak, 1);
    });

    test('counts consecutive days back from today', () {
      final now = DateTime.now();
      final streak = calcStreak([
        focusOn(now),
        focusOn(now.subtract(const Duration(days: 1))),
        focusOn(now.subtract(const Duration(days: 2))),
      ]);
      expect(streak, 3);
    });

    test('still counts when today has no session but yesterday does', () {
      final now = DateTime.now();
      final streak = calcStreak([
        focusOn(now.subtract(const Duration(days: 1))),
        focusOn(now.subtract(const Duration(days: 2))),
      ]);
      expect(streak, 2);
    });

    test('breaks at the first gap', () {
      final now = DateTime.now();
      final streak = calcStreak([
        focusOn(now),
        focusOn(now.subtract(const Duration(days: 1))),
        // gap: 2 days ago missing
        focusOn(now.subtract(const Duration(days: 3))),
        focusOn(now.subtract(const Duration(days: 4))),
      ]);
      expect(streak, 2);
    });

    test('returns zero when the last focus day is too old', () {
      final now = DateTime.now();
      final streak = calcStreak([
        focusOn(now.subtract(const Duration(days: 5))),
        focusOn(now.subtract(const Duration(days: 6))),
      ]);
      expect(streak, 0);
    });

    test('ignores break sessions for streak purposes', () {
      final now = DateTime.now();
      final streak = calcStreak([
        SessionLog(mode: TimerMode.shortBreak, minutes: 5, at: now),
        SessionLog(mode: TimerMode.longBreak, minutes: 15, at: now),
      ]);
      expect(streak, 0);
    });
  });
}
