import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';

class HireMeScreen extends StatelessWidget {
  const HireMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Me'),
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F7),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      body: Center(
        child: Text(
          'Welcome to the Hire Me feature! (Coming soon)',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 