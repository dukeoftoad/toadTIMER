import '../core/constants.dart';
import 'timer_mode.dart';

class TimerSettings {
  final int focusMin;
  final int shortMin;
  final int longMin;
  final int longEvery;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool soundOn;
  final bool notifyOn;

  /// Daily focus-minutes goal — drives the goal card and the goal-reached
  /// celebration when a session pushes today's total across the line.
  final int dailyGoalMin;

  const TimerSettings({
    required this.focusMin,
    required this.shortMin,
    required this.longMin,
    required this.longEvery,
    required this.autoStartBreaks,
    required this.autoStartFocus,
    required this.soundOn,
    required this.notifyOn,
    this.dailyGoalMin = kDailyGoalDefault,
  });

  const TimerSettings.defaults()
      : focusMin = 25,
        shortMin = 5,
        longMin = 15,
        longEvery = 4,
        autoStartBreaks = true,
        autoStartFocus = false,
        soundOn = true,
        notifyOn = false,
        dailyGoalMin = kDailyGoalDefault;

  int minutesFor(TimerMode mode) => switch (mode) {
        TimerMode.focus => focusMin,
        TimerMode.shortBreak => shortMin,
        TimerMode.longBreak => longMin,
      };

  TimerSettings copyWith({
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? longEvery,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? soundOn,
    bool? notifyOn,
    int? dailyGoalMin,
  }) {
    return TimerSettings(
      focusMin: focusMin ?? this.focusMin,
      shortMin: shortMin ?? this.shortMin,
      longMin: longMin ?? this.longMin,
      longEvery: longEvery ?? this.longEvery,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      soundOn: soundOn ?? this.soundOn,
      notifyOn: notifyOn ?? this.notifyOn,
      dailyGoalMin: dailyGoalMin ?? this.dailyGoalMin,
    );
  }

  Map<String, dynamic> toJson() => {
        'focusMin': focusMin,
        'shortMin': shortMin,
        'longMin': longMin,
        'longEvery': longEvery,
        'autoStartBreaks': autoStartBreaks,
        'autoStartFocus': autoStartFocus,
        'soundOn': soundOn,
        'notifyOn': notifyOn,
        'dailyGoalMin': dailyGoalMin,
      };

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) {
      final v = json[key];
      return v is int ? v : (v is num ? v.round() : fallback);
    }

    bool readBool(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    return TimerSettings(
      focusMin: readInt('focusMin', 25),
      shortMin: readInt('shortMin', 5),
      longMin: readInt('longMin', 15),
      longEvery: readInt('longEvery', 4),
      autoStartBreaks: readBool('autoStartBreaks', true),
      autoStartFocus: readBool('autoStartFocus', false),
      soundOn: readBool('soundOn', true),
      notifyOn: readBool('notifyOn', false),
      dailyGoalMin: readInt('dailyGoalMin', kDailyGoalDefault),
    );
  }
}
