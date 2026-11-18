import '../models/session_log.dart';
import '../models/timer_mode.dart';

String formatClock(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final m = (safe ~/ 60).toString().padLeft(2, '0');
  final s = (safe % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String dayKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

int calcStreak(List<SessionLog> history) {
  final days = <String>{};
  for (final log in history) {
    if (log.mode == TimerMode.focus) days.add(dayKey(log.at));
  }
  if (days.isEmpty) return 0;

  var streak = 0;
  var cursor = DateTime.now();
  if (!days.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(dayKey(cursor))) return 0;
  }
  while (days.contains(dayKey(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
