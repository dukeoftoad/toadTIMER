import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// The toad is not a mascot sticker — it is the body of toadtimer.
/// It runs while a timer runs, walks during rest, breathes when idle and
/// leaps when a session is done. Everything is painted with strokes and
/// beziers so it feels hand-drawn, matching the toadmark sketch language.

enum ToadMood { idle, run, walk, celebrate }

class ToadMascot extends StatefulWidget {
  const ToadMascot({
    super.key,
    required this.mood,
    this.size = 160,
  });

  final ToadMood mood;
  final double size;

  @override
  State<ToadMascot> createState() => _ToadMascotState();
}

class _ToadMascotState extends State<ToadMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _duration(widget.mood),
  )..repeat();

  static Duration _duration(ToadMood mood) {
    switch (mood) {
      case ToadMood.run:
        return const Duration(milliseconds: 640);
      case ToadMood.walk:
        return const Duration(milliseconds: 1150);
      case ToadMood.idle:
        return const Duration(milliseconds: 2600);
      case ToadMood.celebrate:
        return const Duration(milliseconds: 780);
    }
  }

  @override
  void didUpdateWidget(ToadMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _c.duration = _duration(widget.mood);
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size * 1.45, widget.size),
          painter: ToadPainter(t: _c.value, mood: widget.mood),
        );
      },
    );
  }
}

/// Design space: 220 x 150, toad facing right (toward the lily pad).
class ToadPainter extends CustomPainter {
  ToadPainter({required this.t, required this.mood});

  final double t;
  final ToadMood mood;

