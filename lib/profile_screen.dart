import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_project_exchange_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'dart:async';
import 'exchange_projects_screen.dart'; // Added for Exchange Projects screen
import 'onboarding_screen.dart'; // Added for OnboardingScreen
import 'dashboard_screen.dart'; // Added for DashboardScreen
import 'users_profiles_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'features/profile/presentation/bloc/profile_cubit.dart';
import 'features/profile/presentation/bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  final String userId; // Firestore user document ID
  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _pageBg = Color(0xFF121212);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _cardBorder = Color(0xFF2D2D2D);

  int projectsExchanged = 0;
  List<Map<String, dynamic>> receivedReviews = [];
  bool reviewsLoading = true;
  String? _currentUserId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _completedExchangesSubscription;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _listenCompletedExchangesAndReviews();
    _loadCurrentUserId();
    // Force immediate server refresh
    _refreshUserDocumentFromServer();
    // Multiple refreshes to ensure latest data
    Future.delayed(Duration(milliseconds: 100), () {
      _refreshUserDocumentFromServer();
    });
    Future.delayed(Duration(milliseconds: 500), () {
      _refreshUserDocumentFromServer();
    });
    Future.delayed(Duration(seconds: 1), () {
      _refreshUserDocumentFromServer();
    });
    Future.delayed(Duration(seconds: 2), () {
      _refreshUserDocumentFromServer();
    });
  }

  @override
  void dispose() {
    _completedExchangesSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() {
        reviewsLoading = true;
        projectsExchanged = 0;
        receivedReviews = [];
      });
      _listenCompletedExchangesAndReviews();
      _loadCurrentUserId();
      // Force server refresh when switching profiles
      _refreshUserDocumentFromServer();
      Future.delayed(Duration(milliseconds: 100), () {
        _refreshUserDocumentFromServer();
      });
      Future.delayed(Duration(milliseconds: 500), () {
        _refreshUserDocumentFromServer();
      });
    }
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUserId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _refreshUserDocumentFromServer() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get(const GetOptions(source: Source.server));
    } catch (_) {
      // Keep stream active; if server is unavailable, cached data still renders.
    }
  }

  // Helper to map country name to ISO code
  String countryNameToCode(String? country) {
    if (country == null) return '';
    final map = {
      'Pakistan': 'PK',
      'India': 'IN',
      'Azerbaijan': 'AZ',
      'United States': 'US',
      'United Kingdom': 'GB',
      'Germany': 'DE',
      'France': 'FR',
      'Canada': 'CA',
      'Australia': 'AU',
      'Bangladesh': 'BD',
      'Nepal': 'NP',
      'China': 'CN',
      'Japan': 'JP',
      'Turkey': 'TR',
      'Russia': 'RU',
      'Saudi Arabia': 'SA',
      'UAE': 'AE',
      'Afghanistan': 'AF',
      'Sri Lanka': 'LK',
      'South Africa': 'ZA',
      'Brazil': 'BR',
      'Italy': 'IT',
      'Spain': 'ES',
      'Egypt': 'EG',
      'Indonesia': 'ID',
      'Malaysia': 'MY',
      'Singapore': 'SG',
      'Qatar': 'QA',
      'Kuwait': 'KW',
      'Oman': 'OM',
      'Yemen': 'YE',
      'Jordan': 'JO',
      'Iraq': 'IQ',
      'Iran': 'IR',
      'Philippines': 'PH',
      'Thailand': 'TH',
      'Vietnam': 'VN',
      'South Korea': 'KR',
      'North Korea': 'KP',
      'Sweden': 'SE',
      'Norway': 'NO',
      'Denmark': 'DK',
      'Finland': 'FI',
      'Poland': 'PL',
      'Netherlands': 'NL',
      'Belgium': 'BE',
      'Switzerland': 'CH',
      'Austria': 'AT',
      'Greece': 'GR',
      'Portugal': 'PT',
      'Mexico': 'MX',
      'Argentina': 'AR',
      'Colombia': 'CO',
      'Chile': 'CL',
      'New Zealand': 'NZ',
      // Add more as needed
    };
    if (country.length == 2) return country.toUpperCase();
    return map[country.trim()] ?? '';
  }

  // Update countryCodeToEmoji to use this mapping
  String countryCodeToEmoji(String? countryOrCode) {
    if (countryOrCode == null || countryOrCode.isEmpty) return '';
    String code = countryOrCode.trim();
    if (code.length != 2) {
      code = countryNameToCode(code);
    }
    if (code.length != 2) return '';
    code = code.toUpperCase();
    return String.fromCharCodes([
      code.codeUnitAt(0) + 127397,
      code.codeUnitAt(1) + 127397,
    ]);
  }

  void _listenCompletedExchangesAndReviews() {
    _completedExchangesSubscription?.cancel();
    _completedExchangesSubscription = FirebaseFirestore.instance
        .collection('exchanges')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      _applyCompletedExchanges(snapshot.docs);
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        reviewsLoading = false;
      });
    });
  }

  Future<void> _applyCompletedExchanges(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    int count = 0;
    List<Map<String, dynamic>> reviewsRaw = [];
    Set<String> reviewerIds = {};
    for (final doc in docs) {
      final data = doc.data();
      final fromUserId = data['fromUserId'];
      final toUserId = data['toUserId'];
      // If this user is involved in this exchange
      if (fromUserId == widget.userId || toUserId == widget.userId) {
        count++;
        // If this user is receiver, show senderReview; if sender, show receiverReview
        if (fromUserId == widget.userId && data['receiverReview'] != null) {
          // Reviewer is toUserId
          reviewerIds.add(toUserId);
          reviewsRaw.add({
            ...data['receiverReview'],
            'reviewerId': toUserId,
          });
        } else if (toUserId == widget.userId && data['senderReview'] != null) {
          // Reviewer is fromUserId
          reviewerIds.add(fromUserId);
          reviewsRaw.add({
            ...data['senderReview'],
            'reviewerId': fromUserId,
          });
        }
      }
    }
    // Batch fetch reviewer countries
    Map<String, String> reviewerIdToCountry = {};
    if (reviewerIds.isNotEmpty) {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: reviewerIds.toList())
          .get();
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        reviewerIdToCountry[doc.id] =
            data['countryCode'] ?? data['country'] ?? '';
      }
    }
    // Build reviews with country
    List<Map<String, dynamic>> reviews = reviewsRaw.map((review) {
      final reviewerId = review['reviewerId'];
      return {
        ...review,
        'reviewerCountry': reviewerIdToCountry[reviewerId] ?? '',
      };
    }).toList();
    if (!mounted) return;
    setState(() {
      projectsExchanged = count;
      receivedReviews = reviews;
      reviewsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isSmallScreen = screenHeight < 700;
    
    return BlocProvider(
      create: (_) => ProfileCubit(),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(includeMetadataChanges: true),
        builder: (context, userSnapshot) {
          // Always try to get latest data
          if (userSnapshot.hasData) {
            if (userSnapshot.data!.metadata.isFromCache) {
              // Data is from cache, force server refresh
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _refreshUserDocumentFromServer();
              });
            }
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(
                child: Text('User not found',
                    style: TextStyle(color: Colors.white)));
          }
          final String name =
              (userData['fullName'] ?? userData['name'] ?? 'User').toString();
          final String _imageUrlRaw =
              (userData['profileImageUrl'] ?? '').toString();
          final String _coverImageUrlRaw =
              (userData['coverImageUrl'] ?? '').toString();
          final String imageUrl = _imageUrlRaw.trim().toLowerCase() == 'null'
              ? ''
              : _imageUrlRaw.trim();
          final String coverImageUrl =
              _coverImageUrlRaw.trim().toLowerCase() == 'null'
                  ? ''
                  : _coverImageUrlRaw.trim();
          final String bio = (userData['bio'] ?? '').toString();
          final String website = (userData['website'] ?? '').toString();
          final List<String> skills = userData['skills'] is List
              ? List<String>.from(userData['skills'])
              : <String>[];
          final String country = (userData['country'] ?? '').toString();
          final String city = (userData['city'] ?? '').toString();
          final String plan = (userData['plan'] ?? '').toString();
          final bool isOnline = (userData['onlineStatus'] ?? false) == true;
          final isOwnProfile = _currentUserId != null &&
              _currentUserId!.isNotEmpty &&
              userSnapshot.data!.id == _currentUserId;
          print(
              'DEBUG: widget.userId=${widget.userId}, firestoreId=${userSnapshot.data!.id}, isOwnProfile=$isOwnProfile');
          final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
          return Scaffold(
            backgroundColor: isDarkMode ? _pageBg : const Color(0xFFF2F2F7),
            appBar: AppBar(
              backgroundColor: isDarkMode ? _pageBg : const Color(0xFFF2F2F7),
              elevation: 0,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId') ?? '';
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => DashboardScreen(userId: userId)),
                    (route) => false,
                  );
                },
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, size: isSmallScreen ? 20 : 24),
                  tooltip: 'Sign Out',
                  onPressed: () async {
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
            drawer: AppDrawer(userId: widget.userId),
            body: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - (isSmallScreen ? 100 : 120),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopHeader(
                      isWide: isWide,
                      isSmallScreen: isSmallScreen,
                      name: name,
                      city: city,
                      country: country,
                      imageUrl: imageUrl,
                      coverImageUrl: coverImageUrl,
                      isOnline: isOnline,
                      isOwnProfile: isOwnProfile,
                      isPro: plan.toLowerCase() == 'pro',
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 28 : 16,
                        isSmallScreen ? 8 : 16,
                        isWide ? 28 : 16,
                        isSmallScreen ? 16 : 24,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showSideBySide = constraints.maxWidth >= 900;
                          final sidePanel = _buildProfileSidePanel(
                            context: context,
                            country: country,
                            city: city,
                            plan: plan,
                            projectsExchanged: projectsExchanged,
                            reviewsLoading: reviewsLoading,
                            skills: skills,
                            isSmallScreen: isSmallScreen,
                          );
                          final mainPanel = _buildProfileMainPanel(
                            context: context,
                            name: name,
                            bio: bio,
                            website: website,
                            plan: plan,
                            isOwnProfile: isOwnProfile,
                            isSmallScreen: isSmallScreen,
                          );
                          final reviewsPanel = _buildReviewsSection(
                            receivedReviews: receivedReviews,
                            reviewsLoading: reviewsLoading,
                            isSmallScreen: isSmallScreen,
                          );

                          if (!showSideBySide) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                mainPanel,
                                SizedBox(height: isSmallScreen ? 8 : 16),
                                sidePanel,
                                SizedBox(height: isSmallScreen ? 8 : 16),
                                reviewsPanel,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: mainPanel),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    sidePanel,
                                    reviewsPanel,
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader({
    required bool isWide,
    required bool isSmallScreen,
    required String name,
    required String city,
    required String country,
    required String imageUrl,
    required String coverImageUrl,
    required bool isOnline,
    required bool isOwnProfile,
    required bool isPro,
  }) {
    final coverHeight = isWide ? 220.0 : (isSmallScreen ? 120.0 : 170.0);
    final avatarRadius = isWide ? 52.0 : (isSmallScreen ? 32.0 : 44.0);
    final dotSize = avatarRadius * 0.45;
    final dotLeft = -dotSize * 0.10;
    final dotTop = avatarRadius * 0.06;
    final locationLabel = [
      if (city.trim().isNotEmpty) city.trim(),
      if (country.trim().isNotEmpty) country.trim(),
    ].join(', ');
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: coverHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14213D), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: coverImageUrl.isEmpty
                  ? null
                  : Image.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isWide ? 28 : 16,
            isSmallScreen ? 8 : 16,
            isWide ? 28 : 16,
            isSmallScreen ? 8 : 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF242424),
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: isSmallScreen ? 24 : 40,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: isSmallScreen ? 24 : 40,
                            ),
                    ),
                  ),
                  if (isPro)
                    Positioned(
                      left: dotLeft,
                      top: dotTop,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF34D399)
                              : const Color(0xFF6B7280),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF121212),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8, 
                        vertical: 3
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _computeLevelLabel(projectsExchanged),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: avatarRadius * 0.25, // Increased from 0.15 to 0.25
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isSmallScreen ? 8 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isWide ? 36 : (isSmallScreen ? 16 : 22),
                            ),
                          ),
                        ),
                        if (isPro) ...[
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Icon(
                            Icons.verified,
                            color: Color(0xFF14A800),
                            size: isSmallScreen ? 16 : 20,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: isSmallScreen ? 14 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Expanded(
                          child: Text(
                            locationLabel.isEmpty
                                ? 'Location not set'
                                : locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: isSmallScreen ? 13 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            color: Colors.white38, size: isSmallScreen ? 14 : 18),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          _formatLocalTimeLabel(),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: isSmallScreen ? 13 : 15,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 12),
                    if (isPro)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 14,
                          vertical: isSmallScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                Icons.bolt,
                                size: isSmallScreen ? 14 : 16,
                                color: Colors.white,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              isOnline ? 'Available' : 'Offline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Only show toggle for own profile
                            if (isOwnProfile) ...[
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              GestureDetector(
                                onTap: () {
                                  // Show confirmation dialog for online/offline status
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF232323),
                                      title: Text(
                                        isOnline ? 'Go Offline' : 'Go Online',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        isOnline 
                                            ? 'Are you sure you want to go offline? Other users will see you as unavailable.'
                                            : 'Are you sure you want to go online? Other users will see you as available.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(ctx).pop();
                                            // Update Firestore to toggle online status
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(widget.userId)
                                                .update({'onlineStatus': !isOnline});
                                          },
                                          child: Text(
                                            isOnline ? 'Go Offline' : 'Available',
                                            style: TextStyle(color: isOnline ? Colors.orange : Colors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isOnline ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    isOnline ? Icons.circle : Icons.circle_outlined,
                                    size: isSmallScreen ? 20 : 24,
                                    color: isOnline ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLocalTimeLabel() {
    final now = DateTime.now();
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period local time';
  }

  String _computeLevelLabel(int projectsExchanged) {
    if (projectsExchanged >= 1000) return 'X360 Top Rated';
    if (projectsExchanged >= 500) return 'Level 3';
    if (projectsExchanged >= 50) return 'Level 2';
    return 'Level 1';
  }

  Widget _buildProfileMainPanel({
    required BuildContext context,
    required String name,
    required String bio,
    required String website,
    required String plan,
    required bool isOwnProfile,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isOwnProfile)
          Column(
            children: [
              Row(
                children: [
                  // Chat button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14A800),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.chat, size: isSmallScreen ? 18 : 20),
                      label: Text(
                        'Chat',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatProjectExchangeScreen(
                              currentUserId: _currentUserId ?? '',
                              profileUserId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 4), // Small gap between buttons
                  // Hire Me button (only for Pro users)
                  if (plan.toLowerCase() == 'pro') ...[
                    Expanded(
                      child: BlocBuilder<ProfileCubit, ProfileState>(
                        buildWhen: (p, c) => p.showComingSoon != c.showComingSoon,
                        builder: (context, pState) {
                          return OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF3A3A3A)),
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12, horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(
                              pState.showComingSoon
                                    ? Icons.hourglass_bottom
                                    : Icons.work_outline,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            label: Text(
                              pState.showComingSoon
                                    ? 'Coming Soon'
                                    : 'Hire Me',
                              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            ),
                            onPressed: () =>
                                context.read<ProfileCubit>().onHireMePressed(),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
            SizedBox(height: isSmallScreen ? 16 : 20), // Add spacing between buttons and Overview
          _sectionCard(
            title: 'Overview',
            child: Text(
              bio.isEmpty ? '$name has not added an overview yet.' : bio,
              style: TextStyle(
                color: Colors.white70,
                height: 1.45,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            isSmallScreen: isSmallScreen,
          ),
        if (website.isNotEmpty)
          _sectionCard(
            title: 'Portfolio Link',
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 10, 
                vertical: isSmallScreen ? 7 : 9
              ),
              decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(color: _cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () async {
                  final url =
                      website.startsWith('http') ? website : 'https://$website';
                  final uri = Uri.parse(url);
                  try {
                    final launched = await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open the website.')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open the website.')),
                      );
                    }
                  }
                },
                child: Text(
                  website,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            isSmallScreen: isSmallScreen,
          ),
      ],
    );
  }

  Widget _buildProfileSidePanel({
    required BuildContext context,
    required String country,
    required String city,
    required String plan,
    required int projectsExchanged,
    required bool reviewsLoading,
    required List<String> skills,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          title: 'Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Country', country.isEmpty ? '-' : country, isSmallScreen),
              _statRow('City', city.isEmpty ? '-' : city, isSmallScreen),
              _statRow('Plan', plan.isEmpty ? '-' : plan, isSmallScreen),
              _statRow(
                'Projects Exchanged',
                reviewsLoading ? '...' : '$projectsExchanged',
                isSmallScreen,
              ),
            ],
          ),
          isSmallScreen: isSmallScreen,
        ),
        _sectionCard(
          title: 'Skills',
          child: skills.isEmpty
              ? Text(
                  'No skills added yet.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills
                      .map(
                        (skill) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10, 
                              vertical: isSmallScreen ? 5 : 7
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildReviewsSection({
    required List<Map<String, dynamic>> receivedReviews,
    required bool reviewsLoading,
    required bool isSmallScreen,
  }) {
    return _sectionCard(
      title: 'Reviews',
      child: reviewsLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                child: const CircularProgressIndicator(color: Color(0xFF14A800)),
              ),
            )
          : receivedReviews.isEmpty
              ? Text(
                  'No reviews yet.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                )
              : Column(
                  children: receivedReviews.map((review) {
                    final rating = (review['rating'] ?? 0).toInt();
                    final comment = (review['comment'] ?? '').toString();
                    final reviewerCountry =
                        (review['reviewerCountry'] ?? '').toString();
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 10),
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (reviewerCountry.isNotEmpty)
                                Text(
                                  countryCodeToEmoji(reviewerCountry),
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
                                ),
                              if (reviewerCountry.isNotEmpty)
                                SizedBox(width: isSmallScreen ? 6 : 8),
                              if (reviewerCountry.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    reviewerCountry,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFF59E0B),
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                          if (comment.isNotEmpty) ...[
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              comment,
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
      isSmallScreen: isSmallScreen,
    );
  }

  Widget _sectionCard({
    required String title, 
    required Widget child,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          child,
        ],
      ),
    );
  }

  Widget _statRow(String title, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String userId;
  const AppDrawer({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.blueGrey[900],
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final name = (data?['fullName'] ?? data?['name'] ?? 'User')
                        .toString();
                    final email = (data?['email'] ?? '').toString();
                    final imageUrl =
                        (data?['profileImageUrl'] ?? '').toString();
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('XCODE360',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1.1)),
                              const SizedBox(height: 4),
                              Text(name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if (email.isNotEmpty)
                                Text(email,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UsersProfilesScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Communities'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        CommunityScreen(userId: userId, showAppBar: true)),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Close the drawer first, then navigate in the next frame
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Exchange Projects'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ExchangeProjectsScreen(currentUserId: userId)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('userId');
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/onboarding', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
