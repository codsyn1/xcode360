import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'sign_up_screen.dart';
import 'dart:math' as math;
import 'login_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> with SingleTickerProviderStateMixin {
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
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          Container(color: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7)),
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
            child: isDesktop
                // ── Desktop: centered card ──
                ? Center(
                    child: Container(
                      width: 460,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 90, color: isDarkMode ? Colors.white70 : Colors.black54),
                          const SizedBox(height: 24),
                          Text(
                            "Get Started With XCode360!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Login or sign up to start exchanging projects and collaborating with the XCode360 community!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login, size: 20, color: Colors.black87),
                                      SizedBox(width: 8),
                                      Text('LOGIN', style: TextStyle(color: Colors.black87)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_alt_1, size: 20, color: Colors.black87),
                                      SizedBox(width: 8),
                                      Text('SIGNUP', style: TextStyle(color: Colors.black87)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                // ── Mobile: original layout unchanged ──
                : Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined, size: 90, color: isDarkMode ? Colors.white70 : Colors.black54),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  "Get Started With XCode360!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  'Login or sign up to start exchanging projects and collaborating with the XCode360 community!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 20, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Text('LOGIN', style: TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_alt_1, size: 20, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Text('SIGNUP', style: TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
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
  static const int points = 24;
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