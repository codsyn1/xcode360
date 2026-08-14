import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'profile_screen.dart';
import 'users_profiles_screen.dart'; // Added import for UsersProfilesScreen
import 'exchange_projects_screen.dart'; // Added import for ExchangeProjectsScreen
import 'chat_project_exchange_screen.dart';
import 'chat_list_screen.dart';
import 'subcategories_screen.dart'; // Added import for SubcategoriesScreen
import 'package:intl/intl.dart';
import 'community_screen.dart'; // Add this import
import 'live_support_screen.dart'; // Added import for LiveSupportScreen
import 'agency_screen.dart'; // Added import for AgencyScreen
import 'agency_options_screen.dart'; // Added import for AgencyOptionsScreen
import 'settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'features/profile_analytics/presentation/profile_analytics_screen.dart';
import 'features/admin/payments/admin_payments_screen.dart';
import 'features/admin/support/admin_support_screen.dart';
import 'features/admin/slider/slider_admin_screen.dart';
import 'features/admin/popup/popup_admin_screen.dart';
import 'features/profile_analytics/presentation/bloc/analytics_access_cubit.dart';
import 'subscription_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/ai_services/presentation/bloc/ai_services_cubit.dart';
import 'features/ai_services/presentation/bloc/ai_services_state.dart';

