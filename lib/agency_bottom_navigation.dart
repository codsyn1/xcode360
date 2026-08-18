import 'package:flutter/material.dart';
import 'agency_screen.dart';
import 'agency_exchange_projects_screen.dart';
import 'agency_payment_page.dart';
import 'exchange_projects_screen.dart';
import 'agency_profile_screen.dart';
import 'create_agency_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'agency_chat_screen.dart';

class AgencyBottomNavigation extends StatelessWidget {
  final String userId;
  final String agencyId;
  final int currentIndex;

  const AgencyBottomNavigation({
    super.key,
    required this.userId,
    required this.agencyId,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;
    final isMobile = screenWidth <= 800;
    final isSmallMobile = screenWidth <= 400;

    return Container(
      height: isDesktop ? 90 : (isTablet ? 80 : (isSmallMobile ? 60 : 70)),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home,
            label: isSmallMobile ? '' : 'Home',
            isSelected: currentIndex == 0,
            onTap: () {
              // Navigate to agencies page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AgencyScreen(userId: userId),
                ),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.swap_horiz,
            label: isSmallMobile ? '' : (isMobile ? 'Exchange' : 'Exchange Projects'),
            isSelected: currentIndex == 1,
            onTap: () {
              // Navigate to exchange projects
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExchangeProjectsScreen(currentUserId: userId),
                ),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.workspace_premium,
            label: isSmallMobile ? '' : (isMobile ? 'Pro' : 'Payment'),
            isSelected: currentIndex == 2,
            onTap: () {
              // Navigate to payment page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AgencyPaymentPage(userId: userId),
                ),
              );
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.chat,
            label: isSmallMobile ? '' : (isMobile ? 'Chat' : 'Agency Chat'),
            isSelected: currentIndex == 3,
            onTap: () {
              // Navigate to agency chat history
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AgencyChatHistoryScreen(
                    userId: userId,
                    agencyId: agencyId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;
    final isMobile = screenWidth <= 800;
    final isSmallMobile = screenWidth <= 400;

    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(isDesktop ? 3 : (isTablet ? 2 : (isMobile ? 1.5 : 1))),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isDesktop ? 10 : (isTablet ? 8 : 6)),
                color: Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: isDesktop ? 36 : (isTablet ? 32 : (isSmallMobile ? 20 : 28)),
                  color: isSelected ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Only show text if not small mobile
            if (!isSmallMobile)
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                  fontSize: isDesktop ? 15 : (isTablet ? 13 : (isSmallMobile ? 8 : 10)),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            const SizedBox(height: 2),
            // White line under all icons
            Container(
              width: isDesktop ? 40 : (isTablet ? 32 : (isSmallMobile ? 20 : 28)),
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 2),
            // Selection line indicator - white when selected
            if (isSelected)
              Container(
                width: isDesktop ? 40 : (isTablet ? 32 : (isSmallMobile ? 20 : 28)),
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AgencyChatHistoryScreen extends StatefulWidget {
  final String userId;
  final String agencyId;

  const AgencyChatHistoryScreen({
    super.key,
    required this.userId,
    required this.agencyId,
  });

  @override
  State<AgencyChatHistoryScreen> createState() => _AgencyChatHistoryScreenState();
}

class _AgencyChatHistoryScreenState extends State<AgencyChatHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white54,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chat history yet',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation to see chat history here',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final chatDocs = chatSnapshot.data!.docs;
          
          // Group chats by agency and user
          Map<String, List<DocumentSnapshot>> agencyChats = {};
          Map<String, Map<String, dynamic>> agencyInfo = {};
          
          for (var chatDoc in chatDocs) {
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final agencyId = chatData['agencyId'] as String;
            final senderId = chatData['senderId'] as String;
            
            if (!agencyChats.containsKey(agencyId)) {
              agencyChats[agencyId] = [];
            }
            agencyChats[agencyId]!.add(chatDoc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agencyChats.keys.length,
            itemBuilder: (context, index) {
              final agencyId = agencyChats.keys.elementAt(index);
              final chats = agencyChats[agencyId]!;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('agencies')
                    .doc(agencyId)
                    .get(),
                builder: (context, agencySnapshot) {
                  if (!agencySnapshot.hasData || !agencySnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  
                  final agencyData = agencySnapshot.data!.data() as Map<String, dynamic>;
                  final agencyName = agencyData['name'] ?? 'Unknown Agency';
                  final agencyLogo = agencyData['logoUrl'];
                  final agencyOwnerId = agencyData['ownerId'];
                  
                  // Get unique users who sent messages to this agency
                  final uniqueUsers = chats.map((chat) => chat['senderId'] as String).toSet().toList();
                  
                  return Card(
                    color: const Color(0xFF2C2C2C),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A1A1A),
                        child: agencyLogo != null && agencyLogo.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: agencyLogo,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.business,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.business,
                                color: Colors.white54,
                                size: 20,
                              ),
                      ),
                      title: Text(
                        agencyName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${uniqueUsers.length} users, ${chats.length} messages',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: const Icon(Icons.expand_more, color: Color(0xFF757575)),
                      children: [
                        // Show individual user chats
                        ...uniqueUsers.map((userId) {
                          final userChats = chats.where((chat) => chat['senderId'] == userId).toList();
                          
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, userSnapshot) {
                              final userName = userSnapshot.data?['name'] ?? 'Unknown User';
                              final userProfileImage = userSnapshot.data?['profileImage'];
                              final lastMessage = userChats.first['message'] as String;
                              final timestamp = userChats.first['timestamp'] as Timestamp;
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  child: userProfileImage != null && userProfileImage.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: CachedNetworkImage(
                                            imageUrl: userProfileImage,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => const Icon(
                                              Icons.person,
                                              color: Colors.white54,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                ),
                                title: Text(
                                  userName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastMessage.length > 50 
                                          ? '${lastMessage.substring(0, 50)}...'
                                          : lastMessage,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF757575),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${userChats.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AgencyChatScreen(
                                        currentUserId: widget.userId,
                                        agencyId: agencyId,
                                        agencyName: agencyName,
                                        agencyLogo: agencyLogo,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    
    if (now.difference(messageTime).inDays == 0) {
      return 'Today ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageTime).inDays == 1) {
      return 'Yesterday ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }
}
