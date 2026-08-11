import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/web_layout.dart';
import '../profile_screen.dart';
import '../web_users_profiles_screen.dart';
import '../exchange_projects_screen.dart';
import '../chat_list_screen.dart';
import '../community_screen.dart';
import '../live_support_screen.dart';
import '../agency_screen.dart';
import '../settings_screen.dart';
import '../features/profile_analytics/presentation/profile_analytics_screen.dart';
import '../features/admin/payments/admin_payments_screen.dart';
import '../features/admin/support/admin_support_screen.dart';
import '../features/admin/slider/slider_admin_screen.dart';
import '../features/admin/popup/popup_admin_screen.dart';
import '../subscription_screen.dart';
import 'package:intl/intl.dart';

class WebDashboardScreen extends StatefulWidget {
  final String? userId;
  final int selectedIndex;
  const WebDashboardScreen({Key? key, this.userId, this.selectedIndex = 0}) : super(key: key);

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  String? userName;
  String? userPlan;
  String? userImageUrl;
  String? userJobTitle;
  String? userEmail;
  String? userCountry;
  String? userCity;
  bool _isAdmin = false;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    setState(() {
      userName = (data['fullName'] ?? data['name'] ?? 'User').toString();
      userPlan = (data['plan'] ?? 'Free').toString();
      userImageUrl = data['profileImageUrl'];
      userJobTitle = data['jobTitle'];
      userEmail = data['email'];
      userCountry = data['country'];
      userCity = data['city'];
      _isAdmin = (data['isAdmin'] == true) || 
                 ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') ||
                 (widget.userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52');
      isLoading = false;
    });
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23272A),
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: userImageUrl != null ? NetworkImage(userImageUrl!) : null,
                  child: userImageUrl == null 
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  userName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (userJobTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    userJobTitle!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: userPlan == 'Pro' ? Colors.amber : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userPlan ?? 'Free',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.people, 'Users', 1),
                _buildNavItem(Icons.swap_horiz, 'Projects', 2),
                _buildNavItem(Icons.chat, 'Messages', 3),
                _buildNavItem(Icons.group, 'Community', 4),
                _buildNavItem(Icons.business, 'Agency', 5),
                _buildNavItem(Icons.support_agent, 'Support', 6),
                if (_isAdmin) ...[
                  const Divider(color: Colors.grey),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildNavItem(Icons.admin_panel_settings, 'Admin Dashboard', 7),
                  _buildNavItem(Icons.payment, 'Payments', 8),
                  _buildNavItem(Icons.support, 'Support Admin', 9),
                  _buildNavItem(Icons.image, 'Slider Admin', 10),
                  _buildNavItem(Icons.notifications, 'Popup Admin', 11),
                ],
                const Divider(color: Colors.grey),
                _buildNavItem(Icons.settings, 'Settings', 12),
                _buildNavItem(Icons.logout, 'Logout', 13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey.shade400,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: () => _navigateToScreen(index),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getScreenTitle(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF23272A),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return WebUsersProfilesScreen();
      case 2:
        return ExchangeProjectsScreen(currentUserId: widget.userId ?? '');
      case 3:
        return ChatListScreen(currentUserId: widget.userId ?? '');
      case 4:
        return CommunityScreen(userId: widget.userId ?? '');
      case 5:
        return AgencyScreen(userId: widget.userId ?? '');
      case 6:
        return LiveSupportScreen();
      case 7:
        return _buildAdminDashboard();
      case 8:
        return AdminPaymentsScreen();
      case 9:
        return AdminSupportScreen();
      case 10:
        return SliderAdminScreen();
      case 11:
        return PopupAdminScreen();
      case 12:
        return SettingsScreen();
      case 13:
        return _buildLogoutScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          ResponsiveGrid(
            children: [
              WebCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Total Users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1,234',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF23272A),
                      ),
                    ),
                  ],
                ),
              ),
              WebCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.green, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Projects Exchanged',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '567',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF23272A),
                      ),
                    ),
                  ],
                ),
              ),
              WebCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat, color: Colors.orange, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '89',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF23272A),
                      ),
                    ),
                  ],
                ),
              ),
              WebCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.trending_up, color: Colors.purple, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Active Now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '45',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF23272A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          WebCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF23272A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityItem('New user registered', '2 minutes ago'),
                _buildActivityItem('Project exchanged', '15 minutes ago'),
                _buildActivityItem('New message received', '1 hour ago'),
                _buildActivityItem('Profile updated', '2 hours ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF23272A),
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return const Center(
      child: Text(
        'Admin Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogoutScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.logout,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Logging out...',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Users';
      case 2: return 'Projects';
      case 3: return 'Messages';
      case 4: return 'Community';
      case 5: return 'Agency';
      case 6: return 'Support';
      case 7: return 'Admin Dashboard';
      case 8: return 'Payments';
      case 9: return 'Support Admin';
      case 10: return 'Slider Admin';
      case 11: return 'Popup Admin';
      case 12: return 'Settings';
      default: return 'Dashboard';
    }
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF23272A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: WebLayout(
        sidebar: _buildSidebar(),
        mainContent: _buildMainContent(),
        topBar: _buildTopBar(),
      ),
    );
  }
}
