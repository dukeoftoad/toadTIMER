import '../core/constants.dart';
import 'timer_mode.dart';

class SessionLog {
  final TimerMode mode;
  final int minutes;
  final DateTime at;

  /// Free-form tag captured from the timer when the session completed
  /// (e.g. "Work", "Study"). Defaults to [kDefaultTag] for older logs.
  final String tag;

  const SessionLog({
    required this.mode,
    required this.minutes,
    required this.at,
    this.tag = kDefaultTag,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'minutes': minutes,
        'at': at.millisecondsSinceEpoch,
        'tag': tag,
      };

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'];
    final minutes = json['minutes'];
    final at = json['at'];
    final tag = json['tag'];
    return SessionLog(
      mode: modeName == 'shortBreak'
          ? TimerMode.shortBreak
          : modeName == 'longBreak'
              ? TimerMode.longBreak
              : TimerMode.focus,
      minutes: minutes is int ? minutes : 25,
      at: DateTime.fromMillisecondsSinceEpoch(at is int ? at : 0),
      tag: tag is String ? tag : kDefaultTag,
    );
  }
}
