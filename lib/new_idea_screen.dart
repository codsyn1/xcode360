import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'dart:math' as math;

class NewIdeaScreen extends StatefulWidget {
  const NewIdeaScreen({super.key});

  @override
  State<NewIdeaScreen> createState() => _NewIdeaScreenState();
}

class _NewIdeaScreenState extends State<NewIdeaScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF232323)),
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Stack(
                children: [
                  _ParallaxLinesBackground(progress: _bgAnimationController.value),
                  _DottedBackground(offset: _bgAnimationController.value),
                ],
              );
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ExchangeIllustration(),
                      const SizedBox(height: 32),
                      _IntroCard(),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => OnboardingScreen()),
                            );
                          },
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: const [
          Text(
            "Introducing the First-Ever Free Project Exchange",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Share your project, get one in return — no fees, just collaboration!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder illustration: use logo.png if you want, or a handshake icon
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(32),
      child: Icon(
        Icons.swap_horiz,
        size: 100,
        color: Colors.white,
      ),
    );
  }
}

// Dots background
class _DottedBackground extends StatelessWidget {
  final double offset;
  const _DottedBackground({required this.offset});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _DottedPainter(offset: offset),
    );
  }
}

class _DottedPainter extends CustomPainter {
  final double offset;
  _DottedPainter({required this.offset});

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
  bool shouldRepaint(covariant _DottedPainter oldDelegate) => oldDelegate.offset != offset;
}

// Parallax lines background
class _ParallaxLinesBackground extends StatelessWidget {
  final double progress;
  const _ParallaxLinesBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ParallaxLinesPainter(progress),
    );
  }
}

class _ParallaxLinesPainter extends CustomPainter {
  final double progress;
  static final int points = 24;
  static final List<_MovingPoint> basePoints = List.generate(
    points,
    (i) => _MovingPoint(
      angle: 2 * math.pi * i / points,
      radiusFactor: 0.25 + 0.25 * (i % 3),
      speed: 0.5 + 0.2 * (i % 5),
    ),
  );

  _ParallaxLinesPainter(this.progress);

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
  bool shouldRepaint(covariant _ParallaxLinesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _MovingPoint {
  final double angle;
  final double radiusFactor;
  final double speed;
  _MovingPoint({required this.angle, required this.radiusFactor, required this.speed});

  Offset position(Offset center, double minSide, double progress) {
    final double r = minSide * (radiusFactor + 0.18 * (math.sin(progress * 2 * math.pi * speed + angle)));
    final double a = angle + progress * 2 * math.pi * speed;
    return Offset(
      center.dx + r * math.cos(a),
      center.dy + r * math.sin(a),
    );
  }
} 