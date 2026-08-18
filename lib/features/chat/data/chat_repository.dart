import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/notification_service.dart';

class ChatRepository {
  final FirebaseFirestore _db;
  ChatRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Future<String> getUserPlan(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    return (userDoc.data()?['plan'] ?? 'Free').toString();
  }

  Future<int> getActiveSentExchangeCount(String fromUserId, String toUserId) async {
    final sentRequests = await _db
        .collection('exchanges')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();
    final active = sentRequests.docs.where((d) {
      final status = (d.data()['status'] ?? 'pending').toString().toLowerCase();
      return status != 'cancelled' && status != 'deleted';
    }).length;
    return active;
  }

  Future<void> markIncomingMessagesAsSeen(String currentUserId, String profileUserId) async {
    final query = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(profileUserId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('seen', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      await doc.reference.update({'seen': true});
    }
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String profileUserId,
    required String text,
  }) async {
    final messageData = {
      'text': text,
      'senderId': currentUserId,
      'receiverId': profileUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    };
    // Sender side
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(profileUserId)
        .set({
          'userId': profileUserId,
          'lastMessage': text,
          'lastTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(profileUserId)
        .collection('messages')
        .add(messageData);
    // Receiver side
    await _db
        .collection('users')
        .doc(profileUserId)
        .collection('chats')
        .doc(currentUserId)
        .set({
          'userId': currentUserId,
          'lastMessage': text,
          'lastTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await _db
        .collection('users')
        .doc(profileUserId)
        .collection('chats')
        .doc(currentUserId)
        .collection('messages')
        .add(messageData);

    // Send notification to receiver
    try {
      // Get sender's name for notification
      final senderDoc = await _db.collection('users').doc(currentUserId).get();
      if (!senderDoc.exists) {
        print('❌ ERROR: Sender user document does not exist: $currentUserId');
      }
      final senderData = senderDoc.data();
      final senderName = senderData?['name'] ?? 
                          senderData?['userName'] ?? 
                          senderData?['fullName'] ?? 
                          'User';
      
      // Get receiver's name for notification
      final receiverDoc = await _db.collection('users').doc(profileUserId).get();
      if (!receiverDoc.exists) {
        print('❌ ERROR: Receiver user document does not exist: $profileUserId');
      }
      final receiverData = receiverDoc.data();
      final receiverName = receiverData?['name'] ?? 
                           receiverData?['userName'] ?? 
                           receiverData?['fullName'] ?? 
                           'User';

      print('📤 Sending notification from: $currentUserId ($senderName)');
      print('📥 Sending notification to: $profileUserId ($receiverName)');

      // Send chat message notification
      await NotificationService().sendChatMessageNotification(
        fromUserId: currentUserId,
        fromUserName: senderName,
        toUserId: profileUserId,
        toUserName: receiverName,
        messageText: text,
      );
      print('✅ Chat notification sent from $currentUserId to $profileUserId');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
}
