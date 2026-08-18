import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_project_exchange_screen.dart'; // For private chat navigation
import 'services/notification_service.dart';
import 'widgets/chat_ad_banner.dart';

class GroupChatScreen extends StatefulWidget {
  final String userId;
  final String? department;
  const GroupChatScreen({super.key, required this.userId, this.department});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

const List<String> _emojis = [
  '😀','😂','😍','😎','👍','🙏','🎉','🔥','🥳','😢','😡','🤔','🙌','👏','💯','🥰','😇','😜','🤩','😅','😆','😏','😋','😱','😴','🤗','😬','😳','😃','😄','😁','😆','😅','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🥸','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🤭','🤫','🤥','😶','😐','😑','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕','🤑','🤠','😈','👿','👹','👺','🤡','💩','👻','💀','☠️','👽','👾','🤖','🎃','😺','😸','😹','😻','😼','😽','🙀','😿','😾'
];

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  bool _showEmojiPicker = false;
  final Map<String, Map<String, String>> _userInfoCache = {};
  Set<String> _activeUserIds = {};
  final Map<String, Map<String, String>> _activeUserInfo = {};

  @override
  void initState() {
    super.initState();
    _storeFCMToken();
  }

  Future<void> _storeFCMToken() async {
    try {
      await NotificationService().storeUserToken(widget.userId);
      print('✅ FCM token stored for group chat user');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  Future<Map<String, String>> _getUserInfo(String userId) async {
    if (_userInfoCache.containsKey(userId)) {
      return _userInfoCache[userId]!;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get(const GetOptions(source: Source.server));
    final data = doc.data() ?? {};
    final info = <String, String>{
      'name': (data['fullName'] ?? data['name'] ?? 'User').toString(),
      'jobTitle': (data['jobTitle'] ?? '').toString(),
      'profileImageUrl': (data['profileImageUrl'] ?? '').toString(),
    };
    _userInfoCache[userId] = info;
    return info;
  }

  Stream<QuerySnapshot> get _messagesStream => FirebaseFirestore.instance
      .collection('group_chats')
      .doc(widget.department ?? 'general')
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(widget.department ?? 'general')
          .collection('messages')
          .add({
        'text': text,
        'senderId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();

      // Send notifications to all active users except sender
      await _sendGroupChatNotifications(text);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendGroupChatNotifications(String messageText) async {
    try {
      // Get current user info for notification
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['fullName'] ?? 
                              currentUserData?['name'] ?? 
                              currentUserData?['userName'] ?? 
                              'Unknown User';

      // Send notification to each active user except the sender
      for (final userId in _activeUserIds) {
        if (userId != widget.userId) {
          try {
            await NotificationService().sendChatMessageNotification(
              fromUserId: widget.userId,
              fromUserName: currentUserName,
              toUserId: userId,
              toUserName: 'Group Chat User',
              messageText: messageText,
            );
            print('Group chat notification sent to user: $userId');
          } catch (e) {
            print('Error sending group chat notification to $userId: $e');
          }
        }
      }
    } catch (e) {
      print('Error in _sendGroupChatNotifications: $e');
    }
  }

  void _showActiveUsersSheet(BuildContext context) async {
    // Fetch user info for all active users
    List<Widget> userTiles = [];
    for (final userId in _activeUserIds) {
      final info = await _getUserInfo(userId);
      userTiles.add(ListTile(
        leading: info['profileImageUrl'] != null && info['profileImageUrl']!.isNotEmpty
            ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(info['profileImageUrl']!))
            : const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
        title: Text(
          '${info['name'] ?? 'User'} (Private Chat)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: info['jobTitle'] != null && info['jobTitle']!.isNotEmpty
            ? Text(
                info['jobTitle']!,
                style: const TextStyle(color: Colors.white70),
              )
            : null,
        onTap: userId == widget.userId ? null : () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatProjectExchangeScreen(
                currentUserId: widget.userId,
                profileUserId: userId,
              ),
            ),
          );
        },
      ));
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF232323),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, left: 16, right: 16, bottom: 2),
              child: Text('Active Users in Group Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0, left: 16, right: 16),
              child: Text('Tap a user below to start a private chat.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
            ...userTiles,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final isLarge = screenWidth > 700;
    final bubbleMaxWidth = isLarge ? screenWidth * 0.5 : isSmall ? screenWidth * 0.88 : screenWidth * 0.7;
    final avatarRadius = isLarge ? 26.0 : isSmall ? 14.0 : 18.0;
    final nameFont = isLarge ? 20.0 : isSmall ? 13.0 : 15.0;
    final jobFont = isLarge ? 15.0 : isSmall ? 10.0 : 12.0;
    final textFont = isLarge ? 20.0 : isSmall ? 13.0 : 16.0;
    final timeFont = isLarge ? 14.0 : isSmall ? 9.0 : 11.0;
    final bubblePaddingV = isLarge ? 16.0 : isSmall ? 7.0 : 10.0;
    final bubblePaddingH = isLarge ? 22.0 : isSmall ? 8.0 : 14.0;
    final rowGap = isLarge ? 16.0 : isSmall ? 6.0 : 10.0;
    final bubbleMarginV = isLarge ? 24.0 : isSmall ? 8.0 : 16.0;
    final inputPadding = isLarge ? 18.0 : isSmall ? 8.0 : 12.0;
    final emojiGridCount = isLarge ? 10 : isSmall ? 6 : 8;
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        title: Text('Group Discussion', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            color: isDarkMode ? Colors.white : Colors.black, // icon color
            tooltip: 'Show Active Users',
            onPressed: () => _showActiveUsersSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  final docs = snapshot.data!.docs;
                  // Collect unique senderIds for active users
                  _activeUserIds = docs.map((d) => (d.data() as Map<String, dynamic>)['senderId'] as String).toSet();
                  return ListView.builder(
                    padding: EdgeInsets.only(
                      left: inputPadding,
                      right: inputPadding,
                      top: bubbleMarginV,
                      bottom: bubbleMarginV / 2,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final msg = docs[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == widget.userId;
                      return FutureBuilder<Map<String, String>>(
                        future: _getUserInfo(msg['senderId'] ?? ''),
                        builder: (context, snapshot) {
                          final userName = snapshot.data?['name'] ?? 'User';
                          final jobTitle = snapshot.data?['jobTitle'] ?? '';
                          final profileImageUrl = snapshot.data?['profileImageUrl'] ?? '';
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: bubbleMarginV / 2),
                              padding: EdgeInsets.symmetric(vertical: bubblePaddingV, horizontal: bubblePaddingH),
                              constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      profileImageUrl.isNotEmpty
                                          ? CircleAvatar(
                                              radius: avatarRadius,
                                              backgroundImage: NetworkImage(profileImageUrl),
                                              backgroundColor: Colors.white24,
                                            )
                                          : CircleAvatar(
                                              radius: avatarRadius,
                                              backgroundColor: Colors.white24,
                                              child: Icon(Icons.person, color: Colors.white, size: avatarRadius+4),
                                            ),
                                      SizedBox(width: rowGap),
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: isMe ? null : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatProjectExchangeScreen(
                                                  currentUserId: widget.userId,
                                                  profileUserId: msg['senderId'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: TextStyle(
                                                  color: isMe ? Colors.greenAccent : Colors.blueAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: nameFont,
                                                  decoration: isMe ? null : TextDecoration.underline,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (jobTitle.isNotEmpty)
                                                Text(
                                                  jobTitle,
                                                  style: TextStyle(color: Colors.white70, fontSize: jobFont),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: rowGap),
                                  Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(color: Colors.white, fontSize: textFont),
                                    softWrap: true,
                                    maxLines: null,
                                  ),
                                  SizedBox(height: isSmall ? 1 : 2),
                                  Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['timestamp'] != null && msg['timestamp'] is Timestamp
                                            ? (msg['timestamp'] as Timestamp).toDate().toLocal().toString().substring(11, 16)
                                            : '',
                                        style: TextStyle(color: Colors.white38, fontSize: timeFont),
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
                },
              ),
            ),
            // AdMob ad banner above input area
            const ChatAdBanner(),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(color: Color(0xFF333333), width: 1),
                ),
              ),
              padding: EdgeInsets.only(
                left: inputPadding,
                right: inputPadding,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showEmojiPicker)
                    Container(
                      height: isLarge ? 320 : isSmall ? 180 : 250,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        border: Border(
                          top: BorderSide(color: Color(0xFF333333), width: 1),
                        ),
                      ),
                      padding: EdgeInsets.all(inputPadding),
                      child: GridView.count(
                        crossAxisCount: emojiGridCount,
                        children: _emojis.map((emoji) => InkWell(
                          onTap: () {
                            _controller.text += emoji;
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length),
                            );
                          },
                          child: Center(child: Text(emoji, style: TextStyle(fontSize: isLarge ? 28 : isSmall ? 18 : 22))),
                        )).toList(),
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions, color: Colors.orangeAccent, size: isSmall ? 20 : 24),
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: isSmall ? 8 : 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF444444),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                            maxLines: null,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: isSmall ? 14 : 16),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFF005C4B), width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 16 : 20, 
                                vertical: isSmall ? 12 : 16
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 8 : 10),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF005C4B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF005C4B),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: _isSending
                              ? SizedBox(width: isSmall ? 18 : 24, height: isSmall ? 18 : 24, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.send, color: Colors.white, size: isSmall ? 20 : 24),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}