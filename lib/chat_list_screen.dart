import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'chat_project_exchange_screen.dart';
import 'agency_chat_screen.dart';
import 'agency_chat_list_screen.dart';
import 'chat_list/bloc/chat_list_bloc.dart';
import 'chat_list/bloc/chat_list_state.dart';
import 'chat_list/bloc/chat_list_event.dart';
import 'chat_list/services/chat_firebase_service.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;
  const ChatListScreen({required this.currentUserId, Key? key})
      : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late ChatListBloc _chatListBloc;

  @override
  void initState() {
    super.initState();
    _chatListBloc = ChatListBloc();
    _chatListBloc.setUserId(widget.currentUserId);
    _chatListBloc.add(LoadChatsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatListBloc.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _filterChatsWithUserData(
      List<Map<String, dynamic>> chats) async {
    if (_searchQuery.isEmpty) return chats;

    final filteredChats = <Map<String, dynamic>>[];

    for (final chat in chats) {
      final chatDoc = chat['chatDoc'] as QueryDocumentSnapshot;
      final otherUserId = chatDoc.id;

      try {
        // Fetch user data to check name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = userData?['fullName'] ??
            userData?['name'] ??
            userData?['userName'] ??
            '';

        // Check if user name contains the search query (case insensitive)
        if (userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          filteredChats.add(chat);
        }
      } catch (e) {
        // If we can't fetch user data, include the chat
        filteredChats.add(chat);
      }
    }

    return filteredChats;
  }

  List<Map<String, dynamic>> _filterChats(List<Map<String, dynamic>> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      final chatDoc = chat['chatDoc'] as QueryDocumentSnapshot;
      final otherUserId = chatDoc.id;

      // Get user data for search filtering
      // We'll need to fetch user data to filter by name
      // For now, return all chats and let the StreamBuilder handle the filtering
      return true;
    }).toList();
  }

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  );

  void _onRetryPressed() {
    _chatListBloc.add(LoadChatsEvent());
  }

  void _switchToAgencyChat(
      String agencyId, String agencyName, String? agencyLogo) {
    _chatListBloc.add(SwitchToAgencyChatEvent(
      agencyId: agencyId,
      agencyName: agencyName,
      agencyLogo: agencyLogo,
    ));
  }

  void _switchBackToChatList() {
    _chatListBloc.add(SwitchToAgencyChatEvent(
      agencyId: null,
      agencyName: null,
      agencyLogo: null,
    ));
  }

  Future<void> _onRefreshPressed() async {
    _chatListBloc.add(RefreshChatsEvent());
  }

  String _formatTimestamp(int milliseconds) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _chatListBloc,
      child: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFF232323),
            appBar: AppBar(
              backgroundColor: const Color(0xFF232323),
              elevation: 0,
              title: Text(
                  state is ChatListLoaded && state.activeAgencyId != null
                      ? state.activeAgencyName ?? 'Agency Chat'
                      : 'Chats',
                  style: const TextStyle(color: Colors.white)),
              leading: state is ChatListLoaded && state.activeAgencyId != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _switchBackToChatList,
                    )
                  : null,
            ),
            body: Column(
              children: [
                // Search Bar - only show in chat list mode
                if (state is! ChatListLoaded || state.activeAgencyId == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      onChanged: (value) {
                        _searchQuery = value.toLowerCase();
                        _chatListBloc.add(
                            UpdateSearchQueryEvent(searchQuery: _searchQuery));
                      },
                    ),
                  ),
                // Chat List or Agency Chat
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            ),
            floatingActionButton: null,
          );
        },
      ),
    );
  }

  Widget _buildBody(ChatListState state) {
    if (state is ChatListLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (state is ChatListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRetryPressed,
              style: _buttonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is ChatListLoaded) {
      // Show agency chat screen if active agency is set
      if (state.activeAgencyId != null) {
        return AgencyChatScreen(
          currentUserId: widget.currentUserId,
          agencyId: state.activeAgencyId!,
          agencyName: state.activeAgencyName ?? 'Agency',
          agencyLogo: state.activeAgencyLogo,
        );
      }

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _filterChatsWithUserData(state.chats),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          final filteredChats = snapshot.data ?? state.chats;

          if (filteredChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No chats yet' : 'No chats found',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefreshPressed,
                    style: _buttonStyle,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefreshPressed,
            child: ListView.separated(
              itemCount: filteredChats.length,
              separatorBuilder: (context, i) =>
                  const Divider(color: Colors.white12, height: 0),
              itemBuilder: (context, index) {
                final chatDoc =
                    filteredChats[index]['chatDoc'] as QueryDocumentSnapshot;
                final otherUserId = chatDoc.id;
                final latestTime = filteredChats[index]['latestTime'] as int;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final userName = userData?['fullName'] ??
                        userData?['name'] ??
                        userData?['userName'] ??
                        'Unknown User';
                    final userImage = userData?['profileImageUrl'] ??
                        userData?['avatarUrl'] ??
                        '';
                    final bool isOnline =
                        (userData?['onlineStatus'] ?? false) == true;

                    // Check if this is an agency user - try multiple possible fields
                    final isAgency = userData?['userType'] == 'agency' ||
                        userData?['isAgency'] == true ||
                        userData?['role'] == 'agency' ||
                        userData?['accountType'] == 'agency' ||
                        userData?['type'] == 'agency' ||
                        userData?['agency'] == true;

                    // Debug: Print user data to check agency fields

                    // Additional filtering in case search query changed
                    if (_searchQuery.isNotEmpty &&
                        !userName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: chatDoc.reference
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, messageSnapshot) {
                        String lastMessage = 'No messages yet';
                        bool isUnread = false;

                        if (messageSnapshot.hasData &&
                            messageSnapshot.data!.docs.isNotEmpty) {
                          final messageDoc = messageSnapshot.data!.docs.first;
                          final messageData =
                              messageDoc.data() as Map<String, dynamic>?;
                          lastMessage = messageData?['text'] ?? 'No message';
                          isUnread = !(messageData?['isRead'] as bool? ??
                                  true) &&
                              messageData?['senderId'] != widget.currentUserId;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white24,
                            backgroundImage: userImage.isNotEmpty
                                ? NetworkImage(userImage)
                                : null,
                            child: userImage.isEmpty
                                ? Icon(isAgency ? Icons.business : Icons.person,
                                    color: Colors.white)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Icon(
                                isOnline ? Icons.circle : Icons.circle_outlined,
                                color: isOnline ? Colors.green : Colors.grey,
                                size: 8,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            lastMessage,
                            style: TextStyle(
                              color: isUnread ? Colors.white : Colors.white70,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 64,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (latestTime > 0)
                                  Text(
                                    _formatTimestamp(latestTime),
                                    style: TextStyle(
                                      color: isUnread
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 6),
                                if (isUnread)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (isAgency) {
                              // Switch to agency chat mode
                              _switchToAgencyChat(
                                otherUserId,
                                userName,
                                userImage,
                              );
                            } else {
                              // Navigate to regular chat screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatProjectExchangeScreen(
                                    currentUserId: widget.currentUserId,
                                    profileUserId: otherUserId,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showAgencySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Agency Chat'),
        content: const Text('Choose an agency to start chatting with:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAgencySwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Agency Chat'),
        content: const Text('Do you want to switch back to chat list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _switchBackToChatList();
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
