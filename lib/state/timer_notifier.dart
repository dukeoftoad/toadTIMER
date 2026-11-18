import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/timer_mode.dart';
import '../models/timer_settings.dart';
import '../models/timer_state.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../services/tile_service.dart';
import '../models/session_log.dart';
import 'providers.dart';

/// The Pomodoro state machine — Riverpod's StateNotifier as the
/// single source of truth (Flutter's answer to provider/riverpod practice).
///
/// Transitions:
///   idle -> running (start / quickStart)
///   running -> paused (pause)
///   running -> complete (tick reaches 0) -> next mode, auto-start if enabled
///
/// Side effects (chime, scheduled notifications, quick-settings tile sync)
/// are driven from the same transitions so the UI layer stays dumb.
class TimerNotifier extends StateNotifier<TimerState> {
  /// [clock] is injectable so unit tests can drive the wall clock
  /// deterministically; production code uses the default DateTime.now.
  TimerNotifier(this._ref, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now,
        super(const TimerState()) {
    _applySettingsToRemaining();
  }

  final Ref _ref;
  final DateTime Function() _now;
  Timer? _ticker;

  TimerSettings get _settings => _ref.read(settingsProvider);

  int _totalSeconds(TimerMode mode, int? overrideMinutes) {
    final minutes = overrideMinutes ?? _settings.minutesFor(mode);
    return (minutes < 1 ? 1 : minutes) * 60;
  }

  /// Settings changed while idle -> refresh the displayed duration.
  void onSettingsChanged() {
    if (!state.isRunning) {
      _applySettingsToRemaining();
    }
  }

  void _applySettingsToRemaining() {
    if (state.isIdle && state.overrideMinutes == null) {
      final secs = _totalSeconds(state.mode, null);
      // Re-plan as well so the ring's total stays in sync with the new
      // duration while idle (a stale plan would fake a partial progress).
      state = state.copyWith(remaining: secs, plannedSeconds: secs);
    }
  }

  // ----- actions -----

  void start() {
    if (state.isRunning) return;
    // A fresh session (idle, or drained to zero while paused) gets a new
    // plan; resuming a paused session keeps the original one.
    final fresh = state.isIdle || state.remaining <= 0;
    if (state.remaining <= 0) {
      state = state.copyWith(
        remaining: _totalSeconds(state.mode, state.overrideMinutes),
      );
    }
    state = state.copyWith(
      status: TimerStatus.running,
      endAt: _now().add(Duration(seconds: state.remaining)),
      plannedSeconds: fresh ? state.remaining : null,
    );
    _startTicker();
    _scheduleForRemaining();
    TileBridge.instance.setActive(true);
  }

  void pause() {
    if (!state.isRunning || state.endAt == null) return;
    final left = state.endAt!.difference(_now()).inSeconds;
    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.paused,
      remaining: left < 0 ? 0 : left,
      clearEndAt: true,
    );
    NotificationService.instance.cancelScheduled();
    TileBridge.instance.setActive(false);
  }

  void reset() {
    _ticker?.cancel();
    NotificationService.instance.cancelScheduled();
    state = state.copyWith(
      status: TimerStatus.idle,
      remaining: _totalSeconds(state.mode, null),
      clearEndAt: true,
      clearOverride: true,
      clearPlanned: true,
    );
    TileBridge.instance.setActive(false);
  }

  void selectMode(TimerMode mode) {
    if (mode == state.mode && state.isIdle) return;
    _ticker?.cancel();
    NotificationService.instance.cancelScheduled();
    state = state.copyWith(
      mode: mode,
      status: TimerStatus.idle,
      remaining: _totalSeconds(mode, null),
      clearEndAt: true,
      clearOverride: true,
      clearPlanned: true,
    );
    // Switching modes abandons the running session — mirror pause()/reset()
    // so the system Quick Tile doesn't keep claiming a session is active.
    TileBridge.instance.setActive(false);
  }

  /// Tag the current (focus) session. The tag rides along on the timer state
  /// and is stamped onto the [SessionLog] when the session completes, so it
  /// can be broken down on the insights screen. Safe to call mid-run.
  void setTag(String tag) {
    if (state.tag == tag) return;
    state = state.copyWith(tag: tag);
  }

  /// Quick Tile tap: launch a preset session immediately.
  void quickStart(TimerMode mode, int minutes) {
    _ticker?.cancel();
    final secs = (minutes < 1 ? 1 : minutes) * 60;
    state = state.copyWith(
      mode: mode,
      overrideMinutes: minutes,
      remaining: secs,
      status: TimerStatus.running,
      endAt: _now().add(Duration(seconds: secs)),
      plannedSeconds: secs,
    );
    _startTicker();
    _scheduleForRemaining();
    TileBridge.instance.setActive(true);
  }

  void skip() => _finish(counted: false);

