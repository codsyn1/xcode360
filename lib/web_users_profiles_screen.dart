import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/web_layout.dart';
import '../profile_screen.dart';
import '../exchange_projects_screen.dart';
import '../chat_list_screen.dart';
import '../community_screen.dart';
import '../subscription_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/users/presentation/bloc/users_cubit.dart';
import '../features/users/presentation/bloc/users_state.dart';
import '../features/users/data/users_repository.dart';

class WebUsersProfilesScreen extends StatefulWidget {
  final String? subcategory;
  const WebUsersProfilesScreen({Key? key, this.subcategory}) : super(key: key);

  @override
  State<WebUsersProfilesScreen> createState() => _WebUsersProfilesScreenState();
}

class _WebUsersProfilesScreenState extends State<WebUsersProfilesScreen> {
  String _searchQuery = '';
  String? _selectedCountry;
  int? _selectedRating;
  String? _currentUserId;
  final UsersCubit _usersCubit = UsersCubit(UsersRepository());

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _usersCubit.start(subcategory: widget.subcategory);
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId') ?? '';
    });
  }

  Widget _buildSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Country Filter
          const Text(
            'Country',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              
              final countries = snapshot.data!.docs
                  .map((doc) => ((doc.data() as Map<String, dynamic>)['country'] ?? '').toString())
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList();
              
              return DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                items: ['All', ...countries]
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                  });
                },
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Rating Filter
          const Text(
            'Rating',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedRating,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: [
              DropdownMenuItem(value: null, child: Text('All Ratings')),
              DropdownMenuItem(value: 5, child: Text('5 Stars')),
              DropdownMenuItem(value: 4, child: Text('4+ Stars')),
              DropdownMenuItem(value: 3, child: Text('3+ Stars')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRating = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<UsersCubit, UsersState>(
      bloc: _usersCubit,
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state.error != null) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final users = state.users.where((user) {
          final name = (user['fullName'] ?? user['name'] ?? '').toString().toLowerCase();
          final country = (user['country'] ?? '').toString();
          final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
          final matchesCountry = _selectedCountry == null || _selectedCountry == 'All' || country == _selectedCountry;
          final isNotCurrentUser = _currentUserId != null && _currentUserId!.isNotEmpty ? user['id'] != _currentUserId : true;
          
          return matchesSearch && matchesCountry && isNotCurrentUser;
        }).toList();

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ResponsiveGrid(
          crossAxisCount: _getCrossAxisCount(),
          childAspectRatio: 0.8,
          children: users.map((user) => _buildUserCard(user)).toList(),
        );
      },
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= 900) return 3;
    if (screenWidth >= 600) return 2;
    return 1;
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = (user['id'] ?? '').toString();
    final name = (user['fullName'] ?? user['name'] ?? 'User').toString();
    final imageUrl = (user['profileImageUrl'] ?? '').toString();
    final jobTitle = (user['jobTitle'] ?? '').toString();
    final country = (user['country'] ?? '').toString();
    final plan = (user['plan'] ?? '').toString();
    final isPro = plan.toLowerCase() == 'pro';
    final online = (user['onlineStatus'] ?? false) == true;

    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade300,
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPro) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    if (jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  country,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (online) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          
          const Spacer(),
          
          Row(
            children: [
              Expanded(
                child: WebButton(
                  text: 'View Profile',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: userId),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: WebButton(
                  text: 'Message',
                  onPressed: () {
                    // Navigate to chat
                  },
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: WebLayout(
        sidebar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23272A),
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: _buildSidebar(),
        ),
        mainContent: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Users',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF23272A),
                      ),
                    ),
                  ),
                  WebButton(
                    text: 'Refresh',
                    icon: Icons.refresh,
                    onPressed: () {
                      _usersCubit.start(subcategory: widget.subcategory);
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }
}
