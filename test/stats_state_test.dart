import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toadtimer/data/settings_repository.dart';
import 'package:toadtimer/data/stats_repository.dart';
import 'package:toadtimer/models/session_log.dart';
import 'package:toadtimer/models/timer_mode.dart';
import 'package:toadtimer/models/timer_settings.dart';
import 'package:toadtimer/state/providers.dart';

SessionLog session(TimerMode mode, int minutes, DateTime at) =>
    SessionLog(mode: mode, minutes: minutes, at: at);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsRepository', () {
    test('returns defaults when nothing is stored', () async {
      final settings = await SettingsRepository.load();
      expect(settings.focusMin, 25);
      expect(settings.longEvery, 4);
    });

    test('roundtrips a saved settings object', () async {
      const saved = TimerSettings(
        focusMin: 45,
        shortMin: 7,
        longMin: 22,
        longEvery: 5,
        autoStartBreaks: false,
        autoStartFocus: true,
        soundOn: false,
        notifyOn: true,
      );
      await SettingsRepository.save(saved);
      final loaded = await SettingsRepository.load();
      expect(loaded.focusMin, 45);
      expect(loaded.shortMin, 7);
      expect(loaded.longMin, 22);
      expect(loaded.longEvery, 5);
      expect(loaded.autoStartBreaks, false);
      expect(loaded.autoStartFocus, true);
      expect(loaded.soundOn, false);
      expect(loaded.notifyOn, true);
    });
  });

  group('StatsRepository', () {
    test('returns an empty history when nothing is stored', () async {
      expect(await StatsRepository.load(), isEmpty);
    });

    test('caps the persisted history at 200 entries', () async {
      final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final logs = List.generate(
        201,
        (i) => session(TimerMode.focus, 25, base.add(Duration(minutes: i))),
      );
      await StatsRepository.save(logs);

      final loaded = await StatsRepository.load();
      expect(loaded.length, 200);
      // the oldest entry was trimmed, the newest survived
      expect(loaded.first.at.millisecondsSinceEpoch, base.add(const Duration(minutes: 1)).millisecondsSinceEpoch);
      expect(loaded.last.at.millisecondsSinceEpoch, base.add(const Duration(minutes: 200)).millisecondsSinceEpoch);
    });

    test('roundtrips break sessions too', () async {
      final at = DateTime.fromMillisecondsSinceEpoch(1700000015000);
      await StatsRepository.save([
        session(TimerMode.shortBreak, 5, at),
        session(TimerMode.longBreak, 15, at),
      ]);
      final loaded = await StatsRepository.load();
      expect(loaded.length, 2);
      expect(loaded[0].mode, TimerMode.shortBreak);
      expect(loaded[1].mode, TimerMode.longBreak);
    });
  });

  group('StatsState', () {
    test('aggregates today / all-time counters from focus sessions only', () {
      final noon = DateTime.now();
      final today = DateTime(noon.year, noon.month, noon.day, 12);
      final yesterday = today.subtract(const Duration(days: 1));

      final state = StatsState([
        session(TimerMode.focus, 25, today),
        session(TimerMode.focus, 50, today.subtract(const Duration(hours: 1))),
        session(TimerMode.shortBreak, 5, today), // breaks don't count
        session(TimerMode.focus, 25, yesterday),
      ]);

      expect(state.sessionsToday, 2);
      expect(state.minutesToday, 75);
      expect(state.allTime, 3);
      expect(state.streak, 2);
    });

    test('is zeroed on an empty history', () {
      const state = StatsState([]);
      expect(state.sessionsToday, 0);
      expect(state.minutesToday, 0);
      expect(state.allTime, 0);
      expect(state.streak, 0);
    });
  });

  group('StatsController', () {
    test('addSession records and persists a session', () async {
      final container = ProviderContainer(overrides: [
        statsProvider.overrideWith(
          (ref) => StatsController.withInitial(const StatsState([])),
        ),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(statsProvider.notifier);
      await controller.addSession(
        session(TimerMode.focus, 25, DateTime.now()),
      );

      final state = container.read(statsProvider);
      expect(state.history.length, 1);
      expect(state.sessionsToday, 1);
      expect(state.minutesToday, 25);

      final persisted = await StatsRepository.load();
      expect(persisted.length, 1);
    });

    test('clear wipes the log and storage', () async {
      final container = ProviderContainer(overrides: [
        statsProvider.overrideWith(
          (ref) => StatsController.withInitial(const StatsState([])),
        ),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(statsProvider.notifier);
      await controller.addSession(
        session(TimerMode.focus, 25, DateTime.now()),
      );
      await controller.clear();

      expect(container.read(statsProvider).history, isEmpty);
      expect(await StatsRepository.load(), isEmpty);
    });
  });

  group('SettingsController', () {
    test('update replaces state and persists it', () async {
      final container = ProviderContainer(overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsController.withInitial(const TimerSettings.defaults()),
        ),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(settingsProvider.notifier);
      await controller.update(
        container.read(settingsProvider).copyWith(focusMin: 40, longEvery: 6),
      );

      expect(container.read(settingsProvider).focusMin, 40);
      expect(container.read(settingsProvider).longEvery, 6);

      final persisted = await SettingsRepository.load();
      expect(persisted.focusMin, 40);
      expect(persisted.longEvery, 6);
    });
  });
}
