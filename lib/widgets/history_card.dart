import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/session_log.dart';
import '../models/timer_mode.dart';
import '../state/providers.dart';

class HistoryCard extends ConsumerWidget {
  const HistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(
      statsProvider.select((s) => s.history),
    );
    final recent = history.reversed.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Session log',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (recent.isNotEmpty)
                Text(
                  'last ${recent.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(
                      Icons.egg_alt_rounded,
                      size: 20,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No sessions yet.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Finish a focus session and it will hop in here.',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                  ),
                ],
              ),
            )
          else
            ...recent.asMap().entries.map(
                  (entry) => _HistoryRow(
                    log: entry.value,
                    showDivider: entry.key > 0,
                  ),
                ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.log, required this.showDivider});

  final SessionLog log;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = log.mode.accent;

    return Column(
      children: [
        if (showDivider)
          Container(height: 1, color: Colors.white.withOpacity(0.04)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withOpacity(0.25)),
                ),
                child: Icon(log.mode.tabIcon, size: 13, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${log.mode.label} · ${log.minutes} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                relativeTime(log.at),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
