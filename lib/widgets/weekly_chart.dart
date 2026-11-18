import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../state/providers.dart';

/// A 7-day focus-minutes bar chart, rendered with [CustomPaint] so it shares
/// the timer ring's hand-drawn aesthetic (no chart dependency). The last bar
/// (today) is highlighted with the brand gradient.
class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key, this.compact = false});

  /// Compact mode trims the header/total row for nested use (home screen).
  final bool compact;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(statsProvider.select((s) => s.weeklyMinutes));
    final total = weekly.fold(0, (a, b) => a + b);
    // Labels aligned to the actual weekdays of the last 7 days (index 6 = today).
    final today = DateTime.now();
    final labels = List<String>.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return _labels[(d.weekday - 1) % 7];
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF34D399).withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This week',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$total focus min across 7 days',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Text(
                  '${weekly.last}m today',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34D399),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: compact ? 96 : 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarPainter(
                values: weekly,
                labels: labels,
                todayIndex: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.values,
    required this.labels,
    required this.todayIndex,
  });

  final List<int> values;
  final List<String> labels;
  final int todayIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final maxVal = (values.fold<int>(0, (a, b) => a > b ? a : b)).clamp(1, 1 << 30);
    const gap = 10.0;
    final barW = (size.width - gap * (n - 1)) / n;
    const chartTop = 6.0;
    final chartBottom = size.height - 18; // leave room for labels
    final chartH = chartBottom - chartTop;

    // baseline hairline
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawLine(
      Offset(0, chartBottom),
      Offset(size.width, chartBottom),
      base,
    );

    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = (v / maxVal) * chartH;
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartBottom - h, barW, h),
        const Radius.circular(5),
      );
      final isToday = i == todayIndex;

      // track (empty bar ghost)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, chartTop, barW, chartH),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.white.withOpacity(0.035),
      );

      if (h <= 0) {
        // draw a tiny nub so empty days still read as "today"
        if (isToday) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, chartBottom - 3, barW, 3),
              const Radius.circular(2),
            ),
            Paint()..color = const Color(0xFF34D399).withOpacity(0.5),
          );
        }
      } else {
        final paint = Paint()
          ..shader = isToday
              ? const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFFA3E635)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ).createShader(Rect.fromLTWH(x, chartBottom - h, barW, h))
              : LinearGradient(
                  colors: [
                    const Color(0xFF34D399).withOpacity(0.45),
                    const Color(0xFFA3E635).withOpacity(0.30),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ).createShader(Rect.fromLTWH(x, chartBottom - h, barW, h));

        if (isToday) {
          // soft glow under today's bar
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 2, chartBottom - h - 2, barW + 4, h + 4),
              const Radius.circular(7),
            ),
            Paint()
              ..color = const Color(0xFF34D399).withOpacity(0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
        canvas.drawRRect(rect, paint);
      }

      // weekday label
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            color: isToday
                ? const Color(0xFF34D399)
                : Colors.white.withOpacity(0.35),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (barW - tp.width) / 2, size.height - tp.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.todayIndex != todayIndex;
}
