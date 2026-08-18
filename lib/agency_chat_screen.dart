import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'agency_exchange_projects_screen.dart';
import '../services/notification_service.dart';

class AgencyChatScreen extends StatefulWidget {
  final String currentUserId;
  final String agencyId;
  final String agencyName;
  final String? agencyLogo;

  const AgencyChatScreen({
    super.key,
    required this.currentUserId,
    required this.agencyId,
    required this.agencyName,
    this.agencyLogo,
  });

  @override
  State<AgencyChatScreen> createState() => _AgencyChatScreenState();
}

class _AgencyChatScreenState extends State<AgencyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool isLoading = false;
  String? _userProfileImage;
  final Map<String, String?> _userProfileImages = {}; // Cache for user profile images
  StreamSubscription? _userMessagesSubscription;
  StreamSubscription? _agencyMessagesSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupMessageStream();
    // Store FCM token for push notifications
    _storeFCMToken();
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          _userProfileImage = userData?['profileImageUrl'] ?? userData?['profileImage'];
        });
        print('Loaded current user profile image: $_userProfileImage');
      } else {
        print('Current user document not found for ID: ${widget.currentUserId}');
        setState(() {
          _userProfileImage = null;
        });
      }
    } catch (e) {
      print('Error loading current user profile: $e');
      setState(() {
        _userProfileImage = null;
      });
    }
  }

  Future<void> _storeFCMToken() async {
    try {
      await NotificationService().storeUserToken(widget.currentUserId);
      print('✅ FCM token stored for agency chat user');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  Future<String?> _getUserProfileImage(String userId) async {
    // Check cache first
    if (_userProfileImages.containsKey(userId)) {
      return _userProfileImages[userId];
    }
    
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        String? profileImage = userData?['profileImageUrl'] ?? userData?['profileImage'];
        _userProfileImages[userId] = profileImage;
        print('Loaded profile image for user $userId: $profileImage');
        return profileImage;
      } else {
        print('User document not found for ID: $userId');
        _userProfileImages[userId] = null;
        return null;
      }
    } catch (e) {
      print('Error loading user profile image for $userId: $e');
      _userProfileImages[userId] = null;
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _userMessagesSubscription?.cancel();
    _agencyMessagesSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _setupMessageStream() {
    // Setup real-time message stream from both chat directions
    final userChatId = '${widget.currentUserId}_${widget.agencyId}';
    final agencyChatId = '${widget.agencyId}_${widget.currentUserId}';
    
    print('Setting up message stream for agency chat...');
    print('User chat ID: $userChatId');
    print('Agency chat ID: $agencyChatId');
    
    // Try a simpler approach - load initial messages first
    _loadInitialMessages();
    
    // Then setup real-time listeners
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Setup real-time listener for user's agency chat messages
    _userMessagesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('agencyChat')
        .doc(widget.agencyId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      print('User agency chat messages updated: ${snapshot.docs.length}');
      // Debounce to prevent multiple rapid reloads
      _debounceMessageReload();
    });

    // Setup real-time listener for agency's agency chat messages
    _agencyMessagesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.agencyId)
        .collection('agencyChat')
        .doc(widget.currentUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      print('Agency agency chat messages updated: ${snapshot.docs.length}');
      // Debounce to prevent multiple rapid reloads
      _debounceMessageReload();
    });
  }

  void _debounceMessageReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print('Debounce timer triggered - reloading messages');
      _loadAndCombineAllMessages();
    });
  }

  Future<void> _loadAndCombineAllMessages() async {
    try {
      print('🔍 Loading and combining messages from ALL users chatting with agency...');
      
      // Get ALL users who are chatting with this agency
      final agencyChatsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agencyId)
          .collection('agencyChat')
          .get();
      
      print('📊 Found ${agencyChatsSnapshot.docs.length} users chatting with agency ${widget.agencyId}');
      
      final allMessages = <QueryDocumentSnapshot>[];
      
      // Load messages from each user's chat with the agency
      for (final chatDoc in agencyChatsSnapshot.docs) {
        final userId = chatDoc.id;
        print('👤 Loading messages for user: $userId');
        
        try {
          final userMessagesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('agencyChat')
              .doc(widget.agencyId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();
          
          print('✅ Found ${userMessagesSnapshot.docs.length} messages for user $userId');
          allMessages.addAll(userMessagesSnapshot.docs);
          
          // Debug: Print each message
          for (final doc in userMessagesSnapshot.docs) {
            final data = doc.data();
            print('📨 Message: "${data['text']}" from ${data['senderName']} (${data['senderId']})');
          }
          
        } catch (e) {
          print('❌ Error loading messages for user $userId: $e');
        }
      }
      
      print('📱 Total messages from all users: ${allMessages.length}');
      
      // Sort all messages by timestamp
      allMessages.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime); // descending order
      });
      
      // Take the latest 50 messages
      final latestMessages = allMessages.take(50).toList();
      
      // Use the existing combine method (pass null for agency docs since we're loading everything)
      _combineAndHandleMessagesUpdate(latestMessages, null);
      
    } catch (e) {
      print('❌ Error loading and combining messages: $e');
    }
  }

  void _loadInitialMessages() async {
    // Use the same combined loading approach
    await _loadAndCombineAllMessages();
  }

  void _combineAndHandleMessagesUpdate(List<QueryDocumentSnapshot>? userDocs, List<QueryDocumentSnapshot>? agencyDocs) {
    print('=== Combined Message Update Called ===');
    print('User docs: ${userDocs?.length ?? 0}');
    print('Agency docs: ${agencyDocs?.length ?? 0}');
    
    // Get current messages and convert to map for easy lookup
    final currentMessagesMap = <String, Map<String, dynamic>>{};
    for (final message in _messages) {
      final timestamp = message['timestamp'] as int? ?? 0;
      final text = message['text'] as String? ?? '';
      final senderId = message['senderId'] as String? ?? '';
      final receiverId = message['receiverId'] as String? ?? '';
      // Create a more specific unique key including receiverId to prevent collisions
      final uniqueKey = '${timestamp}_${text}_${senderId}_$receiverId';
      currentMessagesMap[uniqueKey] = message;
    }
    
    // Add user messages
    if (userDocs != null) {
      for (final doc in userDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as int? ?? 0;
        final text = data['text'] as String? ?? '';
        final senderId = data['senderId'] as String? ?? '';
        final receiverId = data['receiverId'] as String? ?? '';
        // Use document ID as part of unique key for better uniqueness
        final docId = doc.id;
        final uniqueKey = '${timestamp}_${text}_${senderId}_${receiverId}_$docId';
        currentMessagesMap[uniqueKey] = data;
        print('✅ Added user message: "$text" from ${data['senderName']} ($senderId) to $receiverId (docId: $docId)');
      }
    }
    
    // Add agency messages
    if (agencyDocs != null) {
      for (final doc in agencyDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as int? ?? 0;
        final text = data['text'] as String? ?? '';
        final senderId = data['senderId'] as String? ?? '';
        final receiverId = data['receiverId'] as String? ?? '';
        // Use document ID as part of unique key for better uniqueness
        final docId = doc.id;
        final uniqueKey = '${timestamp}_${text}_${senderId}_${receiverId}_$docId';
        currentMessagesMap[uniqueKey] = data;
        print('✅ Added agency message: "$text" from ${data['senderName']} ($senderId) to $receiverId (docId: $docId)');
      }
    }
    
    setState(() {
      // Convert back to list and sort by timestamp
      _messages = currentMessagesMap.values.toList()
        ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int))
        ..take(50); // Limit to 50 messages
      
      print('📱 Final combined messages list length: ${_messages.length}');
      
      // Print all messages for debugging
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        print('📨 Message $i: "${msg['text']}" from ${msg['senderName']} (${msg['senderId']}) to ${msg['receiverId']} at ${msg['timestamp']}');
      }
    });
    
    // Auto-scroll to bottom for new messages
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessagesUpdate(List<QueryDocumentSnapshot> messageDocs) {
    print('=== Message Update Called ===');
    print('Total message docs received: ${messageDocs.length}');
    
    // Convert to Map with unique key based on timestamp + text + senderId + receiverId + docId for better deduplication
    final messageMap = <String, Map<String, dynamic>>{};
    
    for (final doc in messageDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int? ?? 0;
      final text = data['text'] as String? ?? '';
      final senderId = data['senderId'] as String? ?? '';
      final receiverId = data['receiverId'] as String? ?? '';
      
      // Create a more specific unique key including receiverId and document ID
      final uniqueKey = '${timestamp}_${text}_${senderId}_${receiverId}_${doc.id}';
      messageMap[uniqueKey] = data;
      
      print('Added message: $text from ${data['senderName']} (senderId: $senderId, receiverId: $receiverId, docId: ${doc.id})');
    }
    
    setState(() {
      // Convert back to list and sort by timestamp
      _messages = messageMap.values.toList()
        ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int))
        ..take(50); // Limit to 50 messages
      
      print('Final messages list length: ${_messages.length}');
      
      // Print all messages in the list
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        print('Message $i: "${msg['text']}" from ${msg['senderName']} (${msg['senderId']}) to ${msg['receiverId']} at ${msg['timestamp']}');
      }
    });
    
    print('Messages updated. Total messages: ${_messages.length}');
    
    // Auto-scroll to bottom for new messages
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadMessages() async {
    // Load existing messages between user and agency from both directions
    try {
      print('Loading messages for agency chat...');
      print('Current user ID: ${widget.currentUserId}');
      print('Agency ID: ${widget.agencyId}');
      
      // Try to load from both possible chat document directions
      final userChatId = '${widget.currentUserId}_${widget.agencyId}';
      final agencyChatId = '${widget.agencyId}_${widget.currentUserId}';
      
      print('Checking user chat ID: $userChatId');
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('agencyChat')
          .doc(widget.agencyId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      print('Checking agency chat ID: $agencyChatId');
      QuerySnapshot agencySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agencyId)
          .collection('agencyChat')
          .doc(widget.currentUserId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      // Combine messages from both directions
      List<Map<String, dynamic>> allMessages = [];
      
      allMessages.addAll(userSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
      allMessages.addAll(agencySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
      
      // Remove duplicates and sort by timestamp
      allMessages.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      // Remove duplicates based on timestamp and text
      final uniqueMessages = <Map<String, dynamic>>[];
      final seen = <String>{};
      
      for (final message in allMessages) {
        final key = '${message['timestamp']}_${message['text']}';
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueMessages.add(message);
        }
      }

      print('Total messages loaded: ${uniqueMessages.length}');
      
      setState(() {
        _messages = uniqueMessages;
      });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isLoading) return;

    setState(() {
      isLoading = true;
    });

    final message = {
      'text': _messageController.text.trim(),
      'senderId': widget.currentUserId,
      'senderName': 'User', // Current user is sending
      'senderType': 'user',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'receiverId': widget.agencyId,
    };

    print('Current user sending message: ${widget.currentUserId}');
    print('Agency ID: ${widget.agencyId}');
    print('Message: $message');

    try {
      // Create agency chat document in user's collection
      final userAgencyChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('agencyChat')
          .doc(widget.agencyId);
      
      // Create agency chat document in agency's collection
      final agencyChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agencyId)
          .collection('agencyChat')
          .doc(widget.currentUserId);
      
      print('Sending message to agency chat collections:');
      print('User agency chat: users/${widget.currentUserId}/agencyChat/${widget.agencyId}');
      print('Agency chat: users/${widget.agencyId}/agencyChat/${widget.currentUserId}');
      print('Message: $message');
      
      // Save message to user's agency chat collection
      await userAgencyChatRef
          .collection('messages')
          .add(message);

      // Save message to agency's agency chat collection
      await agencyChatRef
          .collection('messages')
          .add(message);

      // Update user's agency chat metadata
      await userAgencyChatRef.set({
        'agencyId': widget.agencyId,
        'agencyName': widget.agencyName,
        'lastMessage': message['text'],
        'lastMessageTime': message['timestamp'],
        'lastMessageSender': widget.currentUserId,
        'senderName': 'User',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update agency's agency chat metadata
      await agencyChatRef.set({
        'userId': widget.currentUserId,
        'userName': 'User',
        'lastMessage': message['text'],
        'lastMessageTime': message['timestamp'],
        'lastMessageSender': widget.currentUserId,
        'senderName': 'User',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // IMPORTANT: Update all other users who are chatting with this agency
      await _updateOtherUsersChatMetadata(message);

      setState(() {
        // Don't add message locally - let the stream handle it
        _messageController.clear();
        isLoading = false;
      });

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
      print('Message sent successfully to both chat documents');
      
      // Send notification to agency
      try {
        // Get current user data for notification
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .get();
        final currentUserData = currentUserDoc.data();
        final currentUserName = currentUserData?['name'] ?? 
                                currentUserData?['userName'] ?? 
                                currentUserData?['fullName'] ?? 
                                'User';

        // Send chat message notification to agency
        await NotificationService().sendChatMessageNotification(
          fromUserId: widget.currentUserId,
          fromUserName: currentUserName,
          toUserId: widget.agencyId,
          toUserName: widget.agencyName,
          messageText: message['text']?.toString() ?? '',
        );
        print('Agency chat notification sent');
      } catch (e) {
        print('Error sending agency chat notification: $e');
      }
      
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateOtherUsersChatMetadata(Map<String, dynamic> message) async {
    try {
      print('Updating other users chat metadata for agency: ${widget.agencyId}');
      
      // Get all users who have chats with this agency
      final agencyChatsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agencyId)
          .collection('agencyChat')
          .get();

      print('Found ${agencyChatsSnapshot.docs.length} users chatting with this agency');

      for (final chatDoc in agencyChatsSnapshot.docs) {
        final otherUserId = chatDoc.id;
        
        // Skip current user and agency themselves
        if (otherUserId != widget.currentUserId && otherUserId != widget.agencyId) {
          print('Updating chat metadata for user: $otherUserId');
          
          // Update the other user's agency chat metadata
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .collection('agencyChat')
              .doc(widget.agencyId)
              .set({
                'agencyId': widget.agencyId,
                'agencyName': widget.agencyName,
                'lastMessage': message['text'],
                'lastMessageTime': message['timestamp'],
                'lastMessageSender': widget.currentUserId,
                'senderName': 'User',
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
      
      print('Updated chat metadata for all relevant users');
    } catch (e) {
      print('Error updating other users chat metadata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.agencyId).snapshots(),
          builder: (context, snapshot) {
            bool isOnline = true;
            String agencyPlan = '';
            String currentUserPlan = '';
            
            if (snapshot.hasData) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              isOnline = data?['onlineStatus'] ?? true;
              agencyPlan = data?['plan'] ?? '';
            }
            
            // Get current user's plan
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  currentUserPlan = userData?['plan'] ?? '';
                }
                
                return Row(
              children: [
                if (widget.agencyLogo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: widget.agencyLogo!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.business, color: Colors.white54, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agencyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // Only show online status for pro users
                          if (currentUserPlan.toLowerCase() == 'pro') ...[
                            Icon(
                              isOnline ? Icons.circle : Icons.circle_outlined,
                              color: isOnline ? Colors.green : Colors.grey,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            // Free members don't see online status
                            const SizedBox(width: 20),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
              },
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white54,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation with ${widget.agencyName}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Send a message to begin discussing your project',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final senderId = message['senderId'] as String? ?? '';
                        final senderType = message['senderType'] as String? ?? '';
                        final isMe = senderId == widget.currentUserId || senderType == 'user';
                        
                        print('Displaying message: "${message['text']}" from ${message['senderName']} (senderId: $senderId, senderType: $senderType, currentUserId: ${widget.currentUserId}, isMe: $isMe)');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                FutureBuilder<String?>(
                                  future: _getUserProfileImage(senderId),
                                  builder: (context, snapshot) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: snapshot.data!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Icon(Icons.business, color: Colors.white, size: 16),
                                              ),
                                            )
                                          : Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Icon(Icons.business, color: Colors.white, size: 16),
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    // Show sender name for agency messages
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message['senderName'] ?? 'Agency',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMe ? const Color(0xFF007AFF) : const Color(0xFF2C2C2C),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        message['text'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: _userProfileImage != null && _userProfileImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _userProfileImage!,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(Icons.person, color: Colors.white, size: 16),
                                          ),
                                        )
                                      : Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(Icons.person, color: Colors.white, size: 16),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Message Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2C),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: isLoading ? null : _sendMessage,
                    ),
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
