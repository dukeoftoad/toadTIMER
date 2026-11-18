import 'timer_mode.dart';

class SessionLog {
  final TimerMode mode;
  final int minutes;
  final DateTime at;

  const SessionLog({
    required this.mode,
    required this.minutes,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'minutes': minutes,
        'at': at.millisecondsSinceEpoch,
      };

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final modeName = json['mode'];
    final minutes = json['minutes'];
    final at = json['at'];
    return SessionLog(
      mode: modeName == 'shortBreak'
          ? TimerMode.shortBreak
          : modeName == 'longBreak'
              ? TimerMode.longBreak
              : TimerMode.focus,
      minutes: minutes is int ? minutes : 25,
      at: DateTime.fromMillisecondsSinceEpoch(at is int ? at : 0),
    );
  }
}
