import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    try {
      // Simplified query to avoid index issues
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('notifications')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isRead'] == false) {
          await NotificationService().markNotificationAsRead(widget.userId, doc.id);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7),
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white : Colors.black));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, color: Colors.white54, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notifications will appear here',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final notificationData = notification.data() as Map<String, dynamic>;
                  
                  return _buildNotificationCard(notification, notificationData, isWide);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(DocumentSnapshot notification, Map<String, dynamic> notificationData, bool isWide) {
    final isRead = notificationData['isRead'] ?? false;
    final title = notificationData['title'] ?? 'No Title';
    final body = notificationData['body'] ?? 'No Description';
    final type = notificationData['type'] ?? 'general';
    final timestamp = notificationData['timestamp'] as Timestamp?;
    final fromUserName = notificationData['fromUserName'] ?? 'Unknown User';

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'exchange_request':
        typeColor = Colors.orange;
        typeIcon = Icons.swap_horiz;
        break;
      case 'message':
        typeColor = Colors.blue;
        typeIcon = Icons.message;
        break;
      case 'project_update':
        typeColor = Colors.green;
        typeIcon = Icons.update;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.notifications;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isWide ? 20 : 16),
      padding: EdgeInsets.all(isWide ? 24 : 20),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFF2C2C2C).withOpacity(0.7) : const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(isWide ? 20 : 16),
        border: isRead ? null : Border.all(color: typeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type icon and timestamp
          Row(
            children: [
              Container(
                width: isWide ? 48 : 40,
                height: isWide ? 48 : 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isWide ? 12 : 10),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: isWide ? 24 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWide ? 18 : 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: isWide ? 14 : 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Notification body
          Text(
            body,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isWide ? 16 : 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action buttons for specific notification types
          if (type == 'exchange_request' && !isRead) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to exchange requests screen
                      Navigator.of(context).pop();
                      // You can add navigation logic here
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isWide ? 12 : 8),
                      ),
                    ),
                    child: const Text(
                      'View Request',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await NotificationService().markNotificationAsRead(widget.userId, notification.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isWide ? 12 : 8),
                      ),
                    ),
                    child: const Text(
                      'Mark as Read',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!isRead) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await NotificationService().markNotificationAsRead(widget.userId, notification.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWide ? 12 : 8),
                  ),
                ),
                child: const Text(
                  'Mark as Read',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(notificationTime);
    }
  }
}
