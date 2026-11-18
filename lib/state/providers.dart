import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../data/settings_repository.dart';
import '../data/stats_repository.dart';
import '../models/session_log.dart';
import '../models/timer_mode.dart';
import '../models/timer_settings.dart';

/// ---------- Settings ----------

class SettingsController extends StateNotifier<TimerSettings> {
  SettingsController.withInitial(super.initial);

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
  (ref) => SettingsController.hydrating(),
);

/// ---------- Stats / session history ----------

class StatsState {
  final List<SessionLog> history;

  const StatsState(this.history);

  bool _isFocus(SessionLog h) => h.mode == TimerMode.focus;

  String _todayKey() => dayKey(DateTime.now());

  int get sessionsToday =>
      history.where((h) => _isFocus(h) && dayKey(h.at) == _todayKey()).length;

  int get minutesToday => history
      .where((h) => _isFocus(h) && dayKey(h.at) == _todayKey())
      .fold(0, (acc, h) => acc + h.minutes);

  int get allTime => history.where(_isFocus).length;

  int get streak => calcStreak(history);

  /// Focus minutes for the last 7 days, oldest -> newest (index 6 = today).
  /// Drives the weekly chart on the home and insights screens.
  List<int> get weeklyMinutes {
    final today = DateTime.now();
    final byDay = <String, int>{};
    for (final h in history) {
      if (!_isFocus(h)) continue;
      final k = dayKey(h.at);
      byDay[k] = (byDay[k] ?? 0) + h.minutes;
    }
    return List<int>.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return byDay[dayKey(d)] ?? 0;
    });
  }

  int get weekTotal => weeklyMinutes.fold(0, (a, b) => a + b);

  /// Tag -> total focus minutes across all history. Used by the insights
  /// breakdown. Tags with zero minutes are omitted.
  Map<String, int> get tagMinutes {
    final m = <String, int>{};
    for (final h in history) {
      if (!_isFocus(h)) continue;
      m[h.tag] = (m[h.tag] ?? 0) + h.minutes;
    }
    return m;
  }

  /// Focus minutes today, grouped by tag.
  Map<String, int> get tagMinutesToday {
    final today = _todayKey();
    final m = <String, int>{};
    for (final h in history) {
      if (!_isFocus(h) || dayKey(h.at) != today) continue;
      m[h.tag] = (m[h.tag] ?? 0) + h.minutes;
    }
    return m;
  }
}

class StatsController extends StateNotifier<StatsState> {
  StatsController.withInitial(super.initial);

  StatsController.hydrating()
      : super(const StatsState([])) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    state = StatsState(await StatsRepository.load());
  }

  Future<void> addSession(SessionLog log) async {
    // Trim in-memory history to the same cap as the repository so a long-lived
    // session can't grow the list unbounded while the app stays open.
    final next = [...state.history, log];
    final trimmed = next.length > kMaxHistory
        ? next.sublist(next.length - kMaxHistory)
        : next;
    state = StatsState(trimmed);
    await StatsRepository.save(state.history);
  }

  Future<void> clear() async {
    state = const StatsState([]);
    await StatsRepository.save(state.history);
  }
}

final statsProvider = StateNotifierProvider<StatsController, StatsState>(
  (ref) => StatsController.hydrating(),
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
  (ref) => UiMessenger(),
);
