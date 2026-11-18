import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../state/providers.dart';
import '../state/timer_notifier.dart';

class SessionDots extends ConsumerWidget {
  const SessionDots({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final longEvery = ref.watch(settingsProvider.select((s) => s.longEvery));
    final shown = timer.cyclePosition.clamp(0, longEvery);

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...List.generate(longEvery, (i) {
          final filled = i < shown;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: filled ? 24 : 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: filled
                  ? const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFFA3E635)])
                  : null,
              color: filled ? null : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '$shown/$longEvery to long break',
            style: const TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }
}
