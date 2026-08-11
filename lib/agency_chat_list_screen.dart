import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'agency_chat_screen.dart';

class AgencyChatListScreen extends StatefulWidget {
  final String currentUserId;
  const AgencyChatListScreen({required this.currentUserId, Key? key}) : super(key: key);

  @override
  State<AgencyChatListScreen> createState() => _AgencyChatListScreenState();
}

class _AgencyChatListScreenState extends State<AgencyChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _agencyChats = [];
  bool _isLoading = false;
  StreamSubscription? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _loadAgencyChats();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    _chatsSubscription?.cancel();
    
    _chatsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('agencyChat')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _loadAgencyChats();
      }
    });
  }

  Future<void> _loadAgencyChats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userAgencyChatsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('agencyChat')
          .limit(10)
          .get();

      final agencyChats = <Map<String, dynamic>>[];
      
      for (final chatDoc in userAgencyChatsSnapshot.docs) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final agencyId = chatData['agencyId'] as String?;
        
        if (agencyId != null) {
          try {
            final agencyDoc = await FirebaseFirestore.instance
                .collection('agencies')
                .doc(agencyId)
                .get();
            
            if (agencyDoc.exists) {
              final agencyData = agencyDoc.data() as Map<String, dynamic>?;
              final agencyName = agencyData?['name'] ?? 'Unknown Agency';
              
              if (_searchQuery.isEmpty || agencyName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                agencyChats.add({
                  'chatDoc': chatDoc,
                  'agencyId': agencyId,
                  'agencyData': agencyData ?? {},
                  'lastMessage': chatData['lastMessage'] ?? 'No messages yet',
                  'latestTime': chatData['lastMessageTime'] ?? 0,
                });
              }
            }
          } catch (e) {
            print('Error fetching agency: $e');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _agencyChats = agencyChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading agency chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatsSubscription?.cancel();
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Agency Chats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search agencies...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
                _loadAgencyChats();
              },
            ),
          ),
          
          // Agency Chat List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _agencyChats.isEmpty
                    ? const Center(
                        child: Text(
                          'No agency chats found',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAgencyChats,
                        child: ListView.builder(
                          itemCount: _agencyChats.length,
                          itemBuilder: (context, index) {
                            final chatData = _agencyChats[index];
                            final agencyData = chatData['agencyData'] as Map<String, dynamic>;
                            final agencyId = chatData['agencyId'] as String;
                            final latestTime = chatData['latestTime'] as int;

                            return ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                ),
                                child: ClipOval(
                                  child: (agencyData['logo']?.isNotEmpty == true)
                                      ? Image.network(
                                          agencyData['logo'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => (agencyData['profileImageUrl']?.isNotEmpty == true)
                                              ? Image.network(
                                                  agencyData['profileImageUrl'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.white),
                                                )
                                              : const Icon(Icons.business, color: Colors.white),
                                        )
                                      : (agencyData['profileImageUrl']?.isNotEmpty == true)
                                          ? Image.network(
                                              agencyData['profileImageUrl'],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.white),
                                            )
                                          : const Icon(Icons.business, color: Colors.white),
                                ),
                              ),
                              title: Text(
                                agencyData['name'] ?? agencyData['fullName'] ?? 'Unknown Agency',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                chatData['lastMessage'] ?? 'No messages yet',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (latestTime > 0)
                                    Text(
                                      _formatTimestamp(latestTime),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AgencyChatScreen(
                                      currentUserId: widget.currentUserId,
                                      agencyId: agencyId,
                                      agencyName: agencyData['name'] ?? agencyData['fullName'] ?? 'Agency',
                                      agencyLogo: agencyData['logo'] ?? agencyData['profileImageUrl'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
