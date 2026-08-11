import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/splash/presentation/bloc/splash_cubit.dart';
import 'features/splash/presentation/bloc/splash_state.dart';
import 'dashboard_screen.dart';
import 'web_dashboard_screen.dart';
import 'web_homepage.dart';
import 'new_idea_screen.dart';
import 'chat_project_exchange_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    // Trigger session check via BLoC after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashCubit>().checkSession();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) async {
        if (state is SplashAuthed) {
          // Check for pending notification before navigating to dashboard
          final prefs = await SharedPreferences.getInstance();
          final pendingType = prefs.getString('pending_notification_type');
          
          if (pendingType == 'chat_message') {
            final fromUserId = prefs.getString('pending_notification_from_user_id');
            final fromUserName = prefs.getString('pending_notification_from_user_name');
            final currentUserId = state.userId;
            
            // Clear the pending notification data
            await prefs.remove('pending_notification_type');
            await prefs.remove('pending_notification_from_user_id');
            await prefs.remove('pending_notification_from_user_name');
            
            if (fromUserId != null) {
              print("🔥 === SPLASH SCREEN: NAVIGATING TO CHAT FROM NOTIFICATION ===");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => kIsWeb 
                    ? WebDashboardScreen()
                    : ChatProjectExchangeScreen(
                        currentUserId: currentUserId,
                        profileUserId: fromUserId,
                        otherUserName: fromUserName,
                        userPlan: 'Free',
                      )),
              );
              return;
            }
          }
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => kIsWeb 
                ? WebDashboardScreen()
                : DashboardScreen(userId: state.userId)),
          );
        } else if (state is SplashGuest) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => kIsWeb 
                ? WebHomePage()
                : NewIdeaScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF232323),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: StableParallaxLinesPainter(_animationController.value, lineColor: Colors.white),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 350,
                      height: 350,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StableParallaxLinesPainter extends CustomPainter {
  final double progress;
  final Color lineColor;
  static final int points = 24;
  static final List<_MovingPoint> basePoints = List.generate(
    points,
    (i) => _MovingPoint(
      angle: 2 * pi * i / points,
      radiusFactor: 0.25 + 0.25 * (i % 3),
      speed: 0.5 + 0.2 * (i % 5),
    ),
  );

  StableParallaxLinesPainter(this.progress, {this.lineColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;

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
  bool shouldRepaint(covariant StableParallaxLinesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lineColor != lineColor;
  }
}

class _MovingPoint {
  final double angle;
  final double radiusFactor;
  final double speed;
  _MovingPoint({required this.angle, required this.radiusFactor, required this.speed});

  Offset position(Offset center, double minSide, double progress) {
    final double r = minSide * (radiusFactor + 0.18 * sin(progress * 2 * pi * speed + angle));
    final double a = angle + progress * 2 * pi * speed;
    return Offset(
      center.dx + r * cos(a),
      center.dy + r * sin(a),
    );
  }
}
