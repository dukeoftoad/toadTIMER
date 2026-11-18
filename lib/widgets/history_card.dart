import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/session_log.dart';
import '../models/timer_mode.dart';
import '../state/providers.dart';

class HistoryCard extends ConsumerWidget {
  const HistoryCard({super.key, this.showTags = false});

  /// When true, each row surfaces the session tag as a colored chip. The home
  /// log keeps it off for density; the insights screen turns it on.
  final bool showTags;

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
                  (entry) => HistoryRow(
                    log: entry.value,
                    showDivider: entry.key > 0,
                    showTag: showTags,
                  ),
                ),
        ],
      ),
    );
  }
}

/// Compact, reusable history row. Used by [HistoryCard] and the insights
/// screen. Pass [showTag] to render a colored tag chip after the label.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.log,
    this.showDivider = true,
    this.showTag = false,
  });

  final SessionLog log;
  final bool showDivider;
  final bool showTag;

  @override
  Widget build(BuildContext context) {
    final accent = log.mode.accent;
    final isFocus = log.mode.name == 'focus';
    final tagClr = tagColor(log.tag);

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
                child: Row(
                  children: [
                    Flexible(
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
                    if (showTag && isFocus) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagClr.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: tagClr.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          log.tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: tagClr,
                          ),
                        ),
                      ),
                    ],
                  ],
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
