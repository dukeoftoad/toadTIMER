import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static const _key = 'toad_settings_v1';

  static Future<TimerSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const TimerSettings.defaults();
      return TimerSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TimerSettings.defaults();
    }
  }

  static Future<void> save(TimerSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(settings.toJson()));
    } catch (_) {
      // persistence is best-effort; the app keeps working in-memory
    }
  }
}
