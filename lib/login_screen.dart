import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'forget_password_screen.dart';
import 'sign_up_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // The form content — shared between desktop and mobile
    Widget formContent = Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: isDarkMode ? Colors.white70 : Colors.black54),
          const SizedBox(height: 32),
          Text(
            'Login to XCode360',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: usernameController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter your username' : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: passwordController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                );
              },
              child: Text(
                'Forgot password?',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // Firestore login logic
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();
                  try {
                    final query = await FirebaseFirestore.instance
                        .collection('users')
                        .where('username', isEqualTo: username)
                        .where('password', isEqualTo: password)
                        .limit(1)
                        .get();
                    if (query.docs.isNotEmpty) {
                      final userId = query.docs.first.id;
                      // Save login state
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);
                      await prefs.setString('userId', userId);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(userId: userId),
                        ),
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid username or password.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $e')),
                    );
                  }
                }
              },
              child: const Text('LOGIN'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      // ── Desktop: centered card over animated background ──
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            Container(color: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7)),
            AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _LoginParallaxPainter(_bgAnimationController.value, isDarkMode: isDarkMode),
                );
              },
            ),
            Center(
              child: SingleChildScrollView(
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
                  child: formContent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile: original layout unchanged ──
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: formContent,
          ),
        ),
      ),
    );
  }
}

/// Simple parallax dots painter for the login desktop background
class _LoginParallaxPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;
  _LoginParallaxPainter(this.progress, {required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const double spacing = 32;
    const double radius = 2.0;
    final double move = progress * spacing * 2;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dx = x + ((y ~/ spacing) % 2 == 0 ? 0 : spacing / 2) + move;
        final dy = y + move * 0.5;
        canvas.drawCircle(Offset(dx % size.width, dy % size.height), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoginParallaxPainter oldDelegate) =>
      oldDelegate.progress != progress;
} 