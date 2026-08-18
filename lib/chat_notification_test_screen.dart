import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_project_exchange_screen.dart';

class ChatNotificationTestScreen extends StatelessWidget {
  const ChatNotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Chat Notifications')),
        body: const Center(
          child: Text('Please log in first'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Test Chat Notifications',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Exchange Request from Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Click the button below to open a test chat screen. In the chat screen:\n\n'
              '1. Click the "Start Exchange" button in the app bar\n'
              '2. Fill the exchange form\n'
              '3. Click "Send Request"\n\n'
              'This will send an offline notification to the test user.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Test with different user IDs
            const Text(
              'Test User IDs:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildTestUserCard(
                    context,
                    userId: 'test_user_1',
                    userName: 'Test User 1',
                    description: 'Test exchange notifications with this user',
                  ),
                  const SizedBox(height: 12),
                  _buildTestUserCard(
                    context,
                    userId: 'test_user_2', 
                    userName: 'Test User 2',
                    description: 'Another test user for notifications',
                  ),
                  const SizedBox(height: 12),
                  _buildTestUserCard(
                    context,
                    userId: user.uid, // Self test
                    userName: 'Yourself',
                    description: 'Send notification to yourself for testing',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestUserCard(
    BuildContext context, {
    required String userId,
    required String userName,
    required String description,
  }) {
    return Card(
      color: const Color(0xFF2C2C2C),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: $userId',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatProjectExchangeScreen(
                        currentUserId: FirebaseAuth.instance.currentUser!.uid,
                        profileUserId: userId,
                        otherUserName: userName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Chat Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
