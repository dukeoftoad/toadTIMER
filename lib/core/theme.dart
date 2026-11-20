import 'package:flutter/material.dart';

import 'constants.dart';

/// Gradients from the toadmark family design (135deg = topLeft -> bottomRight).
class AppGradients {
  AppGradients._();

  /// The signature frog gradient — lime into emerald.
  static const LinearGradient frog = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA3E635), Color(0xFF10B981)],
  );

  /// Emerald into frog lime — activity-family accents.
  static const LinearGradient emeraldFrog = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF84CC16)],
  );

  /// Bottom-up lime bar used by chart painters.
  static const LinearGradient barFrog = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF65A30D), Color(0xFFA3E635)],
  );

  /// Phone screen background wash (180deg ink).
  static const LinearGradient screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.ink900, Color(0xFF0C1311)],
  );

  /// Card background wash (180deg ink700 -> ink800).
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.cardTop, AppColors.cardBottom],
  );
}

/// Text helpers: Inter (body) and Sora (display) — bundled with the app, so
/// typography never waits on a network fetch.
class AppText {
  AppText._();

  static TextStyle inter({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sora({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.01 * size,
    );
  }

  /// Small uppercase muted label (tracking-wide).
  static TextStyle upper({
    double size = 11,
    Color color = AppColors.mute,
    FontWeight weight = FontWeight.w700,
  }) {
    return inter(size: size, weight: weight, color: color, letterSpacing: 0.3);
  }
}

/// toadmark family theme — deep ink surfaces, frog-lime accents and the
/// bundled Inter/Sora type pair, matching toadHEALTH and the rest of the
/// toad apps.
class ToadTheme {
  ToadTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Inter',
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.frog,
        onPrimary: AppColors.onGradient,
        secondary: AppColors.teal400,
        surface: AppColors.surface,
        error: AppColors.coral400,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink700,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.frog,
        inactiveTrackColor: Color(0x1FFFFFFF),
        thumbColor: AppColors.frog,
        overlayColor: AppColors.glow,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onGradient
              : const Color(0xFF8E8E93),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.frog
              : const Color(0x29FFFFFF),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line.withOpacity(0.7),
        thickness: 1,
      ),
    );
  }
}
