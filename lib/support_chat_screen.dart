import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'dart:async';

class SupportChatScreen extends StatefulWidget {
  final String userId;
  final String category; // e.g., 'Live Chat'
  const SupportChatScreen({super.key, required this.userId, required this.category});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _controller = TextEditingController();
  late final String ticketId;

  @override
  void initState() {
    super.initState();
    ticketId = '${widget.userId}_${widget.category}';
    _ensureTicket();
    // Store FCM token for push notifications
    _storeFCMToken();
  }

  Future<void> _ensureTicket() async {
    final docRef = FirebaseFirestore.instance.collection('supportTickets').doc(ticketId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'userId': widget.userId,
        'category': widget.category,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final docRef = FirebaseFirestore.instance.collection('supportTickets').doc(ticketId);
    await docRef.collection('messages').add({
      'text': text,
      'senderId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });
    await docRef.set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Send notification to support team/admin
    try {
      // Get current user data for notification
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      final currentUserName = currentUserData?['name'] ?? 
                              currentUserData?['userName'] ?? 
                              currentUserData?['fullName'] ?? 
                              'User';

      // Send support chat notification
      await NotificationService().sendChatMessageNotification(
        fromUserId: widget.userId,
        fromUserName: currentUserName,
        toUserId: 'support_team', // Support team ID
        toUserName: 'Support Team',
        messageText: 'New ${widget.category}: $text',
      );
      print('Support chat notification sent');
    } catch (e) {
      print('Error sending support chat notification: $e');
    }
  }

  Future<void> _storeFCMToken() async {
    try {
      await NotificationService().storeUserToken(widget.userId);
      print('✅ FCM token stored for support chat user');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('supportTickets').doc(ticketId);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: const Color(0xFF2C2C2C), // light dark grey
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF232323),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: docRef.collection('messages').orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMine = data['senderId'] == widget.userId;
                    final rawTs = data['timestamp'];
                    DateTime dt;
                    if (rawTs is Timestamp) {
                      dt = rawTs.toDate();
                    } else if (rawTs is DateTime) {
                      dt = rawTs;
                    } else {
                      dt = DateTime.fromMillisecondsSinceEpoch(0);
                    }
                    final tsStr = DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.amber : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data['text'] ?? '').toString(),
                              style: TextStyle(color: isMine ? Colors.black : Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tsStr,
                              style: TextStyle(
                                color: (isMine ? Colors.black : Colors.white).withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF2C2C2C), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
