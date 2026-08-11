import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectNotificationTest extends StatefulWidget {
  const DirectNotificationTest({super.key});

  @override
  State<DirectNotificationTest> createState() => _DirectNotificationTestState();
}

class _DirectNotificationTestState extends State<DirectNotificationTest> {
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testDirectNotification() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing direct notification...\n\n';
    });

    try {
      // Get current user
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');
      
      setState(() {
        _testResult += 'Current User ID: $currentUserId\n\n';
      });

      // Test User B's FCM token directly
      final userBDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('6gibNQHPOvT71t6buyclpN3vVjx2') // User B's ID
          .get();
      
      if (!userBDoc.exists) {
        setState(() {
          _testResult += '❌ User B not found\n';
          _isLoading = false;
        });
        return;
      }

      final userBData = userBDoc.data() as Map<String, dynamic>;
      final userBFcmToken = userBData['fcmToken'];
      
      setState(() {
        _testResult += 'User B FCM Token: ${userBFcmToken?.substring(0, 20)}...\n\n';
      });

      // Send direct notification to User B
      final message = {
        'token': userBFcmToken,
        'notification': {
          'title': 'Direct Test Notification',
          'body': 'This is a direct test to User B',
        },
        'data': {
          'type': 'direct_test',
          'fromUserId': currentUserId,
          'toUserId': '6gibNQHPOvT71t6buyclpN3vVjx2',
          'test': 'direct_notification_test',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            'clickAction': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      setState(() {
        _testResult += 'Sending direct notification to User B...\n';
        _testResult += 'Message: ${message['notification']['title']}\n';
        _testResult += 'Body: ${message['notification']['body']}\n\n';
      });

      // Send using Firebase Admin SDK (via Cloud Function)
      final notificationRef = await FirebaseFirestore.instance
          .collection('push_notifications')
          .add({
            ...message,
            'toUserId': '6gibNQHPOvT71t6buyclpN3vVjx2',
            'timestamp': FieldValue.serverTimestamp(),
            'isProcessed': false,
          });

      setState(() {
        _testResult += '✅ Direct notification queued\n';
        _testResult += 'Notification ID: ${notificationRef.id}\n';
        _testResult += 'Target: User B (6gibNQHPOvT71t6buyclpN3vVjx2)\n';
        _testResult += 'Expected: User B should receive notification\n\n';
      });

    } catch (e) {
      setState(() {
        _testResult += '❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotificationToUserA() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing notification to User A...\n\n';
    });

    try {
      // Get User A's FCM token
      final userADoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('00s2X3c47kfTrhv88NiNMXrTfem1') // User A's ID
          .get();
      
      if (!userADoc.exists) {
        setState(() {
          _testResult += '❌ User A not found\n';
          _isLoading = false;
        });
        return;
      }

      final userAData = userADoc.data() as Map<String, dynamic>;
      final userAFcmToken = userAData['fcmToken'];
      
      setState(() {
        _testResult += 'User A FCM Token: ${userAFcmToken?.substring(0, 20)}...\n\n';
      });

      // Send notification to User A
      final message = {
        'token': userAFcmToken,
        'notification': {
          'title': 'Test to User A',
          'body': 'This is a test to User A',
        },
        'data': {
          'type': 'test_to_user_a',
          'fromUserId': '6gibNQHPOvT71t6buyclpN3vVjx2',
          'toUserId': '00s2X3c47kfTrhv88NiNMXrTfem1',
          'test': 'test_notification_to_user_a',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            'clickAction': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      setState(() {
        _testResult += 'Sending notification to User A...\n';
        _testResult += 'Message: ${message['notification']['title']}\n';
        _testResult += 'Body: ${message['notification']['body']}\n\n';
      });

      // Send via Cloud Function
      final notificationRef = await FirebaseFirestore.instance
          .collection('push_notifications')
          .add({
            ...message,
            'toUserId': '00s2X3c47kfTrhv88NiNMXrTfem1',
            'timestamp': FieldValue.serverTimestamp(),
            'isProcessed': false,
          });

      setState(() {
        _testResult += '✅ Notification to User A queued\n';
        _testResult += 'Notification ID: ${notificationRef.id}\n';
        _testResult += 'Target: User A (00s2X3c47kfTrhv88NiNMXrTfem1)\n';
        _testResult += 'Expected: User A should receive notification\n\n';
      });

    } catch (e) {
      setState(() {
        _testResult += '❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Notification Test'),
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
                      'Direct Notification Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This test sends notifications directly to specific users to verify FCM token delivery.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testDirectNotification,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Test Notification to User B'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testNotificationToUserA,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Test Notification to User A'),
                    ),
                  ],
                ),
              ),
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
