import 'package:flutter/material.dart';

import '../models/timer_mode.dart';

/// App version mirrored from pubspec.yaml — shown in the home footer.
const kAppVersion = '1.2.0';

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
  Color(0xFFA3E635), // General  - frog lime (the family brand hue)
  Color(0xFF2DD4BF), // Work      - teal
  Color(0xFF34D399), // Study     - emerald
  Color(0xFFFBBF24), // Reading   - amber
  Color(0xFF60A5FA), // Coding    - sky (only blue accent, scoped to a chip)
  Color(0xFFF472B6), // Creative  - pink
];

/// Map a tag string to its color, falling back to the General accent.
Color tagColor(String tag) {
  final i = kTags.indexOf(tag);
  return i < 0 ? kTagColors[0] : kTagColors[i];
}

/// Brand palette — the toadmark family ink-and-frog design, shared with
/// toadHEALTH and the rest of the toad apps. Deep ink surfaces, frog-lime
/// accents and a faint lime halo everywhere something is alive.
class AppColors {
  AppColors._();

  // Family ink scale (screens and cards are cut from these).
  static const ink950 = Color(0xFF070B0A);
  static const ink900 = Color(0xFF0B100F);
  static const ink850 = Color(0xFF0F1614);
  static const ink800 = Color(0xFF131A18);
  static const ink700 = Color(0xFF1A2320);
  static const ink600 = Color(0xFF212D29);

  // Frog lime — the family primary.
  static const frog = Color(0xFF84CC16);
  static const frog400 = Color(0xFFA3E635);
  static const frog600 = Color(0xFF65A30D);
  static const glow = Color(0x5584CC16); // the family halo

  // Supporting family hues.
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const teal400 = Color(0xFF2DD4BF);
  static const amber400 = Color(0xFFFBBF24);
  static const coral400 = Color(0xFFFB7185);
  static const violet400 = Color(0xFFA78BFA);

  // Hairlines and muted text.
  static const line = Color(0xFF1F2A26);
  static const mute = Color(0xFF8A9B92);

  // Text.
  static const textPrimary = Color(0xFFF3F4F6);
  static const textSecondary = Color(0x8CFFFFFF); // white54
  static const textFaint = Color(0x59FFFFFF); // white35
  static const iconLight = Color(0xFFCDE7A0);
  static const onGradient = Color(0xFF06140C);

  // Composite surfaces.
  static const background = ink900;
  static const surfaceLow = ink850;
  static const surface = ink800;
  static const outline = Color(0x14FFFFFF); // white8
  static const cardFill = Color(0x0AFFFFFF); // white4
  static const cardFillHover = Color(0x14FFFFFF); // white8
  static const cardTop = Color(0xE61A2320); // rgba(26,35,32,.9)
  static const cardBottom = Color(0xE6131A18); // rgba(19,26,24,.9)
}

/// One-tap launch presets — the in-app Quick Tiles.
class QuickTilePreset {
  final String label;
  final String hint;
  final int minutes;
  final TimerMode mode;
  final IconData icon;

  /// Asset name inside assets/icons/ — the family stroke icon rendered for
  /// this preset in the grid.
  final String svg;

  const QuickTilePreset({
    required this.label,
    required this.hint,
    required this.minutes,
    required this.mode,
    required this.icon,
    required this.svg,
  });
}

const kQuickTilePresets = [
  QuickTilePreset(
    label: 'Sprint',
    hint: 'quick hit',
    minutes: 15,
    mode: TimerMode.focus,
    icon: Icons.bolt,
    svg: 'zap.svg',
  ),
  QuickTilePreset(
    label: 'Classic',
    hint: 'the standard',
    minutes: 25,
    mode: TimerMode.focus,
    icon: Icons.track_changes,
    svg: 'timer.svg',
  ),
  QuickTilePreset(
    label: 'Deep Work',
    hint: 'long haul',
    minutes: 50,
    mode: TimerMode.focus,
    icon: Icons.psychology,
    svg: 'target.svg',
  ),
  QuickTilePreset(
    label: 'Marathon',
    hint: 'full send',
    minutes: 90,
    mode: TimerMode.focus,
    icon: Icons.terrain,
    svg: 'flag.svg',
  ),
  QuickTilePreset(
    label: 'Break',
    hint: 'stretch + sip',
    minutes: 5,
    mode: TimerMode.shortBreak,
    icon: Icons.local_cafe,
    svg: 'coffee.svg',
  ),
  QuickTilePreset(
    label: 'Reset',
    hint: 'full recharge',
    minutes: 15,
    mode: TimerMode.longBreak,
    icon: Icons.chair,
    svg: 'refresh.svg',
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
