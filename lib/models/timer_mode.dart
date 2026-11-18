import 'package:flutter/material.dart';

enum TimerMode { focus, shortBreak, longBreak }

extension TimerModeX on TimerMode {
  String get label => switch (this) {
        TimerMode.focus => 'Focus',
        TimerMode.shortBreak => 'Short Break',
        TimerMode.longBreak => 'Long Break',
      };

  String get tagline => switch (this) {
        TimerMode.focus => 'Ribbit. Head down, hop to it.',
        TimerMode.shortBreak => 'Stretch those legs. You earned it.',
        TimerMode.longBreak => 'Full pond mode. Recharge deep.',
      };

  Color get from => switch (this) {
        TimerMode.focus => const Color(0xFF10B981),
        TimerMode.shortBreak => const Color(0xFF14B8A6),
        TimerMode.longBreak => const Color(0xFFF59E0B),
      };

  Color get to => switch (this) {
        TimerMode.focus => const Color(0xFFA3E635),
        TimerMode.shortBreak => const Color(0xFF34D399),
        TimerMode.longBreak => const Color(0xFFFB923C),
      };

  Color get accent => switch (this) {
        TimerMode.focus => const Color(0xFF34D399),
        TimerMode.shortBreak => const Color(0xFF2DD4BF),
        TimerMode.longBreak => const Color(0xFFFBBF24),
      };

  /// Compact icon used in mode tabs and history rows.
  IconData get tabIcon => switch (this) {
        TimerMode.focus => Icons.adjust_rounded,
        TimerMode.shortBreak => Icons.coffee_rounded,
        TimerMode.longBreak => Icons.spa_rounded,
      };
}

enum TimerStatus { idle, running, paused }
