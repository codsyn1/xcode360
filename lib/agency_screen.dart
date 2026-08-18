import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/profile_analytics/presentation/bloc/analytics_access_cubit.dart';
import 'chat_project_exchange_screen.dart';
import 'subscription_screen.dart';
import 'agency_profile_screen.dart';
import 'agency_bottom_navigation.dart';

class AgencyScreen extends StatefulWidget {
  final String userId;
  const AgencyScreen({super.key, required this.userId});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _agencies = [];
  String? userPlan;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? selectedCountry;
  List<String> availableCountries = ['All']; // Will be populated dynamically

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchUserPlan();
    _loadAvailableCountries();
    _testFirestoreConnection(); // Test connection
    _animationController.forward();
  }

  Future<void> _loadAvailableCountries() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .where('isActive', isEqualTo: true)
          .get();
      
      Set<String> countries = {'All'};
      for (var doc in snapshot.docs) {
        String? country = doc['country'] as String?;
        if (country != null && country.isNotEmpty) {
          countries.add(country);
        }
      }
      
      setState(() {
        availableCountries = countries.toList()..sort();
      });
    } catch (e) {
      print('Error loading countries: $e');
    }
  }

  void _showCountryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Allow modal to be scrollable
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Filter by Country',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search Field
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setModalState(() {}); // Rebuild modal to filter countries
                },
              ),
              const SizedBox(height: 16),
              
              // Countries List
              Expanded(
                child: ListView.builder(
                  itemCount: availableCountries.length,
                  itemBuilder: (context, index) {
                    final country = availableCountries[index];
                    final isSelected = selectedCountry == country;
                    
                    // Filter countries based on search
                    if (_searchController.text.isNotEmpty &&
                        !country.toLowerCase().contains(_searchController.text.toLowerCase())) {
                      return const SizedBox.shrink(); // Hide non-matching countries
                    }
                    
                    return ListTile(
                      title: Text(
                        country,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFFFFD700))
                          : null,
                      onTap: () {
                        setState(() {
                          selectedCountry = country == 'All' ? null : country;
                        });
                        _searchController.clear(); // Clear search
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getAgenciesStream() {
    Query query = FirebaseFirestore.instance
        .collection('agencies')
        .where('isActive', isEqualTo: true);
    
    if (selectedCountry != null && selectedCountry!.isNotEmpty) {
      query = query.where('country', isEqualTo: selectedCountry);
    }
    
    return query.snapshots();
  }

  Future<void> _testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      QuerySnapshot testSnapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .limit(1)
          .get();
      
      print('Firestore connection successful! Found ${testSnapshot.docs.length} test agencies');
      
      if (testSnapshot.docs.isNotEmpty) {
        final testData = testSnapshot.docs.first.data() as Map<String, dynamic>;
        print('Test agency data: ${testData.keys}');
        print('Test agency name: ${testData['name']}');
        print('Test agency logo: ${testData['logoUrl']}');
      }
      
      // If no agencies exist, create a test one
      if (testSnapshot.docs.isEmpty) {
        print('No agencies found, creating test agency...');
        await _createTestAgency();
      }
      
      // Also try to get all agencies without filtering
      print('Testing all agencies fetch...');
      QuerySnapshot allAgencies = await FirebaseFirestore.instance
          .collection('agencies')
          .get();
      print('Total agencies in Firestore: ${allAgencies.docs.length}');
      
      for (var doc in allAgencies.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Agency: ${data['name']}, Active: ${data['isActive']}');
      }
      
    } catch (e) {
      print('Firestore connection error: $e');
    }
  }

  Future<void> _createTestAgency() async {
    try {
      Map<String, dynamic> testAgency = {
        'name': 'Test Agency',
        'description': 'This is a test agency for debugging',
        'contact': '+1234567890',
        'email': 'test@agency.com',
        'website': 'https://testagency.com',
        'location': 'Test City',
        'experience': '5+ years of experience',
        'services': ['Web Development', 'Mobile Apps'],
        'ownerId': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'rating': 4.5,
        'totalProjects': 10,
      };
      
      await FirebaseFirestore.instance.collection('agencies').add(testAgency);
      print('Test agency created successfully!');
    } catch (e) {
      print('Error creating test agency: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  Future<void> _fetchUserPlan() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      setState(() {
        userPlan = userDoc['plan'] ?? 'Free';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userPlan = 'Free';
        isLoading = false;
      });
    }
  }

  String _getCountryFlag(String country) {
    switch (country) {
      case 'US':
        return '🇺🇸';
      case 'PK':
        return '🇵🇰';
      case 'IN':
        return '🇮🇳';
      case 'GB':
        return '🇬🇧';
      case 'CA':
        return '🇨🇦';
      case 'AU':
        return '🇦🇺';
      case 'DE':
        return '🇩🇪';
      case 'FR':
        return '🇫🇷';
      case 'IT':
        return '🇮🇹';
      case 'ES':
        return '🇪🇸';
      case 'JP':
        return '🇯🇵';
      case 'CN':
        return '🇨🇳';
      case 'BR':
        return '🇧🇷';
      case 'RU':
        return '🇷🇺';
      case 'KR':
        return '🇰🇷';
      case 'MX':
        return '🇲🇽';
      case 'AR':
        return '🇦🇷';
      case 'SA':
        return '🇸🇦';
      case 'AE':
        return '🇦🇪';
      case 'NL':
        return '🇳🇱';
      case 'BE':
        return '🇧🇪';
      case 'CH':
        return '🇨🇭';
      case 'AT':
        return '🇦🇹';
      case 'SE':
        return '🇸🇪';
      case 'NO':
        return '🇳🇴';
      case 'DK':
        return '🇩🇰';
      case 'FI':
        return '🇫🇮';
      case 'PL':
        return '🇵🇱';
      case 'TR':
        return '🇹🇷';
      case 'EG':
        return '🇪🇬';
      case 'ZA':
        return '🇿🇦';
      case 'NG':
        return '🇳🇬';
      case 'KE':
        return '🇰🇪';
      case 'TH':
        return '🇹🇭';
      case 'MY':
        return '🇲🇾';
      case 'SG':
        return '🇸🇬';
      case 'HK':
        return '🇭🇰';
      case 'TW':
        return '🇹🇼';
      case 'IL':
        return '🇮🇱';
      case 'NZ':
        return '🇳🇿';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Agencies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showCountryFilter,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAgenciesStream(),
        builder: (context, snapshot) {
          print('StreamBuilder state: ${snapshot.connectionState}');
          print('StreamBuilder hasError: ${snapshot.hasError}');
          print('StreamBuilder error: ${snapshot.error}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: isWide ? 80 : 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading agencies',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 20 : 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isWide ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh the stream
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final agencies = snapshot.data?.docs ?? [];
          print('Found ${agencies.length} agencies in snapshot');
          
          if (agencies.isEmpty) {
            print('No agencies found, showing empty state');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_center,
                    color: Colors.white54,
                    size: isWide ? 80 : 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No agencies found',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isWide ? 20 : 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create an agency!',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: isWide ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }
          
          print('Building agency cards for ${agencies.length} agencies');
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.only(
                left: isWide ? 32 : 16,
                right: isWide ? 32 : 16,
                top: isWide ? 24 : 16,
                bottom: isWide ? 120 : 100, // Add bottom padding for footer
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: isWide ? 20 : 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.2 : 1.4,
                ),
                itemCount: agencies.length,
                itemBuilder: (context, index) {
                  final agency = agencies[index];
                  final agencyData = agency.data() as Map<String, dynamic>;
                  
                  print('Building agency card for: ${agencyData['name'] ?? 'Unknown'}');
                  print('Agency data keys: ${agencyData.keys}');
                  
                  return _buildAgencyCard(agency, agencyData, isWide);
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AgencyBottomNavigation(
        userId: widget.userId,
        agencyId: 'default', // You can pass actual agency ID if needed
        currentIndex: 0, // Home is selected
      ),
    );
  }

  Widget _buildAgencyCard(DocumentSnapshot agency, Map<String, dynamic> agencyData, bool isWide) {
    final agencyName = agencyData['name'] ?? 'Unknown Agency';
    final agencyDescription = agencyData['description'] ?? '';
    final agencyLogo = agencyData['logoUrl'] ?? '';
    final agencyCover = agencyData['coverUrl'] ?? '';
    final agencyRating = (agencyData['rating'] ?? 0.0).toDouble();
    final totalProjects = agencyData['totalProjects'] ?? 0;
    final country = agencyData['country'] ?? '';
    
    print('Building card for agency: $agencyName');
    print('Logo URL: $agencyLogo');
    print('Cover URL: $agencyCover');
    print('Document ID: ${agency.id}');
    
    return GestureDetector(
      onTap: () {
        print('Tapped on agency: $agencyName');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AgencyProfileScreen(
              userId: widget.userId,
              agencyId: agency.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(isWide ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agency Cover Photo as Background with Logo Overlay
            SizedBox(
              height: isWide ? 180 : 120,
              child: Stack(
                children: [
                  // Cover Photo Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isWide ? 20 : 16),
                        topRight: Radius.circular(isWide ? 20 : 16),
                      ),
                    ),
                    child: agencyCover.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isWide ? 20 : 16),
                              topRight: Radius.circular(isWide ? 20 : 16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: agencyCover,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF2C2C2C),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                print('Error loading cover: $error');
                                return Container(
                                  color: const Color(0xFF2C2C2C),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.white54,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                              memCacheWidth: isWide ? 400 : 300,
                              memCacheHeight: isWide ? 200 : 150,
                            ),
                          )
                        : Container(
                            color: const Color(0xFF2C2C2C),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                  // Logo Overlay
                  Positioned(
                    bottom: 25,
                    left: 10,
                    child: Container(
                      width: isWide ? 70 : 60,
                      height: isWide ? 70 : 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: agencyLogo.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: agencyLogo,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF2C2C2C),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Color(0xFF2C2C2C)),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  print('Error loading logo: $error');
                                  return Container(
                                    color: const Color(0xFF2C2C2C),
                                    child: const Icon(
                                      Icons.business,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                  );
                                },
                                memCacheWidth: 100,
                                memCacheHeight: 100,
                              )
                            : Container(
                                color: const Color(0xFF2C2C2C),
                                child: const Icon(
                                  Icons.business,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Agency Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 20 : 16,
                  right: isWide ? 20 : 16,
                  top: isWide ? 30 : 25,
                  bottom: isWide ? 20 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agencyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (country.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCountryFlag(country),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              country,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      agencyDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Rating and Projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating Tab - only show if rating > 0.0
                        if (agencyRating > 0.0) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                agencyRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Projects Tab - only show if totalProjects > 0
                        if (totalProjects > 0) ...[
                          Text(
                            '$totalProjects projects',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
