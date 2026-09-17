import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import 'profile_screen.dart';
import 'users_profiles_screen.dart'; // Added import for UsersProfilesScreen
import 'exchange_projects_screen.dart'; // Added import for ExchangeProjectsScreen
import 'chat_project_exchange_screen.dart';
import 'chat_list_screen.dart';
import 'subcategories_screen.dart'; // Added import for SubcategoriesScreen
import 'community_screen.dart'; // Add this import
import 'live_support_screen.dart'; // Added import for LiveSupportScreen
// Added import for AgencyScreen
// Added import for AgencyOptionsScreen
import 'settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'features/profile_analytics/presentation/profile_analytics_screen.dart';
import 'features/profile_analytics/data/profile_analytics_repository.dart';
import 'features/admin/payments/admin_payments_screen.dart';
import 'features/admin/support/admin_support_screen.dart';
import 'features/admin/slider/slider_admin_screen.dart';
import 'features/admin/popup/popup_admin_screen.dart';
import 'features/profile_analytics/presentation/bloc/analytics_access_cubit.dart';
import 'subscription_screen.dart';

import 'features/ai_services/presentation/bloc/ai_services_cubit.dart';
import 'features/ai_services/presentation/bloc/ai_services_state.dart';

import 'features/admin/slider/slider_admin_cubit.dart';
import 'features/admin/slider/slider_admin_state.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final int selectedIndex;
  const DashboardScreen({super.key, required this.userId, this.selectedIndex = 0});

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

  final PageController _carouselPageController = PageController(viewportFraction: 0.92);
  int _carouselCurrentPage = 0;
  Timer? _carouselTimer;
  


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
      final data = doc.data() ?? {};
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

    _sliderTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pageController.hasClients && _sliderImages.isNotEmpty) {
        _currentPage++;
        if (_currentPage >= _sliderImages.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_carouselPageController.hasClients) {
        final nextPage = (_carouselCurrentPage + 1) % 3;
        _carouselPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    // Check for pending notification navigation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
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
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
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
      final data = doc.data();
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
      print('Fetched coverImageUrl: $covPrint');
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

  Widget _buildHeroBannerFallback(bool isDarkMode, double cardRadius, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 8, vertical: 8),
      height: isDesktop ? 220 : 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2638), const Color(0xFF131722)]
              : [const Color(0xFFEDE9FE), const Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDarkMode ? Colors.white : const Color(0xFF7C3AED)).withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDarkMode ? Colors.white : const Color(0xFF3B82F6)).withValues(alpha: 0.03),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: isDarkMode ? Colors.amber : const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'XCODE360 PLATFORM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 12 : 8),
                  Text(
                    'Exchange Projects & Collaborate',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connect with verified developers and agencies worldwide to share opportunities and build together.',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: isDarkMode ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    // UserId check: agar userId null ya empty hai to onboarding pe redirect karo
    if (widget.userId.isEmpty) {
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String getLabelForIndex(int index) {
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

    Widget buildNavItem(IconData icon, int index) {
      final isSelected = _selectedIndex == index;
      final activeColor = isDarkMode ? Colors.white : Colors.black87;
      final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 2),
          Text(
            getLabelForIndex(index),
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 20,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }

    Widget buildChatNavItem() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return buildNavItem(Icons.chat_bubble_outline, 2);
          }
          final chatDocs = snapshot.data!.docs;
          return FutureBuilder<bool>(
            future: _hasAnyUnreadMessage(chatDocs, widget.userId),
            builder: (context, unreadSnapshot) {
              final hasUnread = unreadSnapshot.data == true;
              final isSelected = _selectedIndex == 2;
              final activeColor = isDarkMode ? Colors.white : Colors.black87;
              final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
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
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
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

    Widget buildProfileNavItem() {
      final isSelected = _selectedIndex == 4;
      final activeColor = isDarkMode ? Colors.white : Colors.black87;
      final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          userImageUrl != null && userImageUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : (isDarkMode ? Colors.white24 : Colors.black12),
                  backgroundImage: NetworkImage(userImageUrl!),
                )
              : CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? (isDarkMode ? Colors.white : Colors.black87)
                      : (isDarkMode ? Colors.white24 : Colors.black12),
                  child: Icon(Icons.person,
                      color: isDarkMode ? Colors.white24 : Colors.black38, size: 16),
                ),
          const SizedBox(height: 2),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 20,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth > 700;
    final isDesktop = screenWidth > 900;
    final cardHeight = isWide ? 260.0 : screenHeight * 0.28;
    final cardRadius = isWide ? 20.0 : 16.0;
    final iconSize = isWide ? 56.0 : 44.0;
    final titleFont = isWide ? 22.0 : 17.0;
    final subtitleFont = isWide ? 14.0 : 12.0;
    final arrowIcon = isWide ? 24.0 : 18.0;
    final List<Widget> pages = [
      Stack(
        children: [
          Container(color: AppColors.background(isDarkMode)),
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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Padding(
                  padding: isDesktop
                      ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
                      : EdgeInsets.zero,
                  child: Column(
                    children: [
                if (isDesktop) const SizedBox(height: 16),
                if (_sliderImages.isEmpty)
                  _buildHeroBannerFallback(isDarkMode, cardRadius, isDesktop)
                else
                  SizedBox(
                    height: isDesktop ? 240 : (isWide ? 200 : 160),
                    child: PageView(
                      controller: _pageController,
                      children: _sliderImages.map((imgUrl) =>
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : (isWide ? 16 : 8), vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cardRadius),
                            child: Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildHeroBannerFallback(isDarkMode, cardRadius, isDesktop);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildHeroBannerFallback(isDarkMode, cardRadius, isDesktop);
                              },
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                SizedBox(height: isWide ? 32 : 24),
                // Communities & Users Carousel
                Builder(builder: (_) {
                  final carouselCards = <Widget>[
                      // Level Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : (isWide ? 12 : 6)),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final int projectsExchanged = (data?['projectsExchanged'] ?? 0) is int
                                ? (data?['projectsExchanged'] ?? 0) as int
                                : int.tryParse((data?['projectsExchanged'] ?? '0').toString()) ?? 0;
                            final levelInfo = ProfileAnalyticsRepository.computeLevelInfo(projectsExchanged);
                            final IconData levelIconData = levelInfo.icon;
                            final String levelTitle = levelInfo.levelLabel;
                            final String levelSubtitle = levelInfo.progressSubtitle;
                            final Color accentColor = levelInfo.levelLabel == 'Level 1'
                                ? const Color(0xFF555E6F)
                                : levelInfo.color;

                            Future<void> onTapLevel() async {
                              if (snapshot.connectionState != ConnectionState.done) return;
                              // Viewing your own current level is free for ALL users
                              // (Pro or not) — navigate directly to Profile Analytics.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileAnalyticsScreen(userId: widget.userId),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: onTapLevel,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppColors.cardGradient(isDarkMode),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow(isDarkMode).withOpacity(0.4),
                                      blurRadius: isWide ? 20 : 15,
                                      offset: Offset(0, isWide ? 12 : 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
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
                                          color: AppColors.cardOverlay(isDarkMode).withOpacity(0.06),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(isWide ? 20 : 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(isWide ? 16 : 12),
                                            decoration: BoxDecoration(
                                              color: accentColor.withOpacity(0.85),
                                              borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                                              border: Border.all(
                                                color: AppColors.cardSubtitle(isDarkMode),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              levelIconData,
                                              color: Colors.white,
                                              size: iconSize * 0.9,
                                            ),
                                          ),
                                          SizedBox(height: isWide ? 16 : 12),
                                          Text(
                                            levelTitle,
                                            style: TextStyle(
                                              color: AppColors.textPrimary(isDarkMode),
                                              fontWeight: FontWeight.bold,
                                              fontSize: titleFont,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(height: isWide ? 6 : 4),
                                          Text(
                                            levelSubtitle,
                                            style: TextStyle(
                                              color: AppColors.textSecondary(isDarkMode),
                                              fontSize: subtitleFont,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: isWide ? 8 : 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isWide ? 10 : 8,
                                                  vertical: isWide ? 4 : 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardOverlay(isDarkMode),
                                                  borderRadius: BorderRadius.circular(isWide ? 12 : 10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.trending_up,
                                                      color: AppColors.textPrimary(isDarkMode),
                                                      size: isWide ? 14 : 12,
                                                    ),
                                                    SizedBox(width: isWide ? 6 : 4),
                                                    Text(
                                                      'Progress',
                                                      style: TextStyle(
                                                        color: AppColors.cardTitle(isDarkMode),
                                                        fontSize: isWide ? 12 : 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.cardOverlay(isDarkMode),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors.textPrimary(isDarkMode).withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(isWide ? 10 : 8),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  color: AppColors.textPrimary(isDarkMode),
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
                            );
                          },
                        ),
                      ),
                      // Users Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : (isWide ? 12 : 6)),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UsersProfilesScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.cardGradient(isDarkMode),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow(isDarkMode).withOpacity(0.4),
                                  blurRadius: isWide ? 20 : 15,
                                  offset: Offset(0, isWide ? 12 : 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
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
                                      color: AppColors.cardOverlay(isDarkMode).withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isWide ? 20 : 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isWide ? 16 : 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardOverlay(isDarkMode).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                                          border: Border.all(
                                            color: AppColors.cardSubtitle(isDarkMode),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.people,
                                          color: AppColors.textPrimary(isDarkMode),
                                          size: iconSize * 0.9,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 16 : 12),
                                      Text(
                                        'Users',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(isDarkMode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: titleFont,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 6 : 4),
                                      Text(
                                        'Find and connect with users',
                                        style: TextStyle(
                                          color: AppColors.textSecondary(isDarkMode),
                                          fontSize: subtitleFont,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 8 : 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isWide ? 10 : 8,
                                              vertical: isWide ? 4 : 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardOverlay(isDarkMode),
                                              borderRadius: BorderRadius.circular(isWide ? 12 : 10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.people,
                                                  color: AppColors.textPrimary(isDarkMode),
                                                  size: isWide ? 14 : 12,
                                                ),
                                                SizedBox(width: isWide ? 6 : 4),
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary(isDarkMode),
                                                    fontSize: isWide ? 12 : 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.cardOverlay(isDarkMode),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.textPrimary(isDarkMode).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.all(isWide ? 10 : 8),
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: AppColors.textPrimary(isDarkMode),
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
                      // Communities Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : (isWide ? 12 : 6)),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CommunityScreen(userId: widget.userId, showAppBar: true),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.cardGradient(isDarkMode),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow(isDarkMode).withOpacity(0.4),
                                  blurRadius: isWide ? 20 : 15,
                                  offset: Offset(0, isWide ? 12 : 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
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
                                      color: AppColors.cardOverlay(isDarkMode).withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isWide ? 20 : 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isWide ? 16 : 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardOverlay(isDarkMode).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                                          border: Border.all(
                                            color: AppColors.cardSubtitle(isDarkMode),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.diversity_3,
                                          color: AppColors.textPrimary(isDarkMode),
                                          size: iconSize * 0.9,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 16 : 12),
                                      Text(
                                        'Communities',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(isDarkMode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: titleFont,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 6 : 4),
                                      Text(
                                        'Connect & collaborate',
                                        style: TextStyle(
                                          color: AppColors.textSecondary(isDarkMode),
                                          fontSize: subtitleFont,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isWide ? 8 : 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isWide ? 10 : 8,
                                              vertical: isWide ? 4 : 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardOverlay(isDarkMode),
                                              borderRadius: BorderRadius.circular(isWide ? 12 : 10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.people,
                                                  color: AppColors.textPrimary(isDarkMode),
                                                  size: isWide ? 14 : 12,
                                                ),
                                                SizedBox(width: isWide ? 6 : 4),
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary(isDarkMode),
                                                    fontSize: isWide ? 12 : 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.cardOverlay(isDarkMode),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.textPrimary(isDarkMode).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            padding: EdgeInsets.all(isWide ? 10 : 8),
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: AppColors.textPrimary(isDarkMode),
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
                  ];
                  if (isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: SizedBox(
                        height: 250,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: carouselCards[0]),
                            const SizedBox(width: 16),
                            Expanded(child: carouselCards[1]),
                            const SizedBox(width: 16),
                            Expanded(child: carouselCards[2]),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: isWide ? 270 : 210,
                    child: PageView(
                      controller: _carouselPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _carouselCurrentPage = index;
                        });
                      },
                      children: carouselCards,
                    ),
                  );
                }),
                if (!isDesktop) SizedBox(height: isWide ? 16 : 12),
                // Carousel Dot Indicators
                if (!isDesktop) Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: isWide ? 6 : 4),
                      width: _carouselCurrentPage == index ? (isWide ? 24 : 16) : (isWide ? 10 : 7),
                      height: isWide ? 10 : 7,
                      decoration: BoxDecoration(
                        color: _carouselCurrentPage == index
                            ? (isDarkMode ? Colors.white : Colors.black87)
                            : (isDarkMode ? Colors.white38 : Colors.black26),
                        borderRadius: BorderRadius.circular(isWide ? 8 : 6),
                      ),
                    );
                  }),
                ),
                SizedBox(height: isWide ? 44 : 32),
                // Second Row - Profile Analytics and Exchange Projects
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? double.infinity : 600,
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
                                    title: const Text('Pro Feature'),
                                    content: const Text('Profile Analytics is available for Pro accounts only. Upgrade to Pro to access advanced analytics.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SubscriptionScreen(userId: widget.userId, showBackButton: true),
                                            ),
                                          );
                                        },
                                        child: const Text('Upgrade to Pro'),
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
                                  title: const Text('Error'),
                                  content: const Text('Unable to verify account status. Please try again.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
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
                                  final cardColor = isProAccount ? AppColors.card(isDarkMode) : AppColors.card(isDarkMode).withOpacity(0.8);
                                  final iconGradientColors = isProAccount 
                                    ? AppColors.cardGradient(isDarkMode)
                                    : AppColors.iconContainerGradient(isDarkMode);
                                  final titleColor = isProAccount ? AppColors.textPrimary(isDarkMode) : AppColors.textPrimary(isDarkMode).withOpacity(0.5);
                                  final subtitleColor = isProAccount 
                                    ? AppColors.textSecondary(isDarkMode)
                                    : AppColors.textSecondary(isDarkMode).withOpacity(0.3);
                                  final arrowColor = isProAccount 
                                    ? AppColors.textPrimary(isDarkMode).withOpacity(0.1) 
                                    : AppColors.textPrimary(isDarkMode).withOpacity(0.05);
                                  final arrowIconColor = isProAccount 
                                    ? AppColors.textPrimary(isDarkMode) 
                                    : AppColors.textPrimary(isDarkMode).withOpacity(0.4);
                                  
                                  return Container(
                                    margin: isDesktop
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.only(right: 6, left: 8, bottom: 12),
                                    height: isDesktop ? 200 : cardHeight,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(isDesktop ? cardRadius : borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.shadow(isDarkMode).withOpacity(isProAccount ? 0.3 : 0.15),
                                          blurRadius: isProAccount ? 12 : 8,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.textPrimary(isDarkMode).withOpacity(isProAccount ? 0.1 : 0.05),
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
                                                  color: isProAccount ? AppColors.textPrimary(isDarkMode) : AppColors.textPrimary(isDarkMode).withOpacity(0.4),
                                                  size: iconSize,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (!isProAccount)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: cardPadding * 0.6, vertical: cardPadding * 0.3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6366F3).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(borderRadius * 1.2),
                                                    border: Border.all(
                                                      color: const Color(0xFF6366F3).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'PRO',
                                                    style: TextStyle(
                                                      color: const Color(0xFF6366F3),
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
                                          const Spacer(),
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
                      if (isDesktop) const SizedBox(width: 16),
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
                                margin: isDesktop
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.only(left: 6, right: 8, bottom: 12),
                                height: isDesktop ? 200 : cardHeight,
                                decoration: BoxDecoration(
                                  color: AppColors.card(isDarkMode),
                                  borderRadius: BorderRadius.circular(isDesktop ? cardRadius : borderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow(isDarkMode).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: AppColors.textPrimary(isDarkMode).withOpacity(0.1),
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
                                                colors: AppColors.cardGradient(isDarkMode),
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(borderRadius - 2),
                                            ),
                                            child: Icon(
                                              Icons.swap_horizontal_circle,
                                              color: AppColors.textPrimary(isDarkMode),
                                              size: iconSize,
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                      SizedBox(height: cardPadding),
                                      // Title
                                      Text(
                                        'Exchange Projects',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(isDarkMode),
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
                                          color: AppColors.textSecondary(isDarkMode),
                                          fontSize: subtitleFontSize,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      // Arrow button
                                      Container(
                                        width: arrowSize * 2.5,
                                        height: arrowSize * 2.5,
                                        decoration: BoxDecoration(
                                          color: AppColors.textPrimary(isDarkMode).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(arrowSize * 0.75),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.textPrimary(isDarkMode),
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
                SizedBox(height: isWide ? 44 : 32),
                Builder(builder: (_) {
                  final allCategoryData = [
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
                  ];
                  Widget buildCategoryCard(int index) {
                    final cardData = allCategoryData[index];
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
                            child: Container(
                              margin: isDesktop
                                  ? EdgeInsets.zero
                                  : EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: isWide ? 18 : 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.12),
                                    blurRadius: isWide ? 20 : 14,
                                    offset: Offset(0, isWide ? 10 : 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(cardRadius),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      cardData['image'] as String,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: isDarkMode ? const Color(0xFF1E2430) : const Color(0xFFE2E8F0),
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDarkMode
                                                  ? [const Color(0xFF242C3D), const Color(0xFF181E29)]
                                                  : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              cardData['icon'] as IconData,
                                              size: 44,
                                              color: isDarkMode ? Colors.white30 : Colors.black26,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(cardRadius),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.85),
                                            Colors.black.withValues(alpha: 0.25),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(isDesktop ? 22 : (isWide ? 28 : 20)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon above text
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              cardData['icon'] as IconData,
                                              color: Colors.white,
                                              size: isDesktop ? 24 : (isWide ? 30 : 24),
                                            ),
                                          ),
                                          const Spacer(),
                                          // Title text
                                          Text(
                                            cardData['title'] as String,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isDesktop ? 22 : (isWide ? 28 : 22),
                                              fontWeight: FontWeight.bold,
                                              height: 1.15,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  blurRadius: isWide ? 10 : 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                  }

                  if (isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.35,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: allCategoryData.length,
                        itemBuilder: (context, index) => buildCategoryCard(index),
                      ),
                    );
                  }
                  return Column(
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
                          itemBuilder: (context, index) => buildCategoryCard(index),
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
                  );
                }),
                SizedBox(height: isDesktop ? 64 : (isWide ? 32 : 24)),
              ],
            ),
            ),
            ),
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
      backgroundColor: AppColors.background(isDarkMode),
      appBar: (isDesktop || _selectedIndex == 4) ? null : AppBar(
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
                    Icon(Icons.notifications, color: AppColors.textPrimary(isDarkMode)),
                    if (hasNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
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
      drawer: isDesktop ? null : Drawer(
        child: Container(
          color: AppColors.drawer(isDarkMode),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.cardOverlay(isDarkMode),
                            backgroundImage: userImageUrl != null && userImageUrl!.isNotEmpty
                                ? NetworkImage(userImageUrl!)
                                : null,
                            child: (userImageUrl == null || userImageUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 32, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName ?? 'User',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDarkMode),
                                    fontSize: 16,
                                  ),
                                ),
                                if (userJobTitle != null && userJobTitle!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      userJobTitle!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary(isDarkMode),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  userPlan == 'Pro' ? 'Pro Member' : 'Free Member',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDarkMode),
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
                leading: Icon(Icons.home, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Home', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              Tooltip(
                message: (userPlan?.toLowerCase() == 'pro')
                    ? 'View Profile Analytics'
                    : 'Pro only feature',
                child: Opacity(
                  opacity: (userPlan?.toLowerCase() == 'pro') ? 1.0 : 0.55,
                  child: ListTile(
                    leading: Icon(Icons.analytics, color: AppColors.textPrimary(isDarkMode)),
                    title: Row(
                      children: [
                        Text('Profile Analytics', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
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
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.settings, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Settings', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.person, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Profile', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.card_membership, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Subscription', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.groups, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Communities', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
              if (_isAdmin) ...[
                Divider(color: AppColors.divider(isDarkMode), height: 1),
                ListTile(
                  leading: Icon(Icons.admin_panel_settings, color: AppColors.textPrimary(isDarkMode)),
                  title: Text('Admin • Payments', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.support_agent, color: AppColors.textPrimary(isDarkMode)),
                  title: Text('Admin • Support', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.slideshow, color: AppColors.textPrimary(isDarkMode)),
                  title: Text('Admin • Slider Images', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SliderAdminScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.image, color: AppColors.textPrimary(isDarkMode)),
                  title: Text('Admin • Popup Image', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PopupAdminScreen()),
                    );
                  },
                ),
              ],
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Exchange Projects', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ExchangeProjectsScreen(currentUserId: widget.userId)),
                  );
                },
              ),
              if (!_isAdmin) Divider(color: AppColors.divider(isDarkMode), height: 1),
              if (!_isAdmin)
              ListTile(
                leading: Icon(Icons.support_agent, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Live Support', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId') ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LiveSupportScreen(showOnlyCards: true)),
                  );
                },
              ),
              Divider(color: AppColors.divider(isDarkMode), height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.textPrimary(isDarkMode)),
                title: Text('Logout', style: TextStyle(color: AppColors.textPrimary(isDarkMode))),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.remove('userId');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: isDesktop
          ? Row(
              children: [
                _buildDesktopSidebar(isDarkMode),
                Expanded(child: pages[_selectedIndex]),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isDesktop ? null : Container(
        decoration: BoxDecoration(
          color: AppColors.bottomNav(isDarkMode),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  currentIndex: _selectedIndex,
                  isDarkMode: isDarkMode,
                  onTap: () => _onItemTapped(0),
                ),
                _buildBottomNavItem(
                  icon: Icons.card_membership_outlined,
                  activeIcon: Icons.card_membership,
                  label: 'Subscription',
                  index: 1,
                  currentIndex: _selectedIndex,
                  isDarkMode: isDarkMode,
                  onTap: () => _onItemTapped(1),
                ),
                _buildBottomNavChatItem(
                  currentIndex: _selectedIndex,
                  isDarkMode: isDarkMode,
                  userId: widget.userId,
                  onTap: () => _onItemTapped(2),
                ),
                _buildBottomNavItem(
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: 'Community',
                  index: 3,
                  currentIndex: _selectedIndex,
                  isDarkMode: isDarkMode,
                  onTap: () => _onItemTapped(3),
                ),
                _buildBottomNavProfileItem(
                  currentIndex: _selectedIndex,
                  isDarkMode: isDarkMode,
                  userImageUrl: userImageUrl,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crisp, single-render nav item — avoids BottomNavigationBar's double-render blur.
  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 20 : 0,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavChatItem({
    required int currentIndex,
    required bool isDarkMode,
    required String userId,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == 2;
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('chats')
              .snapshots(),
          builder: (context, snapshot) {
            final hasUnread = snapshot.hasData &&
                snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['hasUnread'] == true;
                });
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline, size: 24, color: color),
                    if (hasUnread)
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Chat', style: TextStyle(fontSize: 11, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: isSelected ? 20 : 0,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavProfileItem({
    required int currentIndex,
    required bool isDarkMode,
    required String? userImageUrl,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == 4;
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
    final color = isSelected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            userImageUrl != null && userImageUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? (isDarkMode ? Colors.white24 : Colors.black12)
                        : (isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                    backgroundImage: NetworkImage(userImageUrl),
                  )
                : Icon(isSelected ? Icons.person : Icons.person_outline, size: 24, color: color),
            const SizedBox(height: 2),
            Text('Profile', style: TextStyle(fontSize: 11, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 20 : 0,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(bool isDarkMode) {
    final activeColor = isDarkMode ? Colors.white : Colors.black87;
    final inactiveColor = isDarkMode ? Colors.white54 : Colors.black38;
    final sidebarBg = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final activeBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);

    Widget navItem(IconData icon, IconData activeIcon, String label, int index, {Widget? badge}) {
      final isActive = _selectedIndex == index;
      final color = isActive ? activeColor : inactiveColor;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3.5,
                    height: isActive ? 18 : 0,
                    decoration: BoxDecoration(
                      color: isActive ? (isDarkMode ? Colors.white : Colors.black87) : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isActive ? 10 : 13.5),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(isActive ? activeIcon : icon, size: 22, color: color),
                      if (badge != null) badge,
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'X360',
                      style: TextStyle(
                        color: isDarkMode ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'XCODE360',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // User info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                    backgroundImage: userImageUrl != null && userImageUrl!.isNotEmpty
                        ? NetworkImage(userImageUrl!)
                        : null,
                    child: (userImageUrl == null || userImageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 20, color: isDarkMode ? Colors.white54 : Colors.black38)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? 'User',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userPlan == 'Pro' ? 'Pro Member' : 'Free',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            // Navigation items
            navItem(Icons.home_outlined, Icons.home, 'Home', 0),
            navItem(Icons.card_membership_outlined, Icons.card_membership, 'Subscription', 1),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('chats')
                  .snapshots(),
              builder: (context, snapshot) {
                final hasUnread = snapshot.hasData &&
                    snapshot.data!.docs.any((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data?['hasUnread'] == true;
                    });
                return navItem(
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  'Chat',
                  2,
                  badge: hasUnread
                      ? Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        )
                      : null,
                );
              },
            ),
            navItem(Icons.groups_outlined, Icons.groups, 'Community', 3),
            navItem(Icons.person_outline, Icons.person, 'Profile', 4),
            const SizedBox(height: 8),
            Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            // Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('exchanges')
                    .where('status', whereIn: ['pending', 'accepted'])
                    .snapshots(),
                builder: (context, snapshot) {
                  final hasNotifications = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExchangeProjectsScreen(currentUserId: widget.userId),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(Icons.notifications_outlined, size: 22, color: inactiveColor),
                                if (hasNotifications)
                                  Positioned(
                                    right: -3,
                                    top: -3,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: inactiveColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
            const Spacer(),
            // Bottom items
            Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.06)),
            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 22, color: inactiveColor),
                        const SizedBox(width: 14),
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: inactiveColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    await prefs.remove('userId');
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (route) => false,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 22, color: inactiveColor),
                        const SizedBox(width: 14),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: inactiveColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          final messageData = messageDoc.data();
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
  static const int points = 24;
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