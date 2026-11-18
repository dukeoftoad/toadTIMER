import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_mode.dart';
import '../state/timer_notifier.dart';
import 'pressable_scale.dart';

class TimerControls extends ConsumerWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final notifier = ref.watch(timerProvider.notifier);
    final meta = timer.mode;

    final running = timer.isRunning;
    final label = running
        ? 'Pause'
        : timer.isPaused
            ? 'Resume'
            : 'Start';
    final icon = running ? Icons.pause_rounded : Icons.play_arrow_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Reset timer',
          onTap: notifier.reset,
        ),
        const SizedBox(width: 16),
        PressableScale(
          pressedScale: 0.93,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [meta.from, meta.to]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: meta.accent.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  HapticFeedback.selectionClick();
                  running ? notifier.pause() : notifier.start();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: const Color(0xFF09090B), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Color(0xFF09090B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _RoundIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Skip session',
          onTap: notifier.skip,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        pressedScale: 0.90,
        child: Material(
          color: Colors.white.withOpacity(0.05),
          shape: const CircleBorder(
            side: BorderSide(color: Color(0x1AFFFFFF)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
