import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/settings_repository.dart';
import 'data/stats_repository.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await SoundService.instance.init();

  final settings = await SettingsRepository.load();
  final stats = StatsState(await StatsRepository.load());

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsController.withInitial(settings),
        ),
        statsProvider.overrideWith(
          (ref) => StatsController.withInitial(stats),
        ),
      ],
      child: const ToadTimerApp(),
    ),
  );
}
