import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'group_chat_screen.dart'; // Add this import
import 'department_list_screen.dart'; // Add this import
import 'fun_group_chat_screen.dart'; // Add this import

class CommunityScreen extends StatelessWidget {
  final String userId;
  final bool showAppBar; // Add this line

  const CommunityScreen({super.key, required this.userId, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: isDarkMode ? Colors.white : Colors.black,
              title: const Text('Community'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CommunityCard(
                  title: 'Discussion',
                  icon: Icons.forum,
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DepartmentListScreen(userId: userId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 32),
                _CommunityCard(
                  title: 'Fun',
                  icon: Icons.emoji_emotions,
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FunGroupChatScreen(userId: userId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.25),
              radius: 36,
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 