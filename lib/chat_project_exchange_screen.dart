import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_screen.dart';
import '../services/notification_service.dart';
import 'dart:async';

// --- Dotted Background Widget (reuse from dashboard/onboarding) ---
class _DottedBackground extends StatelessWidget {
  final double offset;
  const _DottedBackground({required this.offset});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _DottedPainter(offset: offset),
    );
  }
}

class _DottedPainter extends CustomPainter {
  final double offset;
  _DottedPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const double spacing = 32;
    const double radius = 2.2;
    final double move = offset * spacing * 2;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dx = x + ((y ~/ spacing) % 2 == 0 ? 0 : spacing / 2) + move;
        final dy = y + move * 0.5;
        final wrappedDx = dx % size.width;
        final wrappedDy = dy % size.height;
        canvas.drawCircle(Offset(wrappedDx, wrappedDy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPainter oldDelegate) => oldDelegate.offset != offset;
}

// Simple emoji list for demo
const List<String> _emojis = [
  '😀','😂','😍','😎','👍','🙏','🎉','🔥','🥳','😢','😡','🤔','🙌','👏','💯','🥰','😇','😜','🤩','😅','😆','😏','😋','😱','😴','🤗','😬','😳','😇','😃','😄','😁','😆','😅','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🥸','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🤭','🤫','🤥','😶','😐','😑','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕','🤑','🤠','😈','👿','👹','👺','🤡','💩','👻','💀','☠️','👽','👾','🤖','🎃','😺','😸','😹','😻','😼','😽','🙀','😿','😾'
];

class ChatProjectExchangeScreen extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;
  final String? otherUserName;
  final String? userPlan;
  const ChatProjectExchangeScreen({
    required this.currentUserId, 
    required this.profileUserId, 
    this.otherUserName,
    this.userPlan,
    super.key
  });

  @override
  State<ChatProjectExchangeScreen> createState() => _ChatProjectExchangeScreenState();
}

