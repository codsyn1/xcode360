import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _currentUserId = 'Unknown';
  String _fcmToken = 'Unknown';
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getFCMToken();
  }

  void _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId') ?? 'Not logged in';
    });
  }

  void _getFCMToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _fcmToken = token ?? 'No token';
    });
  }

  void _testNotificationFlow() async {
    setState(() {
      _testResult = 'Testing notification flow...\n\n';
    });

    // Test 1: Check current user
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    
    setState(() {
      _testResult += 'Current User ID: $currentUserId\n';
      _testResult += 'FCM Token: ${_fcmToken.substring(0, 20)}...\n\n';
    });

    // Test 2: Simulate incoming notification
    final testMessage = {
      'data': {
        'type': 'chat_message',
        'fromUserId': '6gibNQHPOvT71t6buyclpN3vVjx2', // Different user
        'toUserId': '00s2X3c47kfTrhv88NiNMXrTfem1', // Current user
        'fromUserName': 'Test User',
        'messageText': 'Test notification message',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'notification': {
        'title': 'New Message',
        'body': 'Test User: Test notification message',
      },
    };

    setState(() {
      _testResult += 'Test Message Data:\n';
      _testResult += 'To User: ${testMessage['data']['toUserId']}\n';
      _testResult += 'From User: ${testMessage['data']['fromUserId']}\n';
      _testResult += 'Current User: $currentUserId\n\n';
    });

    // Test 3: Check if user should receive notification
    final toUserId = testMessage['data']['toUserId'];
    final fromUserId = testMessage['data']['fromUserId'];
    
    if (toUserId == currentUserId) {
      setState(() {
        _testResult += '✅ NOTIFICATION FOR CURRENT USER - SHOULD SHOW\n';
      });
    } else if (fromUserId == currentUserId) {
      setState(() {
        _testResult += '⚠️ CURRENT USER IS SENDER - ALLOWING FOR TESTING\n';
      });
    } else {
      setState(() {
        _testResult += '❌ NOTIFICATION FOR DIFFERENT USER - SHOULD NOT SHOW\n';
      });
    }

    setState(() {
      _testResult += '\n✅ Notification flow test completed!\n';
      _testResult += '\nExpected: User should see notification above';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: $_currentUserId'),
                    Text('FCM Token: ${_fcmToken.substring(0, 20)}...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testNotificationFlow,
              child: const Text('Test Notification Flow'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_testResult),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
