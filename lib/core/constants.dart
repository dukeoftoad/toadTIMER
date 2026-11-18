import 'package:flutter/material.dart';

import '../models/timer_mode.dart';

/// App version mirrored from pubspec.yaml — shown in the home footer.
const kAppVersion = '1.1.0';

/// Maximum session-log entries kept in memory and on disk. Older entries are
/// trimmed from the tail so long-running sessions never leak memory.
const kMaxHistory = 200;

/// Default daily focus-minutes goal (2 hours).
const kDailyGoalDefault = 120;

/// Default tag attached to a focus session when the user hasn't picked one.
const kDefaultTag = 'General';

/// Selectable focus-session tags, shown as chips above the timer controls.
/// Order is stable so the chip row and the insights breakdown line up.
const kTags = <String>['General', 'Work', 'Study', 'Reading', 'Coding', 'Creative'];

/// A display color per tag — indexed by position in [kTags]. Keeping this next
/// to [kTags] guarantees the two stay in sync.
const kTagColors = <Color>[
  Color(0xFF34D399), // General  - emerald
  Color(0xFF2DD4BF), // Work      - teal
  Color(0xFFA3E635), // Study     - lime
  Color(0xFFFBBF24), // Reading   - amber
  Color(0xFF60A5FA), // Coding    - sky (only blue accent, scoped to a chip)
  Color(0xFFF472B6), // Creative  - pink
];

/// Map a tag string to its color, falling back to the General accent.
Color tagColor(String tag) {
  final i = kTags.indexOf(tag);
  return i < 0 ? kTagColors[0] : kTagColors[i];
}

/// Brand palette — "toad pond" dark theme.
class AppColors {
  AppColors._();

  static const background = Color(0xFF09090B);
  static const surfaceLow = Color(0xFF101014);
  static const surface = Color(0xFF16161B);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0x8CFFFFFF); // white54
  static const textFaint = Color(0x59FFFFFF); // white35
  static const outline = Color(0x14FFFFFF); // white8
  static const cardFill = Color(0x0AFFFFFF); // white4
  static const cardFillHover = Color(0x14FFFFFF); // white8
}

/// One-tap launch presets — the in-app Quick Tiles.
class QuickTilePreset {
  final String label;
  final String hint;
  final int minutes;
  final TimerMode mode;
  final IconData icon;

  const QuickTilePreset({
    required this.label,
    required this.hint,
    required this.minutes,
    required this.mode,
    required this.icon,
  });
}

const kQuickTilePresets = [
  QuickTilePreset(
    label: 'Sprint',
    hint: 'quick hit',
    minutes: 15,
    mode: TimerMode.focus,
    icon: Icons.bolt,
  ),
  QuickTilePreset(
    label: 'Classic',
    hint: 'the standard',
    minutes: 25,
    mode: TimerMode.focus,
    icon: Icons.track_changes,
  ),
  QuickTilePreset(
    label: 'Deep Work',
    hint: 'long haul',
    minutes: 50,
    mode: TimerMode.focus,
    icon: Icons.psychology,
  ),
  QuickTilePreset(
    label: 'Marathon',
    hint: 'full send',
    minutes: 90,
    mode: TimerMode.focus,
    icon: Icons.terrain,
  ),
  QuickTilePreset(
    label: 'Break',
    hint: 'stretch + sip',
    minutes: 5,
    mode: TimerMode.shortBreak,
    icon: Icons.local_cafe,
  ),
  QuickTilePreset(
    label: 'Reset',
    hint: 'full recharge',
    minutes: 15,
    mode: TimerMode.longBreak,
    icon: Icons.chair,
  ),
];

const kTips = [
  'Long-press your quick settings and pin the Toad Focus tile for one-tap sessions.',
  'Quick Tiles launch a session instantly, mid-flow.',
  'Four focus rounds earn a long break. The dots under the ring track it.',
  'One session, one task. Park everything else for later.',
  'Small starts win: a 15 minute Sprint beats a skipped 50 minute plan.',
  'Turn on notifications so breaks never quietly run long.',
];
