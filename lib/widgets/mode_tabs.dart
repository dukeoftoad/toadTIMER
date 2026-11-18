import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/timer_mode.dart';
import '../state/providers.dart';
import '../state/timer_notifier.dart';

class ModeTabs extends ConsumerWidget {
  const ModeTabs({super.key});

  static const _modes = TimerMode.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.watch(timerProvider.notifier);

    final index = _modes.indexOf(timer.mode);

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            // Spread the highlight across n tabs: -1 .. 0 .. +1. A naive
            // `-1 + 2 * index` only works for two tabs — with three it shoves
            // the middle pill to the far edge and the last one off-screen.
            alignment: Alignment(-1 + 2 * index / (_modes.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / _modes.length,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: timer.mode.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: timer.mode.accent.withOpacity(0.30),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: _modes.map((mode) {
              final selected = mode == timer.mode;
              final minutes = settings.minutesFor(mode);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => notifier.selectMode(mode),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mode.tabIcon,
                            size: 13,
                            color: selected
                                ? mode.accent
                                : AppColors.textFaint,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            mode.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: selected
                                  ? mode.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$minutes min',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
