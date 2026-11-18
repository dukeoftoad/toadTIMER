import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../data/stats_repository.dart';
import '../core/utils.dart';
import '../models/session_log.dart';
import '../models/timer_settings.dart';

/// ---------- Settings ----------

class SettingsController extends StateNotifier<TimerSettings> {
  SettingsController.withInitial(TimerSettings initial) : super(initial);

  /// Default constructor hydrates asynchronously (used when not overridden).
  SettingsController.hydrating() : super(const TimerSettings.defaults()) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    state = await SettingsRepository.load();
  }

  Future<void> update(TimerSettings next) async {
    state = next;
    await SettingsRepository.save(next);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, TimerSettings>(
  SettingsController.hydrating.new,
);

/// ---------- Stats / session history ----------

class StatsState {
  final List<SessionLog> history;

  const StatsState(this.history);

  int get sessionsToday {
    final today = dayKey(DateTime.now());
    return history.where((h) => h.mode.name == 'focus' && dayKey(h.at) == today).length;
  }

  int get minutesToday {
    final today = dayKey(DateTime.now());
    return history
        .where((h) => h.mode.name == 'focus' && dayKey(h.at) == today)
        .fold(0, (acc, h) => acc + h.minutes);
  }

  int get allTime =>
      history.where((h) => h.mode.name == 'focus').length;

  int get streak => calcStreak(history);
}

class StatsController extends StateNotifier<StatsState> {
  StatsController.withInitial(StatsState initial) : super(initial);

  StatsController.hydrating()
      : super(const StatsState([])) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    state = StatsState(await StatsRepository.load());
  }

  Future<void> addSession(SessionLog log) async {
    state = StatsState([...state.history, log]);
    await StatsRepository.save(state.history);
  }

  Future<void> clear() async {
    state = const StatsState([]);
    await StatsRepository.save(state.history);
  }
}

final statsProvider = StateNotifierProvider<StatsController, StatsState>(
  StatsController.hydrating.new,
);

/// ---------- In-app messages (snackbars) ----------

class UiMessage {
  final int id;
  final String text;

  const UiMessage(this.id, this.text);
}

class UiMessenger extends StateNotifier<UiMessage?> {
  UiMessenger() : super(null);

  void show(String text) => state = UiMessage(
        DateTime.now().millisecondsSinceEpoch,
        text,
      );

  void clear() => state = null;
}

final uiMessengerProvider = StateNotifierProvider<UiMessenger, UiMessage?>(
  UiMessenger.new,
);
