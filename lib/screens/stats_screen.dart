import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/session_log.dart';
import '../state/providers.dart';
import '../widgets/history_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_chart.dart';

/// Full insights view: weekly chart, tag breakdown, summary stats and the
/// full session log. Pushed from the home header's insights button.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final tagMinutes = stats.tagMinutes;
    final tagList = tagMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxTag = tagList.isEmpty ? 1 : tagList.first.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy CSV to clipboard',
            icon: const Icon(
              Icons.ios_share_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () async {
              final csv = _toCsv(stats.history);
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Copied ${stats.history.length} sessions as CSV to clipboard.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ambient glow
          const Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: _Orb(size: 280, color: Color(0xFF34D399)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WeeklyChart(),
                  const SizedBox(height: 16),
                  const StatsGrid(),
                  const SizedBox(height: 16),
                  _TagBreakdown(
                    tagList: tagList,
                    maxTag: maxTag,
                    totalMinutes: stats.tagMinutes.values.fold(0, (a, b) => a + b),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('Session log'),
                  const SizedBox(height: 10),
                  const HistoryCard(showTags: true),
                  const SizedBox(height: 24),
                  Text(
                    'toadTIMER v$kAppVersion · ${stats.allTime} focus sessions all-time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the full history as a CSV string (mode, tag, minutes, timestamp).
  String _toCsv(List<SessionLog> history) {
    final rows = <List<dynamic>>[
      ['mode', 'tag', 'minutes', 'at'],
      ...history.map((h) => [
            h.mode.name,
            h.tag,
            h.minutes,
            dayKey(h.at),
          ]),
    ];
    return const CsvConverter().convert(rows);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TagBreakdown extends StatelessWidget {
  const _TagBreakdown({
    required this.tagList,
    required this.maxTag,
    required this.totalMinutes,
  });

  final List<MapEntry<String, int>> tagList;
  final int maxTag;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                  color: const Color(0xFFA3E635).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFA3E635).withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.label_rounded,
                  size: 16,
                  color: Color(0xFFA3E635),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Focus by tag',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$totalMinutes min across ${tagList.length} tags',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (tagList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tag a focus session and your breakdown appears here.',
                style: TextStyle(fontSize: 12, color: AppColors.textFaint),
              ),
            )
          else
            ...tagList.map((e) {
              final color = tagColor(e.key);
              final pct = maxTag <= 0 ? 0.0 : (e.value / maxTag).clamp(0.0, 1.0);
              final share = totalMinutes <= 0
                  ? 0
                  : ((e.value / totalMinutes) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 64,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${e.value}m',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '$share%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.14), color.withOpacity(0)],
        ),
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

/// Tiny, dependency-free CSV writer — keeps `share_plus` out of the dependency
/// tree. Quotes a cell only when it needs to (contains comma, quote or newline).
class CsvConverter {
  const CsvConverter();

  String convert(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.write(row.map(_escape).join(','));
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _escape(dynamic cell) {
    final s = cell.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
