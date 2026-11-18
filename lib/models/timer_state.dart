import 'timer_mode.dart';

/// Immutable timer state — the Riverpod state machine's single source of truth.
class TimerState {
  final TimerMode mode;
  final TimerStatus status;

  /// Seconds left in the current session.
  final int remaining;

  /// Wall-clock target so ticking stays drift-free, even when
  /// the OS throttles background timers. Null when not running.
  final DateTime? endAt;

  /// Focus sessions completed inside the current long-break cycle.
  final int cyclePosition;

  /// One-shot duration override coming from a Quick Tile.
  final int? overrideMinutes;

  const TimerState({
    this.mode = TimerMode.focus,
    this.status = TimerStatus.idle,
    this.remaining = 25 * 60,
    this.endAt,
    this.cyclePosition = 0,
    this.overrideMinutes,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;

  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? remaining,
    DateTime? endAt,
    bool clearEndAt = false,
    int? cyclePosition,
    int? overrideMinutes,
    bool clearOverride = false,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      cyclePosition: cyclePosition ?? this.cyclePosition,
      overrideMinutes: clearOverride ? null : (overrideMinutes ?? this.overrideMinutes),
    );
  }
}
