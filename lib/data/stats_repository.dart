import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_log.dart';

class StatsRepository {
  StatsRepository._();

  static const _key = 'toad_history_v1';
  static const _maxEntries = 200;

  static Future<List<SessionLog>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SessionLog.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<SessionLog> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = history.length > _maxEntries
          ? history.sublist(history.length - _maxEntries)
          : history;
      await prefs.setString(
        _key,
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // best-effort
    }
  }
}
