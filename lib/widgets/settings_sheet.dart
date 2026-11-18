import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../services/notification_service.dart';
import '../state/providers.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  bool _notifGranted = false;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.areNotificationsEnabled().then((granted) {
      if (mounted) setState(() => _notifGranted = granted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.watch(settingsProvider.notifier);
    final statsCtrl = ref.watch(statsProvider.notifier);

    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Timer settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Tune your pond. Changes apply to the next session.',
              style: TextStyle(fontSize: 12, color: AppColors.textFaint),
            ),
            const SizedBox(height: 18),

            _card(
              children: [
                _SliderTile(
                  label: 'Focus length',
                  value: settings.focusMin,
                  min: 5,
                  max: 90,
                  step: 5,
                  suffix: 'min',
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(focusMin: v),
                  ),
                ),
                _SliderTile(
                  label: 'Short break',
                  value: settings.shortMin,
                  min: 1,
                  max: 30,
                  step: 1,
                  suffix: 'min',
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(shortMin: v),
                  ),
                ),
                _SliderTile(
                  label: 'Long break',
                  value: settings.longMin,
                  min: 5,
                  max: 45,
                  step: 5,
                  suffix: 'min',
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(longMin: v),
                  ),
                ),
                _SliderTile(
                  label: 'Long break every',
                  value: settings.longEvery,
                  min: 2,
                  max: 8,
                  step: 1,
                  suffix: 'sessions',
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(longEvery: v),
                  ),
                ),
                _SliderTile(
                  label: 'Daily focus goal',
                  value: settings.dailyGoalMin,
                  min: 30,
                  max: 360,
                  step: 15,
                  suffix: 'min',
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(dailyGoalMin: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _card(
              children: [
                _SwitchTile(
                  label: 'Auto-start breaks',
                  description: 'Hop straight into the break when focus ends.',
                  value: settings.autoStartBreaks,
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(autoStartBreaks: v),
                  ),
                ),
                _SwitchTile(
                  label: 'Auto-start focus',
                  description: 'Roll into the next focus session after a break.',
                  value: settings.autoStartFocus,
                  onChanged: (v) => settingsCtrl.update(
                    settings.copyWith(autoStartFocus: v),
                  ),
                ),
                _SwitchTile(
                  label: 'Completion chime',
                  description: 'A gentle tone when a session ends.',
                  value: settings.soundOn,
                  onChanged: (v) =>
                      settingsCtrl.update(settings.copyWith(soundOn: v)),
                ),
                _SwitchTile(
                  label: 'OS notifications',
                  description: 'System alert when a session ends.',
                  value: settings.notifyOn,
                  onChanged: (v) async {
                    if (v) {
                      final granted =
                          await NotificationService.instance.requestPermission();
                      setState(() => _notifGranted = granted);
                      if (!granted) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Permission denied - enable alerts for toadTIMER in system settings.',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    settingsCtrl.update(settings.copyWith(notifyOn: v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            _cardRow(
              child: Row(
                children: [
                  Icon(
                    _notifGranted
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    size: 18,
                    color: _notifGranted
                        ? const Color(0xFF34D399)
                        : Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _notifGranted
                          ? 'Notification permission granted.'
                          : 'Notification permission not granted yet.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!_notifGranted)
                    TextButton(
                      onPressed: () async {
                        final granted = await NotificationService.instance
                            .requestPermission();
                        setState(() => _notifGranted = granted);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF34D399),
                      ),
                      child: const Text('Enable'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _armed
                        ? 'Tap again to confirm clearing the log.'
                        : 'Wipe the session log and cycle dots.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _armed
                          ? const Color(0xFFF87171)
                          : AppColors.textFaint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    if (_armed) {
                      statsCtrl.clear();
                      setState(() => _armed = false);
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _armed = true);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFF87171).withOpacity(0.4),
                    ),
                    foregroundColor: const Color(0xFFF87171),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Clear log'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _cardRow({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$value $suffix',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF34D399),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ step,
          onChanged: (v) => onChanged((v / step).round() * step),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