class _ChatProjectExchangeScreenState extends State<ChatProjectExchangeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bgAnimationController;
  bool _showEmojiPicker = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSendingMessage = false; // Prevent duplicate sends
  String _currentUserPlan = 'Free';
  int _sentExchangeCount = 0;
  bool _loadingExchangeCount = true;
  List<DocumentSnapshot> _allMessages = [];
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _markMessagesAsSeen();
    if (widget.userPlan != null) {
      setState(() {
        _currentUserPlan = widget.userPlan!;
      });
    } else {
      _fetchCurrentUserPlan();
    }
    _fetchSentExchangeCount();
    // Store FCM token for push notifications
    _storeFCMToken();
    // Setup real-time message listening
    _setupMessageListener();
  }

  Future<void> _storeFCMToken() async {
    try {
      print('🔥 === STORING FCM TOKEN FOR SENDER ===');
      print('📤 SENDER USER ID: ${widget.currentUserId}');
      await NotificationService().storeUserToken(widget.currentUserId);
      print('✅ FCM token stored for chat user');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // REMOVED: _storeReceiverFCMToken was causing token conflicts
  // Each user should have their own FCM token on their own device
  // Future<void> _storeReceiverFCMToken() async {
  //   try {
  //     print('🔥 === STORING FCM TOKEN FOR RECEIVER ===');
  //     print('📥 RECEIVER USER ID: ${widget.profileUserId}');
  //     await NotificationService().storeUserToken(widget.profileUserId);
  //     print('✅ FCM token stored for receiver user');
  //   } catch (e) {
  //     print('❌ Error storing receiver FCM token: $e');
  //     print('❌ Stack trace: ${StackTrace.current}');
  //   }
  // }

  Future<void> _fetchCurrentUserPlan() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
    setState(() {
      _currentUserPlan = (userDoc.data()?['plan'] ?? 'Free').toString();
    });
  }

  void _setupMessageListener() {
    // Listen to both user's message streams for complete real-time updates
    _messagesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('chats')
        .doc(widget.profileUserId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allMessages = snapshot.docs;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    // Auto-scroll to latest message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _markMessagesAsSeen() async {
    // Temporarily disabled to fix index issues
    // This will be re-enabled once proper indexes are created
    print('🔍 Marking messages as seen (temporarily disabled for index fix)');
  }

  Future<void> _fetchSentExchangeCount() async {
    // Count total sent requests for free plan limit
    final sentRequests = await FirebaseFirestore.instance
        .collection('exchanges')
        .where('fromUserId', isEqualTo: widget.currentUserId)
        .get();
    final activeRequests = sentRequests.docs.where((doc) {
      final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
      return status != 'cancelled' && status != 'deleted';
    }).toList();
    setState(() {
      _sentExchangeCount = activeRequests.length;
      _loadingExchangeCount = false;
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    if (_isSendingMessage) return;
    setState(() { _isSendingMessage = true; });
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final messageData = {
        'text': text,
        'senderId': widget.currentUserId,
        'receiverId': widget.profileUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      };
      try {
        print('Sending message: $messageData');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .collection('chats')
            .doc(widget.profileUserId)
            .set({
              'userId': widget.profileUserId,
              'lastMessage': text,
              'lastTimestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        print('Sender chat doc created/updated');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .collection('chats')
            .doc(widget.profileUserId)
            .collection('messages')
            .add(messageData);
        print('Message added to sender chat');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.profileUserId)
            .collection('chats')
            .doc(widget.currentUserId)
            .set({
              'userId': widget.currentUserId,
              'lastMessage': text,
              'lastTimestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        print('Receiver chat doc created/updated');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.profileUserId)
            .collection('chats')
            .doc(widget.currentUserId)
            .collection('messages')
            .add(messageData);
        print('Message added to receiver chat');

        // Scroll to bottom after sending message
        _scrollToBottom();

        // Send offline notification to receiver
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
                                  'Unknown User';

          // Check if receiver has FCM token
          final receiverDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.profileUserId)
              .get();
          final receiverData = receiverDoc.data();
          final receiverFcmToken = receiverData?['fcmToken'];
          final receiverTokenUserId = receiverData?['tokenUserId'];
          final receiverDeviceActive = receiverData?['deviceActive'] ?? false;
          
          print('=== DEBUGGING PRIVATE CHAT NOTIFICATION ===');
          print('From User ID: ${widget.currentUserId}');
          print('From User Name: $currentUserName');
          print('To User ID: ${widget.profileUserId}');
          print('To User Name: ${widget.otherUserName ?? 'Unknown User'}');
          print('Message: $text');
          print('Receiver FCM Token: ${receiverFcmToken?.substring(0, 10) ?? 'NULL'}...');
          print('Receiver Token User ID: $receiverTokenUserId');
          print('Receiver Device Active: $receiverDeviceActive');
          print('Receiver Doc Exists: ${receiverDoc.exists}');
          print('==========================================');

          // Send chat message notification
          print('🔥 === SENDING EXCHANGE CHAT NOTIFICATION ===');
          print('📤 FROM: ${widget.currentUserId} ($currentUserName)');
          print('📥 TO: ${widget.profileUserId} (${widget.otherUserName ?? 'Unknown User'})');
          print('📝 MESSAGE: $text');
          
          await NotificationService().sendChatMessageNotification(
            fromUserId: widget.currentUserId,
            fromUserName: currentUserName,
            toUserId: widget.profileUserId,
            toUserName: widget.otherUserName ?? 'Unknown User',
            messageText: text,
          );
          
          print('✅ EXCHANGE CHAT NOTIFICATION SENT');
          print('🔥 === EXCHANGE CHAT NOTIFICATION END ===');
          print('✅ Chat message notification sent successfully');
        } catch (e) {
          print('❌ Error sending chat message notification: $e');
        }

        _controller.clear();
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      } finally {
        setState(() { _isSendingMessage = false; });
      }
    } else {
      setState(() { _isSendingMessage = false; });
    }
  }

  Stream<QuerySnapshot> get _chatStream {
    // This is no longer needed - using _setupMessageListener instead
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('chats')
        .doc(widget.profileUserId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.profileUserId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final profileUserName = data?['fullName'] ?? data?['name'] ?? 'User';
            final profileUserImageUrl = data?['profileImageUrl'];
            final profileUserPlan = data?['plan'];
            final profileUserOnlineStatus = data?['onlineStatus'] ?? true;
            final screenWidth = MediaQuery.of(context).size.width;
            final isWide = screenWidth > 500;
            return Row(
              children: [
                CircleAvatar(
                  radius: isWide ? 30 : 24,
                  backgroundColor: Colors.white24,
                  backgroundImage: (profileUserImageUrl != null && profileUserImageUrl.isNotEmpty)
                      ? NetworkImage(profileUserImageUrl)
                      : null,
                  child: (profileUserImageUrl == null || profileUserImageUrl.isEmpty)
                      ? Icon(Icons.person, color: Colors.white, size: isWide ? 30 : 24)
                      : null,
                ),
                SizedBox(width: isWide ? 18 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profileUserName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 22 : 17,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      Row(
                        children: [
                          if (profileUserPlan != null && profileUserPlan.toLowerCase() == 'pro') ...[
                            Icon(
                              profileUserOnlineStatus ? Icons.circle : Icons.circle_outlined,
                              color: profileUserOnlineStatus ? Colors.green : Colors.grey,
                              size: isWide ? 14 : 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profileUserOnlineStatus ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: profileUserOnlineStatus ? Colors.green : Colors.grey,
                                fontSize: isWide ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (profileUserPlan == null || profileUserPlan.toLowerCase() != 'pro') ...[
                            // Free members don't see online status
                            SizedBox(width: isWide ? 20 : 16),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isWide ? 18 : 10), // Add space before button
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: _currentUserPlan.toLowerCase() == 'free' && _sentExchangeCount >= 5 
                  ? 'Free plan limit reached. Upgrade to Pro for unlimited requests.'
                  : 'Start an exchange project',
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _currentUserPlan.toLowerCase() == 'free' && _sentExchangeCount >= 5 
                      ? Colors.grey 
                      : Colors.blueGrey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.swap_horiz, size: 22, color: Colors.white),
              label: const Text('Start Exchange', style: TextStyle(fontSize: 15, color: Colors.white)),
                onPressed: _loadingExchangeCount
                    ? null
                    : () async {
                      print('=== BUTTON CLICKED ===');
                      print('Current user plan: $_currentUserPlan');
                      print('Sent exchange count: $_sentExchangeCount');
                      print('Loading exchange count: $_loadingExchangeCount');
                      
                      // Check if free user has reached limit - MAIN CHECK
                      if (_currentUserPlan.toLowerCase() == 'free' && _sentExchangeCount >= 5) {
                        print('=== LIMIT REACHED - SHOWING PRO DIALOG ===');
                        print('User plan: $_currentUserPlan');
                        print('Sent count: $_sentExchangeCount');
                        
                        if (context.mounted) {
                          print('=== CONTEXT MOUNTED, TRYING SHOWDIALOG ===');
                          
                          // Try with a small delay to ensure UI is ready
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              print('=== DELAYED DIALOG ATTEMPT ===');
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx2) {
                                  print('=== DIALOG BUILDER CALLED ===');
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFF232323),
                                    title: const Text('Pro Plan Required', style: TextStyle(color: Colors.white)),
                                    content: const Text('You have reached the free request limit (5) total. Upgrade to Pro plan for unlimited requests.', style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          print('=== MAYBE LATER PRESSED ===');
                                          Navigator.of(ctx2).pop();
                                        },
                                        child: const Text('Maybe Later', style: TextStyle(color: Colors.white70)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          print('=== UPGRADE PRESSED ===');
                                          Navigator.of(ctx2).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => SubscriptionScreen(userId: widget.currentUserId)),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                        child: const Text('Upgrade to Pro', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  );
                                },
                              ).then((_) {
                                print('=== DIALOG CLOSED ===');
                              }).catchError((error) {
                                print('=== DIALOG ERROR: $error ===');
                              });
                            } else {
                              print('=== CONTEXT NOT MOUNTED AFTER DELAY ===');
                            }
                          });
                        } else {
                          print('=== CONTEXT NOT MOUNTED ===');
                        }
                        print('=== RETURNING AFTER PRO DIALOG ===');
                        return;
                      }
                      
                      
                      print('Start Exchange button pressed');
                      Map<String, dynamic>? existingExchange;
                      String? exchangeId;
                      try {
                        print('Querying existing exchanges...');
                        final exchangeQuery = await FirebaseFirestore.instance
                            .collection('exchanges')
                            .where('fromUserId', isEqualTo: widget.currentUserId)
                            .where('toUserId', isEqualTo: widget.profileUserId)
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .get();
                        if (exchangeQuery.docs.isNotEmpty) {
                          existingExchange = exchangeQuery.docs.first.data();
                          exchangeId = exchangeQuery.docs.first.id;
                        }
                        print('Firestore query success - found ${exchangeQuery.docs.length} exchanges');
                      } catch (e) {
                        print('Firestore query failed: $e');
                        // Try without ordering as fallback
                        try {
                          print('Trying fallback query without ordering...');
                          final fallbackQuery = await FirebaseFirestore.instance
                              .collection('exchanges')
                              .where('fromUserId', isEqualTo: widget.currentUserId)
                              .where('toUserId', isEqualTo: widget.profileUserId)
                              .limit(1)
                              .get();
                          if (fallbackQuery.docs.isNotEmpty) {
                            existingExchange = fallbackQuery.docs.first.data();
                            exchangeId = fallbackQuery.docs.first.id;
                          }
                          print('Fallback query success');
                        } catch (fallbackError) {
                          print('Fallback query also failed: $fallbackError');
                          // Continue without existing exchange check
                        }
                      }
                      try {
                        print('Trying to show dialog');
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final titleController = TextEditingController();
                            final typeController = TextEditingController();
                            final descController = TextEditingController();
                            final linkController = TextEditingController();
                            final noteController = TextEditingController();
                            String selectedLinkType = 'Google Drive';
                            return StatefulBuilder(
                              builder: (context, setState) {
                                bool showProjectLinkFields = false;
                                if (existingExchange != null) {
                                  final status = existingExchange['status'] ?? 'pending';
                                  final otherUserLink = existingExchange['otherUserProjectLink'] ?? '';
                                  if (status == 'accepted' && otherUserLink.isNotEmpty) {
                                    showProjectLinkFields = true;
                                  }
                                }
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF232323),
                                  title: const Text('Start Exchange', style: TextStyle(color: Colors.white)),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: titleController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Project Title',
                                            labelStyle: TextStyle(color: Colors.white70),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: typeController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Project Type',
                                            hintText: 'e.g. Flutter, Web, SEO, Design',
                                            hintStyle: TextStyle(color: Colors.white38),
                                            labelStyle: TextStyle(color: Colors.white70),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: descController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Project Description',
                                            hintText: 'Describe your project',
                                            hintStyle: TextStyle(color: Colors.white38),
                                            labelStyle: TextStyle(color: Colors.white70),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                          ),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 14),
                                        if (showProjectLinkFields) ...[
                                          DropdownButtonFormField<String>(
                                            initialValue: selectedLinkType,
                                            dropdownColor: const Color(0xFF232323),
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: 'Project Link Type',
                                              labelStyle: TextStyle(color: Colors.white70),
                                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                            ),
                                            items: ['Google Drive', 'Github']
                                                .map((type) => DropdownMenuItem(
                                                      value: type,
                                                      child: Text(type),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  selectedLinkType = val;
                                                });
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: linkController,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: selectedLinkType == 'Google Drive'
                                                  ? 'Google Drive Project Link'
                                                  : 'Github Project Link',
                                              hintText: selectedLinkType == 'Google Drive'
                                                  ? 'Please drop your Google Drive project link'
                                                  : 'Please drop your Github project link',
                                              hintStyle: const TextStyle(color: Colors.white38),
                                              labelStyle: const TextStyle(color: Colors.white70),
                                              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: _startDate ?? DateTime.now(),
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2100),
                                                    builder: (context, child) => Theme(
                                                      data: ThemeData.dark().copyWith(
                                                        colorScheme: const ColorScheme.dark(
                                                          primary: Colors.blueAccent,
                                                          onPrimary: Colors.white,
                                                          surface: Color(0xFF232323),
                                                          onSurface: Colors.white,
                                                        ), dialogTheme: DialogThemeData(backgroundColor: Color(0xFF232323)),
                                                      ),
                                                      child: child!,
                                                    ),
                                                  );
                                                  if (picked != null) {
                                                    setState(() {
                                                      _startDate = picked;
                                                    });
                                                  }
                                                },
                                                child: AbsorbPointer(
                                                  child: TextFormField(
                                                    style: const TextStyle(color: Colors.white),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Start Project Date',
                                                      labelStyle: TextStyle(color: Colors.white70),
                                                      hintText: 'Select start date',
                                                      hintStyle: TextStyle(color: Colors.white38),
                                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                                    ),
                                                    controller: TextEditingController(
                                                      text: _startDate == null ? '' : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                                                    firstDate: _startDate ?? DateTime(2020),
                                                    lastDate: DateTime(2100),
                                                    builder: (context, child) => Theme(
                                                      data: ThemeData.dark().copyWith(
                                                        colorScheme: const ColorScheme.dark(
                                                          primary: Colors.blueAccent,
                                                          onPrimary: Colors.white,
                                                          surface: Color(0xFF232323),
                                                          onSurface: Colors.white,
                                                        ), dialogTheme: DialogThemeData(backgroundColor: Color(0xFF232323)),
                                                      ),
                                                      child: child!,
                                                    ),
                                                  );
                                                  if (picked != null) {
                                                    setState(() {
                                                      _endDate = picked;
                                                    });
                                                  }
                                                },
                                                child: AbsorbPointer(
                                                  child: TextFormField(
                                                    style: const TextStyle(color: Colors.white),
                                                    decoration: const InputDecoration(
                                                      labelText: 'End Project Date',
                                                      labelStyle: TextStyle(color: Colors.white70),
                                                      hintText: 'Select end date',
                                                      hintStyle: TextStyle(color: Colors.white38),
                                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                                    ),
                                                    controller: TextEditingController(
                                                      text: _endDate == null ? '' : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: noteController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Exchange Note',
                                            labelStyle: TextStyle(color: Colors.white70),
                                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final title = titleController.text.trim();
                                                final desc = descController.text.trim();
                                                final startDate = _startDate?.toIso8601String();
                                                final endDate = _endDate?.toIso8601String();
                                                final note = noteController.text.trim();
                                                if (title.isEmpty || desc.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please fill all required fields!')),
                                                  );
                                                  return;
                                                }
                                                // Check if user can send exchange request
                                                if (_currentUserPlan.toLowerCase() != 'pro') {
                                                  final sentRequests = await FirebaseFirestore.instance
                                                      .collection('exchanges')
                                                      .where('fromUserId', isEqualTo: widget.currentUserId)
                                                      .get();
                                                  // Only count active requests for free plan limit
                                                  final activeSentRequests = sentRequests.docs.where((doc) {
                                                    final status = (doc.data()['status'] ?? 'pending').toString().toLowerCase();
                                                    return status != 'cancelled' && status != 'deleted';
                                                  }).toList();
                                                  if (activeSentRequests.length >= 5) {
                                                    Navigator.of(ctx).pop();
                                                    showDialog(
                                                      context: context,
                                                      builder: (ctx2) => AlertDialog(
                                                        backgroundColor: const Color(0xFF232323),
                                                        title: const Text('Pro Plan Required', style: TextStyle(color: Colors.white)),
                                                        content: const Text('You have reached the free request limit (5) total. Upgrade to Pro plan for unlimited requests.', style: TextStyle(color: Colors.white70)),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(ctx2).pop(),
                                                            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                }
                                                
                                                // Create and send exchange request
                                                final exchangeData = {
                                                    'title': title,
                                                    'type': typeController.text.trim(),
                                                    'description': desc,
                                                    'status': 'pending',
                                                    'startDate': startDate,
                                                    'endDate': endDate,
                                                    'note': note,
                                                    'fromUserId': widget.currentUserId,
                                                    'toUserId': widget.profileUserId,
                                                    'timestamp': FieldValue.serverTimestamp(),
                                                  };

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
                                                                          'Unknown User';

                                                  // Save to main exchanges collection
                                                  final exchangeDocRef = await FirebaseFirestore.instance
                                                      .collection('exchanges')
                                                      .add(exchangeData);

                                                  // Save to sender's requests subcollection (unique doc ID)
                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(widget.currentUserId)
                                                      .collection('requests')
                                                      .doc(exchangeDocRef.id)
                                                      .set({
                                                    ...exchangeData,
                                                    'exchangeId': exchangeDocRef.id,
                                                    'isOutgoing': true, // This user sent the request
                                                  });
                                                  print('Sender request created: ${exchangeDocRef.id}');

                                                  // Save to receiver's requests subcollection (unique doc ID)
                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(widget.profileUserId)
                                                      .collection('requests')
                                                      .doc(exchangeDocRef.id)
                                                      .set({
                                                    ...exchangeData,
                                                    'exchangeId': exchangeDocRef.id,
                                                    'isOutgoing': false, // This user received the request
                                                  });
                                                  print('Receiver request created: ${exchangeDocRef.id}');

                                                  // Send offline notification to receiver
                                                  print('Sending offline notification from chat...');
                                                  await NotificationService().sendExchangeRequestNotification(
                                                    fromUserId: widget.currentUserId,
                                                    fromUserName: currentUserName,
                                                    toUserId: widget.profileUserId,
                                                    toUserName: widget.otherUserName ?? 'Unknown User',
                                                    projectTitle: title,
                                                    requestId: exchangeDocRef.id,
                                                  );
                                                  print('Offline notification sent from chat');

                                                  Navigator.of(ctx).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Exchange request sent!')),
                                                  );
                                                } catch (e) {
                                                  Navigator.of(ctx).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Failed to send exchange request: ${e.toString()}')),
                                                  );
                                                }
                                              },
                                              child: const Text('Send Request'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                        print('Dialog should be visible');
                      } catch (e) {
                        print('Dialog failed: $e');
                        showDialog(
                          context: context,
                          builder: (ctx) => const AlertDialog(
                            title: Text('Error'),
                            content: Text('Something went wrong. Please try again.'),
                          ),
                        );
                      }
                    },
              ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return _DottedBackground(offset: _bgAnimationController.value);
              },
            ),
            Column(
              children: [
                Expanded(
                  child: _allMessages.isEmpty 
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        itemCount: _allMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _allMessages[index].data() as Map<String, dynamic>;
                          final isMe = msg['senderId'] == widget.currentUserId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF005C4B) : const Color(0xFF222B32),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['text'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        msg['timestamp'] != null && msg['timestamp'] is Timestamp
                                            ? (msg['timestamp'] as Timestamp).toDate().toLocal().toString().substring(11, 16)
                                            : '',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        (msg['seen'] ?? false) == true ? Icons.done_all : Icons.check,
                                        size: 16,
                                        color: (msg['seen'] ?? false) == true ? Colors.blueAccent : Colors.white38,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
                if (_showEmojiPicker)
                  Container(
                    height: 220,
                    color: const Color(0xFF232323),
                    child: GridView.count(
                      crossAxisCount: 8,
                      children: _emojis.map((emoji) => InkWell(
                        onTap: () {
                          _controller.text += emoji;
                          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                        },
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                      )).toList(),
                    ),
                  ),
                Container(
                  color: const Color(0xFF232323),
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 8,
                    bottom: 8,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions, color: Colors.orangeAccent),
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              maxLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D2D2D),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.greenAccent),
                            onPressed: _isSendingMessage ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}