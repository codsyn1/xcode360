import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock_reset, size: 64, color: isDarkMode ? Colors.white70 : Colors.black54),
          const SizedBox(height: 32),
          Text(
            'Reset Your Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Enter your email address',
              labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || value.isEmpty ? 'Enter your email' : null,
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
                if (_formKey.currentState!.validate()) {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: _emailController.text.trim(),
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Password reset link sent to your email.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to send reset link: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('SUBMIT'),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
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
                  painter: _ForgetPasswordParallaxPainter(_bgAnimationController.value, isDarkMode: isDarkMode),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
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

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        title: Text('Forgot Password', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      ),
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

/// Simple parallax dots painter for the desktop background
class _ForgetPasswordParallaxPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;
  _ForgetPasswordParallaxPainter(this.progress, {required this.isDarkMode});

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
  bool shouldRepaint(covariant _ForgetPasswordParallaxPainter oldDelegate) =>
      oldDelegate.progress != progress;
}