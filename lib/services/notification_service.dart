import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Send chat message notification
  Future<void> sendChatMessageNotification({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String messageText,
  }) async {
    try {
      print('🔥 === STARTING CHAT MESSAGE NOTIFICATION ===');
      print('📤 FROM: $fromUserId ($fromUserName)');
      print('📥 TO: $toUserId ($toUserName)');
      print('📝 MESSAGE: $messageText');
      
      // CRITICAL VALIDATION: Ensure we're not sending to sender
      if (fromUserId == toUserId) {
        print('❌ SENDER AND RECEIVER ARE THE SAME USER - SKIPPING');
        print('❌ THIS IS A SELF-MESSAGE - NOTIFICATION NOT NEEDED');
        print('🔥 === NOTIFICATION SKIPPED ===');
        return;
      }
      
      // Get receiver's FCM token from Firestore
      print('🔍 FETCHING RECEIVER DOCUMENT FROM FIRESTORE...');
      final receiverDoc = await _firestore.collection('users').doc(toUserId).get();
      
      if (!receiverDoc.exists) {
        print('❌ RECEIVER DOCUMENT NOT FOUND: $toUserId');
        print('❌ CANNOT SEND NOTIFICATION - USER DOES NOT EXIST');
        print('❌ CHECK IF USER ID IS CORRECT');
        print('🔥 === NOTIFICATION FAILED ===');
        return;
      }
      
      print('✅ RECEIVER DOCUMENT FOUND');
      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final fcmToken = receiverData['fcmToken'];
      final tokenUserId = receiverData['tokenUserId'];
      final deviceActive = receiverData['deviceActive'] ?? false;
      final lastTokenUpdate = receiverData['lastTokenUpdate'];
      
      print('📊 RECEIVER DATA ANALYSIS:');
      print('   FCM TOKEN: ${fcmToken ?? "NULL"}');
      print('   TOKEN USER ID: $tokenUserId');
      print('   DEVICE ACTIVE: $deviceActive');
      print('   LAST TOKEN UPDATE: $lastTokenUpdate');
      print('   EXPECTED RECEIVER ID: $toUserId');
      print('   MESSAGE FROM USER: $fromUserId');
      
      // CRITICAL VALIDATION: Ensure token belongs to correct user
      // FIXED: Allow notification if tokenUserId is null (legacy data) or matches
      if (tokenUserId != null && tokenUserId != toUserId) {
        print('❌ !!! CRITICAL ERROR: TOKEN BELONGS TO WRONG USER !!!');
        print('❌ !!! TOKEN USER ID: $tokenUserId !!!');
        print('❌ !!! EXPECTED USER ID: $toUserId !!!');
        print('❌ !!! NOTIFICATION WILL GO TO WRONG USER !!!');
        print('❌ !!! SKIPPING NOTIFICATION TO PREVENT WRONG USER DELIVERY !!!');
        print('🔥 === NOTIFICATION SKIPPED ===');
        return; // Skip notification to prevent wrong user delivery
      }
      
      // If tokenUserId is null, this is legacy data - allow notification but log warning
      if (tokenUserId == null && fcmToken != null) {
        print('⚠️ TOKEN USER ID IS NULL (LEGACY DATA)');
        print('⚠️ ALLOWING NOTIFICATION BUT TOKEN SHOULD BE UPDATED');
      }
      
      // CRITICAL VALIDATION: Ensure receiver has an active device
      if (!deviceActive) {
        print('⚠️ RECEIVER DEVICE IS NOT ACTIVE');
        print('⚠️ RECEIVER MAY NOT RECEIVE PUSH NOTIFICATION');
      }
      
      // NOTE: For same device testing, we'll allow same token notifications
      // In production, different devices will have different tokens anyway
      if (fcmToken != null && fcmToken.toString().isNotEmpty) {
        print('✅ RECEIVER FCM TOKEN VALIDATED');
        print('✅ NOTIFICATION WILL BE SENT TO: $toUserId');
        print('✅ SENDER: $fromUserId -> RECEIVER: $toUserId');
      }
      
      // Store notification in database for offline access (always do this)
      print('💾 STORING OFFLINE NOTIFICATION...');
      await _storeOfflineNotification(
        toUserId: toUserId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        title: 'New Message',
        body: '$fromUserName: $messageText',
        type: 'chat_message',
        requestId: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      );
      print('✅ OFFLINE NOTIFICATION STORED');

      if (fcmToken == null || fcmToken.toString().trim().isEmpty) {
        print('❌ NO FCM TOKEN FOUND FOR RECEIVER: $toUserId');
        print('❌ OFFLINE NOTIFICATION STORED ONLY');
        print('❌ RECEIVER WILL NOT RECEIVE PUSH NOTIFICATION');
        print('🔥 === NOTIFICATION COMPLETED (OFFLINE ONLY) ===');
        return; // Don't try to send push notification without token
      }
      
      print('✅ FCM TOKEN FOUND: ${fcmToken.substring(0, 10)}...');
      print('📤 CREATING PUSH NOTIFICATION PAYLOAD...');
      
      // Create a notification document to trigger Cloud Function
      // Use both 'notification' and 'data' fields
      // 'notification' field displays the message content
      // 'data' field contains info for app to handle tap
      final notificationPayload = {
        'notification': {
          'title': 'New Message',
          'body': '$fromUserName: $messageText',
        },
        'data': {
          'type': 'chat_message',
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'toUserId': toUserId,
          'messageText': messageText,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'toUserId': toUserId,
        'fcmToken': fcmToken,
        'timestamp': FieldValue.serverTimestamp(),
        'isProcessed': false,
      };

      // Store in notifications collection to trigger Cloud Function
      print('📤 SENDING TO CLOUD FUNCTION VIA FIRESTORE...');
      final notificationRef = await _firestore.collection('push_notifications').add(notificationPayload);
      
      print('✅ Chat message notification queued successfully');
      print('📝 NOTIFICATION DOC ID: ${notificationRef.id}');
      print('📱 PUSH NOTIFICATION TRIGGERED FOR USER: $toUserId');
      print('🔥 === NOTIFICATION SENT SUCCESSFULLY ===');
      
    } catch (e) {
      print('❌ Error sending chat message notification: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      print('🔥 === NOTIFICATION FAILED WITH ERROR ===');
    }
  }

  /// Send offline notification when project exchange request is submitted
  Future<void> sendExchangeRequestNotification({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String projectTitle,
    required String requestId,
  }) async {
    try {
      print('=== SENDING EXCHANGE REQUEST NOTIFICATION ===');
      
      // Get receiver's FCM token
      final receiverDoc = await _firestore
          .collection('users')
          .doc(toUserId)
          .get();
      
      if (!receiverDoc.exists) {
        print('Receiver document does not exist');
        return;
      }

      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final fcmToken = receiverData['fcmToken'];
      
      // Store notification in database for offline access (always do this)
      await _storeOfflineNotification(
        toUserId: toUserId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        title: 'Project Exchange Request',
        body: '$fromUserName wants to exchange project: $projectTitle',
        type: 'exchange_request',
        requestId: requestId,
      );

      if (fcmToken == null || fcmToken.toString().trim().isEmpty) {
        print('No FCM token found for receiver: $toUserId');
        print('Notification stored for offline access only');
        return;
      }

      print('FCM token found: ${fcmToken.substring(0, 10)}...');
      
      // Create a notification document to trigger Cloud Function
      // Use both 'notification' and 'data' fields
      final notificationPayload = {
        'notification': {
          'title': 'Project Exchange Request',
          'body': '$fromUserName wants to exchange project: $projectTitle',
        },
        'data': {
          'type': 'exchange_request',
          'requestId': requestId,
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'toUserId': toUserId,
          'projectTitle': projectTitle,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'toUserId': toUserId,
        'fcmToken': fcmToken,
        'timestamp': FieldValue.serverTimestamp(),
        'isProcessed': false,
      };

      // Store in notifications collection to trigger Cloud Function
      await _firestore.collection('push_notifications').add(notificationPayload);

      print('✅ Exchange request notification queued successfully');
      
    } catch (e) {
      print('❌ Error sending exchange request notification: $e');
      // Even if push notification fails, we already stored it for offline access
    }
  }

  /// Store notification in Firestore for offline access
  Future<void> _storeOfflineNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String title,
    required String body,
    required String type,
    required String requestId,
  }) async {
    try {
      final notification = {
        'title': title,
        'body': body,
        'type': type,
        'requestId': requestId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isOffline': true,
      };

      // Store in user's notifications collection
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add(notification);

      // Also store in global notifications collection
      await _firestore.collection('notifications').add(notification);

      // Update receiver's unread notification count
      await _updateReceiverNotificationCount(toUserId);

      print('✅ Offline notification stored successfully');
      
    } catch (e) {
      print('❌ Error storing offline notification: $e');
    }
  }

  /// Update receiver's notification count
  Future<void> _updateReceiverNotificationCount(String toUserId) async {
    try {
      final notificationsRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false);

      final snapshot = await notificationsRef.get();
      final unreadCount = snapshot.docs.length;

      await _firestore.collection('users').doc(toUserId).update({
        'unreadNotifications': unreadCount,
        'lastNotificationUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Updated unread count for user $toUserId: $unreadCount');
    } catch (e) {
      print('❌ Error updating notification count: $e');
    }
  }

  /// Get user's FCM token and store it in Firestore
  Future<void> storeUserToken(String userId) async {
    try {
      print('🔥 === STARTING FCM TOKEN STORAGE FOR USER: $userId ===');
      
      // Wait for Firebase to be ready
      int retryCount = 0;
      String? token;
      
      while (retryCount < 5) {
        token = await _messaging.getToken();
        print('🔍 Attempt ${retryCount + 1}: FCM Token = ${token?.substring(0, 20) ?? "NULL"}...');
        
        if (token != null && token.isNotEmpty) {
          break;
        }
        
        print('⏳ Waiting for FCM token... (attempt ${retryCount + 1}/5)');
        await Future.delayed(const Duration(seconds: 1));
        retryCount++;
      }
      
      print('🔥 === FINAL FCM TOKEN RESULT ===');
      print('🔑 Token: ${token?.substring(0, 20) ?? "NULL"}...');
      print('🔄 Retry attempts: $retryCount');
      
      if (token != null && token.isNotEmpty) {
        // CRITICAL FIX: Clear this token from ALL other users before assigning to current user
        // This prevents same-device token conflicts
        print('🔍 SEARCHING FOR USERS WITH SAME TOKEN...');
        print('🔍 CURRENT TOKEN: ${token.substring(0, 20)}...');
        print('🔍 CURRENT USER ID: $userId');
        
        final usersWithSameToken = await _firestore
            .collection('users')
            .where('fcmToken', isEqualTo: token)
            .get();
        
        print('🔍 Found ${usersWithSameToken.docs.length} users with same token');
        
        for (final doc in usersWithSameToken.docs) {
          final existingUserId = doc.id;
          final existingUserData = doc.data();
          final existingTokenUserId = existingUserData['tokenUserId'];
          final existingFcmToken = existingUserData['fcmToken'];
          
          print('🔍 Checking user: $existingUserId');
          print('🔍 Token User ID: $existingTokenUserId');
          print('🔍 FCM Token: ${existingFcmToken?.substring(0, 20) ?? "NULL"}...');
          
          if (existingUserId != userId) {
            print('🗑️ CLEARING TOKEN FROM WRONG USER: $existingUserId');
            print('🗑️ This token should belong to $userId, not $existingUserId');
            await _firestore.collection('users').doc(existingUserId).update({
              'fcmToken': null,
              'deviceActive': false,
              'tokenUserId': null,
            });
            print('✅ Token cleared from user: $existingUserId');
          } else {
            print('✅ Token already belongs to current user: $existingUserId');
            print('✅ No need to update token');
          }
        }
        
        // Store token for current user
        final deviceId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
        
        print('📝 STORING TOKEN FOR CURRENT USER: $userId');
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'deviceActive': true,
          'deviceId': deviceId,
          'tokenUserId': userId, // Explicit link
          'userId': userId, // Add userId for tracking
        });
        print('✅ FCM token stored for user: $userId');
        print('📱 Device ID: $deviceId');
        print('🔒 Cleared token from ${usersWithSameToken.docs.length} other users');
        print('📱 Device marked as ACTIVE');
        print('🔥 === FCM TOKEN STORAGE COMPLETE ===');
      } else {
        print('❌ NO FCM TOKEN AVAILABLE AFTER 5 RETRIES FOR USER: $userId');
        print('❌ USER WILL NOT RECEIVE PUSH NOTIFICATIONS');
        print('🔥 === FCM TOKEN STORAGE FAILED ===');
      }
    } catch (e) {
      print('❌ Error storing FCM token: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Validate user has FCM token
  Future<bool> validateUserToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User document not found: $userId');
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'];
      final deviceActive = userData['deviceActive'] ?? false;
      
      print('🔍 TOKEN VALIDATION FOR $userId:');
      print('   TOKEN EXISTS: ${fcmToken != null && fcmToken.toString().isNotEmpty}');
      print('   DEVICE ACTIVE: $deviceActive');
      
      return fcmToken != null && fcmToken.toString().isNotEmpty;
    } catch (e) {
      print('❌ Error validating user token: $e');
      return false;
    }
  }

  /// Listen for token refresh and update in Firestore
  void listenForTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        // Clear this new token from all other users first
        final usersWithSameToken = await _firestore
            .collection('users')
            .where('fcmToken', isEqualTo: newToken)
            .get();
        
        for (final doc in usersWithSameToken.docs) {
          final existingUserId = doc.id;
          if (existingUserId != userId) {
            await _firestore.collection('users').doc(existingUserId).update({
              'fcmToken': null,
              'deviceActive': false,
              'tokenUserId': null,
            });
          }
        }
        
        // Update current user's token
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'tokenUserId': userId,
        });
        print('🔄 FCM token refreshed and updated for user: $userId');
      } catch (e) {
        print('❌ Error updating refreshed FCM token: $e');
      }
    });
  }

  /// Clear user's FCM token when they logout
  Future<void> clearUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': null,
        'deviceActive': false,
        'tokenUserId': null,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token cleared for user: $userId');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Listen for real-time notifications for a user
  Stream<QuerySnapshot> getNotificationStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      // Simplified query to avoid index issues
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isRead'] == false) {
          unreadCount++;
        }
      }
      
      return unreadCount;
    } catch (e) {
      print('❌ Error getting unread notifications count: $e');
      return 0;
    }
  }
}
