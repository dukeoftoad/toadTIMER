import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../state/timer_notifier.dart';

/// A horizontally scrolling chip row that tags the active focus session.
///
/// The chosen tag is stamped onto the [SessionLog] when the session ends, so
/// it can be broken down on the insights screen. Selecting a tag mid-run is
/// safe — the new tag is what gets logged.
class TagSelector extends ConsumerWidget {
  const TagSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTag = ref.watch(timerProvider.select((s) => s.tag));
    final notifier = ref.watch(timerProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: kTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tag = kTags[i];
          final color = kTagColors[i];
          final selected = tag == activeTag;

          return _TagChip(
            label: tag,
            color: color,
            selected: selected,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setTag(tag);
            },
          );
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.16) : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color.withOpacity(0.55) : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
