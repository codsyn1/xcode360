import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFirebaseService {
  final String userId;

  ChatFirebaseService({required this.userId});

  Future<List<Map<String, dynamic>>> getSortedChats() async {
    try {
      final chatDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chats')
          .get();

      final sortedChats = <Map<String, dynamic>>[];
      
      for (final chatDoc in chatDocs.docs) {
        final messagesSnap = await chatDoc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        int latestMessageTime = 0;
        if (messagesSnap.docs.isNotEmpty) {
          final messageData = messagesSnap.docs.first.data() as Map<String, dynamic>?;
          if (messageData?['timestamp'] != null) {
            if (messageData!['timestamp'] is Timestamp) {
              latestMessageTime = (messageData!['timestamp'] as Timestamp).millisecondsSinceEpoch;
            } else if (messageData!['timestamp'] is int) {
              latestMessageTime = messageData!['timestamp'] as int;
            }
          }
        }
        
        sortedChats.add({
          'chatDoc': chatDoc,
          'latestTime': latestMessageTime,
        });
      }
      
      // Sort by latest message time (newest first)
      sortedChats.sort((a, b) => (b['latestTime'] as int).compareTo(a['latestTime'] as int));
      return sortedChats;
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchChats() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'chatDoc': doc,
          'latestTime': DateTime.now().millisecondsSinceEpoch, // Placeholder for real-time updates
        }).toList());
  }
}
