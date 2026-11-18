import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/timer_mode.dart';
import '../state/providers.dart';
import '../state/timer_notifier.dart';

/// The premium dial: gradient progress ring with 60 dial ticks, an inner
/// hairline, a breathing glow while the session runs, a glowing tip dot and
/// per-second slide/fade clock transitions.
class TimerRing extends ConsumerStatefulWidget {
  const TimerRing({super.key});

  @override
  ConsumerState<TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends ConsumerState<TimerRing>
    with SingleTickerProviderStateMixin {
  /// Drives the "breathing" glow — only loops while a session is running.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    if (ref.read(timerProvider).isRunning) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final settings = ref.watch(settingsProvider);

    // Start/stop the breathing pulse in sync with the state machine.
    ref.listen<bool>(timerProvider.select((s) => s.isRunning), (_, next) {
      if (next) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    });

    // The session's planned duration was captured at start — using it keeps
    // the ring stable when the user edits timer settings mid-run. Falls back
    // to the settings/override duration when no plan exists (idle).
    final total = timer.plannedSeconds ??
        ((timer.overrideMinutes ?? settings.minutesFor(timer.mode)) * 60);
    final progress =
        total <= 0 ? 0.0 : (1 - timer.remaining / total).clamp(0.0, 1.0);

    final meta = timer.mode;
    final size = (MediaQuery.sizeOf(context).width * 0.72).clamp(240.0, 320.0);

    final statusLabel = switch (timer.status) {
      TimerStatus.running => 'IN SESSION',
      TimerStatus.paused => 'PAUSED',
      TimerStatus.idle => 'READY',
    };

    final clock = formatClock(timer.remaining);

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final breathing = timer.isRunning ? _pulse.value : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // ambient halo behind the dial
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: meta.accent.withOpacity(
                          timer.isRunning ? 0.10 + 0.10 * breathing : 0.08,
                        ),
                        blurRadius: timer.isRunning ? 55 + 25 * breathing : 40,
                        spreadRadius: timer.isRunning ? 4 + 6 * breathing : 2,
                      ),
                    ],
                  ),
                ),
              ),

              // progress dial
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 300),
                curve: Curves.linear,
                builder: (context, animated, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    progress: animated,
                    from: meta.from,
                    to: meta.to,
                    breathing: breathing,
                  ),
                ),
              ),

              // center stack: status pill, clock, tagline
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusPill(label: statusLabel, accent: meta.accent),
                  SizedBox(height: size * 0.045),
                  SizedBox(
                    height: size * 0.21,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return ClipRect(
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.16),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        clock,
                        key: ValueKey<String>(clock),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: size * 0.185,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size * 0.035),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      meta.tagline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.6,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.from,
    required this.to,
    required this.breathing,
  });

  final double progress;
  final Color from;
  final Color to;

  /// 0..1 "breathing" factor while running; 0 when idle/paused.
  final double breathing;

  static const _stroke = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(center, radius, track);

    // 2. inner hairline ring
    final hairline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(center, radius - _stroke / 2 - 14, hairline);

    // 3. dial ticks — 60 of them, majors every 5
    final tickMinor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.10);
    final tickMajor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withOpacity(0.20);

    const tickCount = 60;
    final tickOuter = radius + _stroke / 2 + 6;
    for (var i = 0; i < tickCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi) * i / tickCount;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final isMajor = i % 5 == 0;
      final inner = center + dir * (tickOuter - (isMajor ? 7 : 4));
      final outer = center + dir * tickOuter;
      canvas.drawLine(inner, outer, isMajor ? tickMajor : tickMinor);
    }

    if (progress <= 0) {
      return;
    }

    // rotate so the gradient starts at 12 o'clock
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.translate(-center.dx, -center.dy);

    final shader = SweepGradient(colors: [from, to]).createShader(rect);

    // breathing glow underlay
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke + 3 + 2 * breathing
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 + 6 * breathing)
      ..color = from.withOpacity(0.45 + 0.2 * breathing);
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, glow);

    // main arc
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, 0, 2 * math.pi * progress, false, arc);

    canvas.restore();

    // glowing tip dot riding the end of the arc
    final tipAngle = -math.pi / 2 + 2 * math.pi * progress;
    final tipCenter =
        center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    canvas.drawCircle(
      tipCenter,
      8.5,
      Paint()
        ..color = to.withOpacity(0.25 + 0.15 * breathing)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(tipCenter, 4.5, Paint()..color = to.withOpacity(0.95));
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.breathing != breathing;
}
