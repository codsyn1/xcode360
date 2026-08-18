import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'sign_up_screen.dart';
import 'login_signup_screen.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _dotsAnimationController;

  final List<_OnboardPageData> _pages = [
    const _OnboardPageData(
      title: 'Welcome to XCode360',
      subtitle: 'A free platform to exchange projects and collaborate with developers, designers, and SEO experts.',
      icon: Icons.hub_outlined, // network/connection
    ),
    const _OnboardPageData(
      title: 'Chat with Community',
      subtitle: 'Connect, discuss, and grow with fellow project exchangers in real time.',
      icon: Icons.forum_outlined, // chat/community
    ),
    const _OnboardPageData(
      title: 'Break Time? Join the Fun Chats!',
      subtitle: 'Relax and chat with developers, designers, and creators in our fun communities.',
      icon: Icons.celebration_outlined, // fun/chat
    ),
    const _OnboardPageData(
      title: 'Start Free. Go Pro Anytime.',
      subtitle: 'Enjoy free project exchange or upgrade to Pro featured listings, and priority support.',
      icon: Icons.workspace_premium_outlined, // plan
    ),
    const _OnboardPageData(
      title: 'Start Exchanging Projects',
      subtitle: 'Find partners, exchange projects, and grow together — for free!',
      icon: Icons.handshake_outlined, // handshake/exchange
    ),
  ];

  void _goToLoginSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void initState() {
    super.initState();
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: const Color(0xFF232323),
            ),
            AnimatedBuilder(
              animation: _dotsAnimationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    _ParallaxLinesBackground(progress: _dotsAnimationController.value),
                    _DottedBackground(offset: _dotsAnimationController.value),
                  ],
                );
              },
            ),
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return _OnboardingPageContent(
                        title: page.title,
                        subtitle: page.subtitle,
                        icon: page.icon,
                      );
                    },
                  ),
                ),
                // Dots indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => _buildDot(i)),
                  ),
                ),
                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _currentPage == _pages.length - 1
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _goToLoginSignup,
                            child: const Text('Get Started'),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _nextPage,
                            child: const Text('Next'),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int i) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == i ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == i ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardingPageContent({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Icon(icon, size: 100, color: const Color(0xFF1976D2)),
            ),
            const SizedBox(height: 40),
            Text(
              title,
              style: TextStyle(
                fontSize: title == 'Break Time? Join the Fun Chats!' ? 22 : 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardPageData({required this.title, required this.subtitle, required this.icon});
}

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
    final double move = offset * spacing * 2; // Controls speed and direction
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Offset every other row for a diagonal/hex effect
        final dx = x + ((y ~/ spacing) % 2 == 0 ? 0 : spacing / 2) + move;
        final dy = y + move * 0.5;
        // Wrap around horizontally
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
      angle: 2 * 3.141592653589793 * i / points,
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

    // Draw lines between close points
    for (int i = 0; i < points; i++) {
      for (int j = i + 1; j < points; j++) {
        if ((offsets[i] - offsets[j]).distance < minSide * 0.35) {
          canvas.drawLine(offsets[i], offsets[j], paint);
        }
      }
    }
    // Draw points
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
    final double r = minSide * (radiusFactor + 0.18 * (math.sin(progress * 2 * 3.141592653589793 * speed + angle)));
    final double a = angle + progress * 2 * 3.141592653589793 * speed;
    return Offset(
      center.dx + r * math.cos(a),
      center.dy + r * math.sin(a),
    );
  }
} 