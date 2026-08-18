import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'forget_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 