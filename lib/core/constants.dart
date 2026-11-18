import 'package:flutter/material.dart';

import '../models/timer_mode.dart';

/// App version mirrored from pubspec.yaml — shown in the home footer.
const kAppVersion = '1.0.0';

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