import 'features/admin/slider/slider_admin_cubit.dart';
import 'features/admin/slider/slider_admin_state.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final int selectedIndex;
  const DashboardScreen({Key? key, required this.userId, this.selectedIndex = 0}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? userName;
  String? userPlan;
  bool isLoading = true;
  String? userImageUrl;
  String? userJobTitle; // Add job title
  String? userEmail;
  String? userPin;
  String? userCoverImageUrl;
  String? userBio;
  String? userWebsite;
  List<String> userSkills = [];
  String? userCountry; // Add country
  String? userCity;    // Add city
  bool _isAdmin = false;

  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _sliderTimer;
  StreamSubscription<List<SliderImageItem>>? _sliderSub;
  StreamSubscription<DocumentSnapshot>? _popupSub;
  bool _popupShown = false;
  StreamSubscription<DocumentSnapshot>? _userSub; // realtime user listener
  bool _receivedServerUserDoc = false; // track first server snapshot
  bool _receivedServerPopupDoc = false; // track first server popup

  List<String> _sliderImages = [];

  late final SliderAdminCubit _sliderCubit;

  late AnimationController _bgAnimationController;
  int _currentCardPage = 0;
  int _selectedIndex = 0;
  


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _bindUserStream() {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) async {
      final meta = doc.metadata;
      // On fresh run Firestore often emits a cached snapshot first; wait for server snapshot
      if (meta.isFromCache && !_receivedServerUserDoc) {
        return; // ignore cached emission before first server data
      }
      final data = doc.data() as Map<String, dynamic>? ?? {};
      String nameVal = (data['fullName'] ?? data['name'] ?? 'User').toString();
      String planVal = (data['plan'] ?? 'Free').toString();
      String? imageVal = data['profileImageUrl'];
      String? jobVal = data['jobTitle'];
      String? emailVal = data['email'];
      String? coverVal = data['coverImageUrl'];
      String? bioVal = data['bio'];
      String? webVal = data['website'];
      List<String> skillsVal = List<String>.from(data['skills'] ?? []);
      String countryVal = (data['country'] ?? '').toString();
      String cityVal = (data['city'] ?? '').toString();
      String? computedPin = data['userPin']?.toString();
      if (computedPin == null || computedPin.isEmpty) {
        final millis = DateTime.now().millisecondsSinceEpoch;
        final generatedPin = ((millis % 900000) + 100000).toString();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({'userPin': generatedPin}, SetOptions(merge: true));
        computedPin = generatedPin;
      }
      final emailLower = (emailVal ?? '').toLowerCase();
      final bool adminFlag = (data['isAdmin'] == true) || ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') || (widget.userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52');
      if (!mounted) return;
      setState(() {
        userName = nameVal;
        userPlan = planVal;
        userImageUrl = imageVal;
        userJobTitle = jobVal;
        userEmail = emailVal;
        userCoverImageUrl = coverVal;
        userBio = bioVal;
        userWebsite = webVal;
        userSkills = skillsVal;
        userCountry = countryVal;
        userCity = cityVal;
        _isAdmin = (data['isAdmin'] == true) || ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') || emailLower == 'jehangir.ceo@xcode360.com' || widget.userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52';
        userPin = computedPin;
        isLoading = false;
      });
      if (!meta.isFromCache) {
        _receivedServerUserDoc = true;
      }
    });
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.selectedIndex;
    fetchUserName();
    _bindUserStream();
    _sliderCubit = SliderAdminCubit();
    // Force a one-time server refresh so Flutter run shows the latest slider images
    _sliderCubit.refreshOnce();
    _bindSliderStream();
    _bindPopupStream();

    _sliderTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_pageController.hasClients && _sliderImages.isNotEmpty) {
        _currentPage++;
        if (_currentPage >= _sliderImages.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Check for pending notification navigation after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _checkPendingNotification();
    });
    
    // Also check periodically for a short time after app start
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 500 + (i * 500)), () {
        if (mounted) {
          _checkPendingNotification();
        }
      });
    }
  }

  Future<void> _checkPendingNotification() async {
    print("🔥 === CHECKING PENDING NOTIFICATION ===");
    final prefs = await SharedPreferences.getInstance();
    final pendingType = prefs.getString('pending_notification_type');
    print("🔍 Pending notification type: $pendingType");
    
    if (pendingType == 'chat_message') {
      final fromUserId = prefs.getString('pending_notification_from_user_id');
      final fromUserName = prefs.getString('pending_notification_from_user_name');
      
      print("📤 From User ID: $fromUserId");
      print("📤 From User Name: $fromUserName");
      print("📱 Current mounted state: $mounted");
      print("📱 Current user ID: ${widget.userId}");
      
      // Clear the pending notification data
      await prefs.remove('pending_notification_type');
      await prefs.remove('pending_notification_from_user_id');
      await prefs.remove('pending_notification_from_user_name');
      print("✅ Pending notification data cleared");
      
      if (fromUserId != null && mounted) {
        print("✅ Attempting to navigate to chat screen");
        print("📊 userPlan value: $userPlan");
        print("📊 widget.userId: ${widget.userId}");
        print("📊 fromUserId: $fromUserId");
        print("📊 fromUserName: $fromUserName");
        
        try {
          final chatScreen = ChatProjectExchangeScreen(
            currentUserId: widget.userId,
            profileUserId: fromUserId,
            otherUserName: fromUserName,
            userPlan: userPlan ?? 'Free',
          );
          
          print("✅ ChatProjectExchangeScreen created successfully");
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => chatScreen,
            ),
          );
          
          print("✅ Navigation to chat screen initiated");
          print("📱 Screen should be visible now");
        } catch (e) {
          print("❌ Error navigating to chat screen: $e");
          print("❌ Stack trace: ${StackTrace.current}");
        }
      } else {
        print("❌ Cannot navigate - fromUserId is null or widget not mounted");
        if (fromUserId == null) print("❌ fromUserId is null");
        if (!mounted) print("❌ widget not mounted");
      }
    } else {
      print("⚠️ No pending chat message notification found");
    }
    print("🔥 === PENDING NOTIFICATION CHECK END ===");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Check for pending notifications when app becomes visible
    if (state == AppLifecycleState.resumed) {
      print("📱 App resumed - checking for pending notifications");
      _checkPendingNotification();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sliderTimer?.cancel();
    _sliderSub?.cancel();
    _popupSub?.cancel();
    _userSub?.cancel();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _bindSliderStream() {
    _sliderSub?.cancel();
    _sliderSub = _sliderCubit.listenItems().listen((items) {
      final activeSorted = items.where((e) => e.active).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final imgs = activeSorted.map((e) => e.url).where((u) => u.isNotEmpty).toList();
      if (mounted) {
        setState(() {
          _sliderImages = imgs;
        });
      }
    }, onError: (e) {
      final msg = e.toString();
      debugPrint('Slider stream error (bloc): $msg');
      if (mounted) {
        setState(() {
          _sliderImages = [];
        });
      }
    });
  }

  void _bindPopupStream() {
    _popupSub?.cancel();
    _popupSub = FirebaseFirestore.instance
        .doc('appConfig/popup')
        .snapshots(includeMetadataChanges: true)
        .listen((doc) {
      final meta = doc.metadata;
      if (meta.isFromCache && !_receivedServerPopupDoc) {
        return; // wait for first server snapshot
      }
      final data = doc.data() as Map<String, dynamic>?;
      final active = data != null && (data['active'] ?? false) == true;
      final url = data != null ? (data['imageUrl'] ?? '').toString() : '';
      if (!_popupShown && active && url.isNotEmpty && mounted) {
        _popupShown = true;
        _showPopupImage(url);
      }
      if (!meta.isFromCache) {
        _receivedServerPopupDoc = true;
      }
    });
  }

  void _showPopupImage(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchUserName() async {
    try {
      // Force a server read on cold start so we don't show stale cache on flutter run
      DocumentSnapshot doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        // Fallback to default behavior if server-only fails
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
      }
      final raw = doc.data();
      final Map<String, dynamic> data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      // Prepare values outside setState
      String nameVal = (data['fullName'] ?? data['name'] ?? 'User').toString();
      String planVal = (data['plan'] ?? 'Free').toString();
      String? imageVal = data['profileImageUrl'];
      String? jobVal = data['jobTitle'];
      String? emailVal = data['email'];
      String? coverVal = data['coverImageUrl'];
      String? bioVal = data['bio'];
      String? webVal = data['website'];
      List<String> skillsVal = List<String>.from(data['skills'] ?? []);
      String countryVal = (data['country'] ?? '').toString();
      String cityVal = (data['city'] ?? '').toString();
      String? computedPin = data['userPin']?.toString();
      if (computedPin == null || computedPin.isEmpty) {
        final millis = DateTime.now().millisecondsSinceEpoch;
        final generatedPin = ((millis % 900000) + 100000).toString();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({'userPin': generatedPin}, SetOptions(merge: true));
        computedPin = generatedPin;
      }
      final emailLower = (emailVal ?? '').toLowerCase();
      final bool adminFlag = (data['isAdmin'] == true) || ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') || (widget.userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52');

      setState(() {
        userName = nameVal;
        userPlan = planVal;
        userImageUrl = imageVal;
        userJobTitle = jobVal; // Fetch job title
        userEmail = emailVal;
        userCoverImageUrl = coverVal;
        userBio = bioVal;
        userWebsite = webVal;
        userSkills = skillsVal;
        userCountry = countryVal;
        userCity = cityVal;
        _isAdmin = (data['isAdmin'] == true) || ((data['username'] ?? '').toString().toLowerCase() == 'xcode360') || emailLower == 'jehangir.ceo@xcode360.com' || widget.userId == 'RLux0lxO4IM1GeSFqHUbmaf9eu52';
        userPin = computedPin;
        isLoading = false;
      });
      final raw2 = doc.data();
      final String covPrint = (raw2 is Map<String, dynamic>) ? (raw2['coverImageUrl'] ?? 'NULL').toString() : 'NULL';
      print('Fetched coverImageUrl: ' + covPrint);
    } catch (e) {
      setState(() {
        userName = 'User';
        userPlan = 'Free';
        userImageUrl = null;
        userJobTitle = null;
        userEmail = null;
        userCoverImageUrl = null;
        userBio = null;
        userWebsite = null;
        userSkills = [];
        userCountry = '';
        userCity = '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    // UserId check: agar userId null ya empty hai to onboarding pe redirect karo
    if (widget.userId == null || widget.userId.isEmpty) {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => OnboardingScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Subscription';
      case 2:
        return 'Chat';
      case 3:
        return 'Community';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }

    Widget _buildNavItem(IconData icon, int index) {
      final isSelected = _selectedIndex == index;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          const SizedBox(height: 2),
          Text(
            _getLabelForIndex(index),
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 20,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }

    Widget _buildChatNavItem() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildNavItem(Icons.chat_bubble_outline, 2);
          }
          final chatDocs = snapshot.data!.docs;
          return FutureBuilder<bool>(
            future: _hasAnyUnreadMessage(chatDocs, widget.userId),
            builder: (context, unreadSnapshot) {
              final hasUnread = unreadSnapshot.data == true;
              final isSelected = _selectedIndex == 2;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: isSelected ? Colors.white : Colors.white54,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Widget _buildProfileNavItem() {
      final isSelected = _selectedIndex == 4;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          userImageUrl != null && userImageUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? Colors.white : Colors.white24,
                  backgroundImage: NetworkImage(userImageUrl!),
                )
              : CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? Colors.white : Colors.white24,
                  child: Icon(Icons.person, color: Colors.white24, size: 16),
                ),
          const SizedBox(height: 2),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 20,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > 700;
    final cardHeight = isWide ? 260.0 : screenHeight * 0.28;
    final cardWidth = isWide ? 420.0 : screenWidth * 0.88;
    final cardRadius = isWide ? 32.0 : 22.0;
    final iconSize = isWide ? 64.0 : 48.0;
    final titleFont = isWide ? 26.0 : 18.0;
    final subtitleFont = isWide ? 18.0 : 13.0;
    final priceFont = isWide ? 20.0 : 15.0;
    final arrowIcon = isWide ? 28.0 : 20.0;
    final List<Widget> _pages = [
      Stack(
        children: [
          Container(color: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7)),
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Stack(
                children: [
                  _ParallaxLinesBackground(progress: _bgAnimationController.value),
                  _DottedBackground(offset: _bgAnimationController.value),
                ],
              );
            },
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: isWide ? 220 : 160,
                  child: PageView(
                    controller: _pageController,
                    children: _sliderImages.map((imgUrl) =>
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 8, vertical: isWide ? 18 : 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                SizedBox(height: isWide ? 32 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Communities Card - Enhanced UI
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunityScreen(userId: widget.userId, showAppBar: true),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: isWide ? 32 : 18, right: isWide ? 32 : 18, bottom: isWide ? 18 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF2D2D2D), // Light black
                                Color(0xFF1A1A1A), // Darker black
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: isWide ? 20 : 15,
                                offset: Offset(0, isWide ? 12 : 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: isWide ? 120 : 80,
                                  height: isWide ? 120 : 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -10,
                                top: -10,
                                child: Container(
                                  width: isWide ? 80 : 50,
                                  height: isWide ? 80 : 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: EdgeInsets.all(isWide ? 20 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon with enhanced styling
                                    Container(
                                      padding: EdgeInsets.all(isWide ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.diversity_3,
                                        color: Colors.white,
                                        size: iconSize * 0.9,
                                      ),
                                    ),
                                    SizedBox(height: isWide ? 16 : 12),
                                    // Title
                                    Text(
                                      'Communities',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: titleFont,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: isWide ? 6 : 4),
                                    // Subtitle
                                    Text(
                                      'Connect & collaborate',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: subtitleFont,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: isWide ? 8 : 6),
                                    // Stats/Features
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isWide ? 10 : 8,
                                            vertical: isWide ? 4 : 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(isWide ? 12 : 10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: Colors.white,
                                                size: isWide ? 14 : 12,
                                              ),
                                              SizedBox(width: isWide ? 6 : 4),
                                              Text(
                                                'Active',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isWide ? 12 : 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                        // Arrow button
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.all(isWide ? 10 : 8),
                                          child: Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: arrowIcon * 0.8,
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
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 20 : 16),
                // Second Row - Profile Analytics and Exchange Projects
                Container(
                  constraints: BoxConstraints(
                    maxWidth: 600, // Maximum width for better layout
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Analytics Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Use the same logic as AnalyticsAccessCubit for consistency
                            try {
                              final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
                              final plan = (doc.data()?['plan'] ?? '').toString().trim();
                              final isProAccount = plan.toLowerCase() == 'pro';
                            
                              if (isProAccount) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileAnalyticsScreen(userId: widget.userId),
                                  ),
                                );
                              } else {
                                // Show dialog for free users
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Pro Feature'),
                                    content: Text('Profile Analytics is available for Pro accounts only. Upgrade to Pro to access advanced analytics.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SubscriptionScreen(userId: widget.userId),
                                            ),
                                          );
                                        },
                                        child: Text('Upgrade to Pro'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              // Show error dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text('Unable to verify account status. Please try again.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive sizing based on container width
                              final containerWidth = constraints.maxWidth;
                              final isSmallMobile = containerWidth < 180;
                              final isMediumMobile = containerWidth < 220;
                              
                              double cardHeight = 160;
                              double cardPadding = 12;
                              double iconSize = 20;
                              double titleFontSize = 14;
                              double subtitleFontSize = 11;
                              double statsFontSize = 10;
                              double badgeFontSize = 8;
                              double arrowSize = 14;
                              double borderRadius = 12;
                              
                              if (isMediumMobile) {
                                cardHeight = 180;
                                cardPadding = 14;
                                iconSize = 22;
                                titleFontSize = 15;
                                subtitleFontSize = 12;
                                statsFontSize = 11;
                                badgeFontSize = 9;
                                arrowSize = 16;
                                borderRadius = 14;
                              } else if (!isSmallMobile) {
                                cardHeight = 200;
                                cardPadding = 16;
                                iconSize = 24;
                                titleFontSize = 16;
                                subtitleFontSize = 13;
                                statsFontSize = 12;
                                badgeFontSize = 10;
                                arrowSize = 18;
                                borderRadius = 16;
                              }
                              
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
                                builder: (context, snapshot) {
                                  // Use the same logic as AnalyticsAccessCubit for consistency
                                  final plan = ((snapshot.data?.data() as Map<String, dynamic>?)?['plan'] ?? '').toString().trim();
                                  final isProAccount = plan.toLowerCase() == 'pro';
                                  
                                  // Dim colors for free accounts, full colors for pro accounts
                                  final cardColor = isProAccount ? Color(0xFF1E1E1E) : Color(0xFF1A1A1A);
                                  final iconGradientColors = isProAccount 
                                    ? [Color(0xFF2D2D2D), Color(0xFF1A1A1A)]
                                    : [Color(0xFF1A1A1A), Color(0xFF0D0D0D)];
                                  final titleColor = isProAccount ? Colors.white : Colors.white.withOpacity(0.5);
                                  final subtitleColor = isProAccount 
                                    ? Colors.white.withOpacity(0.7) 
                                    : Colors.white.withOpacity(0.3);
                                  final arrowColor = isProAccount 
                                    ? Colors.white.withOpacity(0.1) 
                                    : Colors.white.withOpacity(0.05);
                                  final arrowIconColor = isProAccount 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.4);
                                  
                                  return Container(
                                    margin: EdgeInsets.only(right: 6, left: 8, bottom: 12),
                                    height: cardHeight,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isProAccount ? 0.3 : 0.15),
                                          blurRadius: isProAccount ? 12 : 8,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(isProAccount ? 0.1 : 0.05),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(cardPadding),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header with icon
                                          Row(
                                            children: [
                                              Container(
                                                width: iconSize * 2,
                                                height: iconSize * 2,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: iconGradientColors,
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(borderRadius - 2),
                                                ),
                                                child: Icon(
                                                  Icons.insights,
                                                  color: isProAccount ? Colors.white : Colors.white.withOpacity(0.4),
                                                  size: iconSize,
                                                ),
                                              ),
                                              Spacer(),
                                              if (!isProAccount)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: cardPadding * 0.6, vertical: cardPadding * 0.3),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF6366F3).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(borderRadius * 1.2),
                                                    border: Border.all(
                                                      color: Color(0xFF6366F3).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'PRO',
                                                    style: TextStyle(
                                                      color: Color(0xFF6366F3),
                                                      fontSize: badgeFontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: cardPadding),
                                          // Title
                                          Text(
                                            'Profile Analytics',
                                            style: TextStyle(
                                              color: titleColor,
                                              fontSize: titleFontSize,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: cardPadding * 0.4),
                                          // Subtitle
                                          Text(
                                            isSmallMobile ? 'Track progress' : 'Track your progress',
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: subtitleFontSize,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Spacer(),
                                          // Arrow button
                                          Container(
                                            width: arrowSize * 2.5,
                                            height: arrowSize * 2.5,
                                            decoration: BoxDecoration(
                                              color: arrowColor,
                                              borderRadius: BorderRadius.circular(arrowSize * 0.75),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color: arrowIconColor,
                                              size: arrowSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      // Exchange Projects Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExchangeProjectsScreen(
                                  currentUserId: widget.userId,
                                ),
                              ),
                            );
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive sizing based on container width
                              final containerWidth = constraints.maxWidth;
                              final isSmallMobile = containerWidth < 180;
                              final isMediumMobile = containerWidth < 220;
                              
                              double cardHeight = 160;
                              double cardPadding = 12;
                              double iconSize = 20;
                              double titleFontSize = 14;
                              double subtitleFontSize = 11;
                              double statsFontSize = 10;
                              double badgeFontSize = 8;
                              double arrowSize = 14;
                              double borderRadius = 12;
                              
                              if (isMediumMobile) {
                                cardHeight = 180;
                                cardPadding = 14;
                                iconSize = 22;
                                titleFontSize = 15;
                                subtitleFontSize = 12;
                                statsFontSize = 11;
                                badgeFontSize = 9;
                                arrowSize = 16;
                                borderRadius = 14;
                              } else if (!isSmallMobile) {
                                cardHeight = 200;
                                cardPadding = 16;
                                iconSize = 24;
                                titleFontSize = 16;
                                subtitleFontSize = 13;
                                statsFontSize = 12;
                                badgeFontSize = 10;
                                arrowSize = 18;
                                borderRadius = 16;
                              }
                              
                              return Container(
                                margin: EdgeInsets.only(left: 6, right: 8, bottom: 12),
                                height: cardHeight,
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(borderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon
                                      Row(
                                        children: [
                                          Container(
                                            width: iconSize * 2,
                                            height: iconSize * 2,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(borderRadius - 2),
                                            ),
                                            child: Icon(
                                              Icons.swap_horizontal_circle,
                                              color: Colors.white,
                                              size: iconSize,
                                            ),
                                          ),
                                          Spacer(),
                                        ],
                                      ),
                                      SizedBox(height: cardPadding),
                                      // Title
                                      Text(
                                        'Exchange Projects',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: cardPadding * 0.4),
                                      // Subtitle
                                      Text(
                                        isSmallMobile ? 'Swap & collaborate' : 'Swap and collaborate',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: subtitleFontSize,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Spacer(),
                                      // Arrow button
                                      Container(
                                        width: arrowSize * 2.5,
                                        height: arrowSize * 2.5,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(arrowSize * 0.75),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: arrowSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isWide ? 32 : 24),
                Column(
                  children: [
                    SizedBox(
                      height: cardHeight,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: isWide ? 0.55 : 0.92),
                        itemCount: 7,
                        onPageChanged: (index) {
                          setState(() {
                            _currentCardPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final cardData = [
                            {
                              'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
                              'title': 'Mobile Apps\nDevelopment',
                              'icon': Icons.phone_iphone,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
                              'title': 'Web\nDevelopment',
                              'icon': Icons.code,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1503676382389-4809596d5290?auto=format&fit=crop&w=800&q=80', // New web design image
                              'title': 'Web\nDesigning',
                              'icon': Icons.design_services,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                              'title': 'Graphics\nDesigning',
                              'icon': Icons.brush,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
                              'title': 'Digital\nMarketing',
                              'icon': Icons.trending_up,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1521737852567-6949f3f9f2b5?auto=format&fit=crop&w=800&q=80',
                              'title': 'Management',
                              'icon': Icons.people,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80',
                              'title': 'Business',
                              'icon': Icons.business,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=800&q=80',
                              'title': 'Writing &\nTranslation',
                              'icon': Icons.translate,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?auto=format&fit=crop&w=800&q=80',
                              'title': 'Video &\nAnimation',
                              'icon': Icons.videocam,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=800&q=80',
                              'title': 'SEO &\nBacklinks',
                              'icon': Icons.search,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1559028006-44a36f563c4e?auto=format&fit=crop&w=800&q=80',
                              'title': 'Design',
                              'icon': Icons.palette,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=800&q=80',
                              'title': 'AI & Data\nScience',
                              'icon': Icons.analytics,
                            },
                            {
                              'image': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=800&q=80',
                              'title': 'App & Web',
                              'icon': Icons.web,
                            },
                          ][index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SubcategoriesScreen(
                                    categoryTitle: cardData['title'] as String,
                                    categoryImage: cardData['image'] as String,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: isWide ? 18 : 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(cardRadius),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    cardData['image'] as String,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(cardRadius),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.black.withOpacity(0.85),
                                          Colors.black.withOpacity(0.25),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: isWide ? 24 : 16,
                                          offset: Offset(0, isWide ? 12 : 8),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(isWide ? 32 : 22),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon above text
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              cardData['icon'] as IconData,
                                              color: Colors.white,
                                              size: isWide ? 32 : 28,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Title text

                                          Text(
                                            cardData['title'] as String,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isWide ? 36 : 30,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: isWide ? 10 : 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                          if ((cardData['title'] as String) == 'AI Services') ...[
                                            const SizedBox(height: 10),
                                            BlocProvider(
                                              create: (_) => AiServicesCubit()..load(),
                                              child: BlocBuilder<AiServicesCubit, AiServicesState>(
                                                builder: (context, state) {
                                                  if (state is AiServicesLoaded) {
                                                    final cats = state.categories;
                                                    return Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: cats.take(isWide ? 10 : 6).map((c) {
                                                        return Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withOpacity(0.18),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(c.icon, size: isWide ? 16 : 14, color: Colors.white),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                c.title,
                                                                style: TextStyle(color: Colors.white, fontSize: isWide ? 13 : 11),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              ),
                                            ),
                                          ],

                                        ],
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(7, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: isWide ? 8 : 4, vertical: isWide ? 8 : 4),
                          width: _currentCardPage == index ? (isWide ? 28 : 18) : (isWide ? 12 : 8),
                          height: isWide ? 12 : 8,
                          decoration: BoxDecoration(
                            color: _currentCardPage == index ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(isWide ? 8 : 6),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 32 : 24),
              ],
            ),
          ),
        ],
      ),
      SubscriptionScreen(userId: widget.userId),
      ChatListScreen(currentUserId: widget.userId),
      CommunityScreen(userId: widget.userId),
      ProfileScreen(
        userId: widget.userId,
      ),
    ];
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: _selectedIndex == 4 ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        automaticallyImplyLeading: true, // Enable hamburger menu
        title: Text(_selectedIndex == 3 ? 'Community' : 'XCODE360'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('exchanges')
                .where('status', whereIn: ['pending', 'accepted'])
                .snapshots(),
            builder: (context, snapshot) {
              final hasNotifications = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications, color: isDarkMode ? Colors.white : Colors.black),
                    if (hasNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExchangeProjectsScreen(currentUserId: widget.userId),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF232323), // light black
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            backgroundImage: userImageUrl != null && userImageUrl!.isNotEmpty
                                ? NetworkImage(userImageUrl!)
                                : null,
                            child: (userImageUrl == null || userImageUrl!.isEmpty)
                                ? Icon(Icons.person, size: 32, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${userName ?? 'User'}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                if (userJobTitle != null && userJobTitle!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      userJobTitle!,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Text(
                                  userPlan == 'Pro' ? 'Pro Member' : 'Free Member',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Home', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              Tooltip(
                message: (userPlan?.toLowerCase() == 'pro')
                    ? 'View Profile Analytics'
                    : 'Pro only feature',
                child: Opacity(
                  opacity: (userPlan?.toLowerCase() == 'pro') ? 1.0 : 0.55,
                  child: ListTile(
                    leading: Icon(Icons.analytics, color: Colors.white),
                    title: Row(
                      children: [
                        Text('Profile Analytics', style: TextStyle(color: Colors.white)),
                        if ((userPlan?.toLowerCase() ?? 'free') != 'pro') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock, color: Colors.white54, size: 16),
                        ],
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final access = AnalyticsAccessCubit();
                      final allowed = await access.check(widget.userId);
                      if (allowed) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProfileAnalyticsScreen(userId: widget.userId)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile Analytics is available for Pro members only.')),
                        );
                      }
                    },
                  ),
                ),
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.person, color: Colors.white),
                title: Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.card_membership, color: Colors.white),
                title: Text('Subscription', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.groups, color: Colors.white),
                title: Text('Communities', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.people, color: Colors.white),
                title: Text('Users', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => UsersProfilesScreen()),
                  );
                },
              ),
              if (_isAdmin) ...[
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  title: const Text('Admin • Payments', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.white),
                  title: const Text('Admin • Support', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.slideshow, color: Colors.white),
                  title: const Text('Admin • Slider Images', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SliderAdminScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.white),
                  title: const Text('Admin • Popup Image', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PopupAdminScreen()),
                    );
                  },
                ),
              ],
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.swap_horiz, color: Colors.white),
                title: Text('Exchange Projects', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ExchangeProjectsScreen(currentUserId: widget.userId)),
                  );
                },
              ),
              if (!_isAdmin) const Divider(color: Colors.white24, height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.support_agent, color: Colors.white),
                title: Text('Live Support', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId') ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LiveSupportScreen(showOnlyCards: true)),
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.remove('userId');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => OnboardingScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bottom navigation
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white54,
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                elevation: 0,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavItem(Icons.home, 0),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(Icons.card_membership, 1),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildChatNavItem(),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(Icons.groups, 3),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildProfileNavItem(),
                    label: '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _hasAnyUnreadMessage(List<QueryDocumentSnapshot> chatDocs, String currentUserId) async {
    for (final chatDoc in chatDocs) {
      // Simplified query to avoid index issues
      final messagesSnap = await chatDoc.reference
          .collection('messages')
          .get();
      if (messagesSnap.docs.isNotEmpty) {
        // Check client-side for unread messages
        for (final messageDoc in messagesSnap.docs) {
          final messageData = messageDoc.data() as Map<String, dynamic>;
          if (messageData['senderId'] != currentUserId && messageData['isRead'] == false) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

// --- Dots && Parallax Lines Background Widgets (copied from onboarding_screen.dart) ---
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

class _ParallaxLinesBackground extends StatelessWidget {
  final double progress;
  const _ParallaxLinesBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ParallaxLinesPainter(progress),
    );
  }
}

class _ParallaxLinesPainter extends CustomPainter {
  final double progress;
  static final int points = 24;
  static final List<_MovingPoint> basePoints = List.generate(
    points,
    (i) => _MovingPoint(
      angle: 2 * math.pi * i / points,
      radiusFactor: 0.25 + 0.25 * (i % 3),
      speed: 0.5 + 0.2 * (i % 5),
    ),
  );

  _ParallaxLinesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.1;

    final center = Offset(size.width / 2, size.height / 2);
    final minSide = size.shortestSide;
    final List<Offset> offsets = basePoints.map((p) => p.position(center, minSide, progress)).toList();

    for (int i = 0; i < points; i++) {
      for (int j = i + 1; j < points; j++) {
        if ((offsets[i] - offsets[j]).distance < minSide * 0.35) {
          canvas.drawLine(offsets[i], offsets[j], paint);
        }
      }
    }
    for (final offset in offsets) {
      canvas.drawCircle(offset, 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParallaxLinesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _MovingPoint {
  final double angle;
  final double radiusFactor;
  final double speed;
  _MovingPoint({required this.angle, required this.radiusFactor, required this.speed});

  Offset position(Offset center, double minSide, double progress) {
    final double r = minSide * (radiusFactor + 0.18 * (math.sin(progress * 2 * math.pi * speed + angle)));
    final double a = angle + progress * 2 * math.pi * speed;
    return Offset(
      center.dx + r * math.cos(a),
      center.dy + r * math.sin(a),
    );
  }
} 