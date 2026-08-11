import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- Dots && Parallax Lines Background Widgets ---

class DottedBackground extends StatelessWidget {
  final double offset;
  const DottedBackground({Key? key, required this.offset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: DottedPainter(offset: offset),
    );
  }
}

class DottedPainter extends CustomPainter {
  final double offset;
  DottedPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const double spacing = 32;
    const double radius = 2.2;
    final double move = offset * spacing * 2;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dx = x + ((y ~/ spacing) % 2 == 0 ? 0 : spacing / 2) + move;
        final dy = y + move * 0.5;
        final wrappedDx = dx % size.width;
        final wrappedDy = dy % size.height;
        canvas.drawCircle(Offset(wrappedDx, wrappedDy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedPainter oldDelegate) => oldDelegate.offset != offset;
}

class ParallaxLinesBackground extends StatelessWidget {
  final double progress;
  const ParallaxLinesBackground({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: ParallaxLinesPainter(progress),
    );
  }
}

class ParallaxLinesPainter extends CustomPainter {
  final double progress;
  static const int points = 24;
  static final List<MovingPoint> basePoints = List.generate(
    points,
    (i) => MovingPoint(
      angle: 2 * math.pi * i / points,
      radiusFactor: 0.25 + 0.25 * (i % 3),
      speed: 0.5 + 0.2 * (i % 5),
    ),
  );

  ParallaxLinesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.1;

    final center = Offset(size.width / 2, size.height / 2);
    final minSide = size.shortestSide;
    final List<Offset> offsets = basePoints.map((p) => p.position(center, minSide, progress)).toList();

    for (int i = 0; i < points; i++) {
      for (int j = i + 1; j < points; j++) {
        if ((offsets[i] - offsets[j]).distance < minSide * 0.35) {
          canvas.drawLine(offsets[i], offsets[j], paint);
        }
      }
    }
    for (final offset in offsets) {
      canvas.drawCircle(offset, 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParallaxLinesPainter oldDelegate) => oldDelegate.progress != progress;
}

class MovingPoint {
  final double angle;
  final double radiusFactor;
  final double speed;
  
  const MovingPoint({required this.angle, required this.radiusFactor, required this.speed});

  Offset position(Offset center, double minSide, double progress) {
    final double r = minSide * (radiusFactor + 0.18 * (math.sin(progress * 2 * math.pi * speed + angle)));
    final double a = angle + progress * 2 * math.pi * speed;
    return Offset(
      center.dx + r * math.cos(a),
      center.dy + r * math.sin(a),
    );
  }
}