  // Palette (family greens).
  static const Color skin = Color(0xFF7FA650);
  static const Color skinDark = Color(0xFF5F7F3F);
  static const Color skinFar = Color(0xFF4E6B34);
  static const Color belly = Color(0xFFD9E3B4);
  static const Color spots = Color(0xFF5C7C3C);
  static const Color inkLine = Color(0xFF2A3320);
  static const Color throat = Color(0xFFE8A33D);
  static const Color blush = Color(0xFFE07B54);
  static const Color eyeWhite = Color(0xFFF6F3E4);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220, size.height / 150);

    switch (mood) {
      case ToadMood.run:
        _paintRun(canvas);
        break;
      case ToadMood.walk:
        _paintWalk(canvas);
        break;
      case ToadMood.idle:
        _paintIdle(canvas);
        break;
      case ToadMood.celebrate:
        _paintCelebrate(canvas);
        break;
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------- poses

  double get _legAmp {
    switch (mood) {
      case ToadMood.run:
        return 0.52;
      case ToadMood.walk:
        return 0.24;
      case ToadMood.idle:
        return 0.0;
      case ToadMood.celebrate:
        return 0.0;
    }
  }

  double get _bob {
    switch (mood) {
      case ToadMood.run:
        return -3.4 * math.sin(2 * math.pi * t * 2);
      case ToadMood.walk:
        return -1.5 * math.sin(2 * math.pi * t);
      case ToadMood.idle:
        return -1.0 * math.sin(2 * math.pi * t);
      case ToadMood.celebrate:
        return -58 * math.pow(math.sin(math.pi * t), 1.15).toDouble();
    }
  }

  double get _blink {
    // A quick blink once per cycle (twice per cycle while running).
    final phase = (t * (mood == ToadMood.run ? 2 : 1)) % 1;
    const center = 0.87;
    const half = 0.045;
    final d = (phase - center).abs();
    if (d > half) return 0;
    final v = 1 - d / half;
    return v * v * (3 - 2 * v);
  }

  void _paintRun(Canvas canvas) {
    _paintShadow(canvas, 0.42);
    _paintDust(canvas);
    _paintLeg(canvas, const Offset(84, 98), phase: math.pi, far: true);
    _paintArm(canvas, const Offset(130, 100), phase: math.pi / 2, far: true);
    _paintBody(canvas);
    _paintLeg(canvas, const Offset(66, 96), phase: 0, far: false);
    _paintArm(canvas, const Offset(136, 100), phase: 3 * math.pi / 2, far: false);
  }

  void _paintWalk(Canvas canvas) {
    _paintShadow(canvas, 0.40);
    _paintLeg(canvas, const Offset(84, 98), phase: math.pi, far: true, restAngle: 0.10);
    _paintArm(canvas, const Offset(130, 100), phase: math.pi, far: true, restAngle: 0.06);
    _paintBody(canvas);
    _paintLeg(canvas, const Offset(66, 96), phase: 0, far: false, restAngle: 0.10);
    _paintArm(canvas, const Offset(136, 100), phase: 0, far: false, restAngle: 0.06);
  }

  void _paintIdle(Canvas canvas) {
    _paintShadow(canvas, 0.36);
    _paintLeg(canvas, const Offset(84, 98), phase: 0, far: true, restAngle: 0.12);
    _paintArm(canvas, const Offset(130, 100), phase: 0, far: true, restAngle: 0.05);
    _paintBody(canvas, withThroatPuff: true);
    _paintLeg(canvas, const Offset(66, 96), phase: 0, far: false, restAngle: 0.12);
    _paintArm(canvas, const Offset(136, 100), phase: 0, far: false, restAngle: 0.05);
  }

  void _paintCelebrate(Canvas canvas) {
    _paintShadow(canvas, 0.30 + 0.18 * (1 - math.sin(math.pi * t)));
    _paintSparkles(canvas);
    _paintLeg(canvas, const Offset(84, 98), phase: 0, far: true, stretch: true);
    _paintArm(canvas, const Offset(130, 100), phase: 0, far: true, stretch: true);
    _paintBody(canvas, openMouth: true);
    _paintLeg(canvas, const Offset(66, 96), phase: 0, far: false, stretch: true);
    _paintArm(canvas, const Offset(136, 100), phase: 0, far: false, stretch: true);
  }

  // ------------------------------------------------------------- parts

  void _paintShadow(Canvas canvas, double alpha) {
    final bobLift = mood == ToadMood.celebrate ? -_bob : 0.0;
    final shrink = (bobLift / 58).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..color = const Color(0xFF000000).withOpacity( alpha * (1 - shrink * 0.55));
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(112, 141),
        width: 104 - 30 * shrink,
        height: 13 - 4 * shrink,
      ),
      paint,
    );
  }

  void _paintBody(Canvas canvas, {bool openMouth = false, bool withThroatPuff = false}) {
    final bob = _bob;

    final body = Path()
      ..moveTo(58, 97)
      ..cubicTo(50, 64, 72, 41, 106, 39)
      ..cubicTo(142, 37, 168, 59, 166, 85)
      ..cubicTo(164, 109, 140, 123, 106, 123)
      ..cubicTo(74, 123, 64, 116, 58, 97)
      ..close();

    canvas.save();
    canvas.translate(0, bob);

    // Throat puff (idle breathing display).
    if (withThroatPuff) {
      final puff = 0.5 + 0.5 * math.sin(2 * math.pi * t);
      final paint = Paint()..color = throat.withOpacity( 0.9);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(116, 104),
          width: 26 + 14 * puff,
          height: 10 + 7 * puff,
        ),
        paint,
      );
    }

    final skinPaint = Paint()..color = skin;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = inkLine;

    canvas.drawPath(body, skinPaint);
    canvas.drawPath(body, outline);

    // Belly + throat patch, clipped to the body.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(112, 112),
        width: 92,
        height: 44,
      ),
      Paint()..color = belly,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(120, 96),
        width: 64,
        height: 22,
      ),
      Paint()..color = belly.withOpacity( 0.75),
    );
    canvas.restore();

    // Parotoid gland bump behind the eye.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(104, 54),
        width: 18,
        height: 11,
      ),
      Paint()..color = spots.withOpacity( 0.55),
    );

    // Warty spots.
    final spotPaint = Paint()..color = spots.withOpacity( 0.8);
    const spotCenters = [
      Offset(88, 72),
      Offset(120, 60),
      Offset(142, 74),
      Offset(74, 86),
      Offset(154, 90),
      Offset(100, 80),
    ];
    for (final c in spotCenters) {
      canvas.drawCircle(c, c == const Offset(142, 74) ? 5.5 : 4, spotPaint);
    }

    // Cheek blush.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(152, 86),
        width: 13,
        height: 8,
      ),
      Paint()..color = blush.withOpacity( 0.45),
    );

    // Eyes.
    _paintEye(canvas, const Offset(120, 41), 14.5, 9, 4.6, const Offset(123, 39));
    _paintEye(canvas, const Offset(94, 43), 12.5, 7.6, 4.0, const Offset(96, 41.5), far: true);

    // Nostrils.
    final nostril = Paint()..color = inkLine;
    canvas.drawCircle(const Offset(146, 62), 1.8, nostril);
    canvas.drawCircle(const Offset(152, 64), 1.5, nostril);

    // Mouth.
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = inkLine;
    if (openMouth) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(122, 84),
          width: 26,
          height: 14,
        ),
        Paint()..color = const Color(0xFF3A2E22),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(122, 88),
          width: 16,
          height: 7,
        ),
        Paint()..color = blush.withOpacity( 0.85),
      );
      canvas.drawPath(
        Path()
          ..moveTo(96, 78)
          ..quadraticBezierTo(122, 96, 148, 76),
        mouth,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(94, 80)
          ..quadraticBezierTo(120, 94, 148, 74),
        mouth,
      );
    }

    canvas.restore();
  }

  void _paintEye(Canvas canvas, Offset center, double r, double eyeR, double pupilR,
      Offset pupilAt, {bool far = false}) {
    final bumpPaint = Paint()..color = far ? skinDark : skin;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = inkLine;

    canvas.drawCircle(center, r, bumpPaint);
    canvas.drawCircle(center, r, outline);

    canvas.save();
    final blink = _blink;
    final eyeCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: eyeR));
    canvas.clipPath(eyeCircle);
    canvas.drawCircle(center, eyeR, Paint()..color = eyeWhite);
    canvas.drawCircle(pupilAt, pupilR, Paint()..color = inkLine);
    canvas.drawCircle(pupilAt + const Offset(1.6, -1.6), pupilR * 0.32, Paint()..color = eyeWhite);
    if (blink > 0) {
      final lidH = eyeR * 2 * blink;
      canvas.drawRect(
        Rect.fromLTWH(center.dx - eyeR, center.dy - eyeR, eyeR * 2, lidH),
        Paint()..color = far ? skinDark : skin,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      eyeR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = inkLine.withOpacity( 0.85),
    );
  }

  /// Bent back leg with a wide foot; swings around the hip while moving.
  void _paintLeg(Canvas canvas, Offset hip,
      {required double phase, required bool far, double restAngle = 0, bool stretch = false}) {
    final double angle = stretch ? -0.5 : restAngle + _legAmp * math.sin(2 * math.pi * t + phase);

    final skinCol = far ? skinFar : skinDark;
    canvas.save();
    canvas.translate(hip.dx, hip.dy + (far ? _bob * 0.7 : _bob * 0.3));
    canvas.rotate(angle);
    canvas.translate(-hip.dx, -hip.dy);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 13
      ..color = inkLine;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.5
      ..color = skinCol;

    // Thigh -> knee -> ankle.
    final thigh = Path()
      ..moveTo(hip.dx, hip.dy)
      ..quadraticBezierTo(hip.dx - 6, hip.dy + 14, hip.dx - 12, hip.dy + 24);
    final shin = Path()
      ..moveTo(hip.dx - 12, hip.dy + 24)
      ..quadraticBezierTo(hip.dx - 6, hip.dy + 34, hip.dx + 4, hip.dy + 37);

    canvas.drawPath(thigh, outline);
    canvas.drawPath(shin, outline);
    canvas.drawPath(thigh, fill);
    canvas.drawPath(shin, fill);

    // Foot + toes pointing forward.
    final ankle = Offset(hip.dx + 4, hip.dy + 37);
    final toes = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..color = skinCol;
    final toeOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = inkLine;
    const toeTips = [Offset(22, 0), Offset(20, 5), Offset(16, 9)];
    for (final tip in toeTips) {
      final toe = Path()
        ..moveTo(ankle.dx, ankle.dy)
        ..lineTo(ankle.dx + tip.dx, ankle.dy + tip.dy);
      canvas.drawPath(toe, toeOutline);
      canvas.drawPath(toe, toes);
    }

    canvas.restore();
  }

  /// Small front arm.
  void _paintArm(Canvas canvas, Offset shoulder,
      {required double phase, required bool far, double restAngle = 0, bool stretch = false}) {
    final double angle = stretch
        ? -1.9 // waving up while celebrating
        : restAngle + (_legAmp * 0.7) * math.sin(2 * math.pi * t + phase + math.pi / 4);

    final skinCol = far ? skinFar : skin;
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy + (far ? _bob * 0.7 : _bob * 0.3));
    canvas.rotate(angle);
    canvas.translate(-shoulder.dx, -shoulder.dy);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10
      ..color = inkLine;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = skinCol;

    final arm = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(shoulder.dx + 4, shoulder.dy + 12, shoulder.dx + 8, shoulder.dy + 22);
    canvas.drawPath(arm, outline);
    canvas.drawPath(arm, fill);

    final hand = Offset(shoulder.dx + 8, shoulder.dy + 22);
    final fingers = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..color = skinCol;
    const fingerTips = [Offset(9, 6), Offset(4, 8), Offset(-1, 7)];
    for (final tip in fingerTips) {
      canvas.drawLine(hand, hand + tip, fingers);
    }

    canvas.restore();
  }

  /// Little dust puffs kicking up behind the toad while running.
  void _paintDust(Canvas canvas) {
    for (int i = 0; i < 3; i++) {
      final phase = (t * 2 + i * 0.33) % 1;
      final alpha = (1 - phase) * 0.30;
      canvas.drawCircle(
        Offset(30 - phase * 16, 128 - phase * 6),
        2.2 + phase * 3.4,
        Paint()..color = const Color(0xFF8A9B92).withOpacity( alpha),
      );
    }
  }

  /// Celebration sparkles around the toad.
  void _paintSparkles(Canvas canvas) {
    final alpha = 1 - t;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.frog400.withOpacity( alpha);
    const sparkleCenters = [
      Offset(52, 34),
      Offset(168, 30),
      Offset(190, 64),
      Offset(40, 66),
    ];
    for (final c in sparkleCenters) {
      canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), paint);
      canvas.drawLine(c.translate(0, -6), c.translate(0, 6), paint);
    }
  }

  @override
  bool shouldRepaint(ToadPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mood != mood;
}