  /// Called on app resume: recalculate from wall clock (backgrounded
  /// timers get throttled) and consume any pending Quick Tile action.
  Future<void> resync() async {
    final action = await TileBridge.instance.consumePendingAction();
    if (action == 'start_focus') {
      if (!state.isRunning) {
        quickStart(TimerMode.focus, _settings.focusMin);
      } else {
        // already running — treat as a no-op, tile state stays active
        TileBridge.instance.setActive(true);
      }
      return;
    }
    if (action == 'stop') {
      if (state.isRunning) pause();
      return;
    }
    if (state.isRunning && state.endAt != null) {
      tick();
    }
  }

  // ----- internals -----

  void tick() {
    if (!state.isRunning || state.endAt == null) return;
    final msLeft = state.endAt!.difference(_now()).inMilliseconds;
    final secsLeft = (msLeft / 1000).ceil();
    if (secsLeft <= 0) {
      _finish(counted: true);
    } else if (secsLeft != state.remaining) {
      state = state.copyWith(remaining: secsLeft);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  void _scheduleForRemaining() {
    // Respect the user's notification setting — no alarm when it is off.
    if (!_settings.notifyOn) return;
    NotificationService.instance
        .scheduleSessionEnd(mode: state.mode, duration: Duration(seconds: state.remaining));
  }

  void _finish({required bool counted}) {
    _ticker?.cancel();
    final s = state;
    final settings = _settings;
    final minutes = s.overrideMinutes ?? settings.minutesFor(s.mode);

    var cycle = s.cyclePosition;
    TimerMode next;
    if (s.mode == TimerMode.focus) {
      if (counted) {
        cycle += 1;
        next = cycle % settings.longEvery == 0
            ? TimerMode.longBreak
            : TimerMode.shortBreak;
      } else {
        next = (cycle > 0 && cycle % settings.longEvery == 0)
            ? TimerMode.longBreak
            : TimerMode.shortBreak;
      }
    } else {
      next = TimerMode.focus;
      if (s.mode == TimerMode.longBreak) cycle = 0;
    }

    var prevFocusMinutesToday = 0;
    if (counted) {
      if (s.mode == TimerMode.focus) {
        // Capture today's total BEFORE adding so we can detect a goal crossing.
        prevFocusMinutesToday = _ref.read(statsProvider).minutesToday;
      }
      _ref.read(statsProvider.notifier).addSession(
            SessionLog(
              mode: s.mode,
              minutes: minutes,
              at: _now(),
              tag: s.tag,
            ),
          );
    }

    final auto = s.mode == TimerMode.focus ? settings.autoStartBreaks : settings.autoStartFocus;
    final nextSeconds = _totalSeconds(next, null);
    final now = _now();

    state = s.copyWith(
      mode: next,
      cyclePosition: cycle,
      clearOverride: true,
      remaining: nextSeconds,
      status: auto ? TimerStatus.running : TimerStatus.idle,
      endAt: auto ? now.add(Duration(seconds: nextSeconds)) : null,
      clearEndAt: !auto,
      plannedSeconds: nextSeconds,
    );

    if (auto) {
      _startTicker();
      _scheduleForRemaining();
      TileBridge.instance.setActive(true);
    } else {
      NotificationService.instance.cancelScheduled();
      TileBridge.instance.setActive(false);
    }

    // side effects
    final messenger = _ref.read(uiMessengerProvider.notifier);
    if (!counted) {
      return;
    }
    if (settings.soundOn) {
      SoundService.instance.playChime();
    }
    if (s.mode == TimerMode.focus) {
      final newMinutes = prevFocusMinutesToday + minutes;
      if (prevFocusMinutesToday < settings.dailyGoalMin &&
          newMinutes >= settings.dailyGoalMin) {
        messenger.show(
            'Daily goal smashed - $newMinutes focus minutes. Legendary hop!');
      } else {
        messenger.show('Focus session complete - nice hop. Break time.');
      }
    } else {
      messenger.show('Break is over - back to it.');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// Watchlist of presets highlighted as "live" is derived by the UI from
/// [TimerState] + [TimerSettings]; nothing extra to store here.

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifier = TimerNotifier(ref);
  ref.listen<TimerSettings>(settingsProvider, (_, __) {
    notifier.onSettingsChanged();
  });
  return notifier;
});

/// Convenience: the preset a quick tile would currently flag as live.
final liveQuickTileProvider = Provider<QuickTilePreset?>((ref) {
  final timer = ref.watch(timerProvider);
  final settings = ref.watch(settingsProvider);
  for (final preset in kQuickTilePresets) {
    final presetMinutes = preset.minutes;
    final currentMinutes =
        timer.overrideMinutes ?? settings.minutesFor(timer.mode);
    if (timer.mode == preset.mode && currentMinutes == presetMinutes) {
      return preset;
    }
  }
  return null;
});
