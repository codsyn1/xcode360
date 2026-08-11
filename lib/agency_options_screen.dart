import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agency_pro_plan_screen.dart';
import 'create_agency_profile_screen.dart';

class AgencyOptionsScreen extends StatefulWidget {
  final String userId;
  const AgencyOptionsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AgencyOptionsScreen> createState() => _AgencyOptionsScreenState();
}

class _AgencyOptionsScreenState extends State<AgencyOptionsScreen> with SingleTickerProviderStateMixin {
  bool hasAgencyProfile = false;
  String? userAgencyId;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _checkUserAgencyProfile();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserAgencyProfile() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerId', isEqualTo: widget.userId)
          .get();
      
      setState(() {
        hasAgencyProfile = snapshot.docs.isNotEmpty;
        if (hasAgencyProfile) {
          userAgencyId = snapshot.docs.first.id;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
          'Agency Options',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: isWide ? 24 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isWide ? 32 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [const Color(0xFF0A0A0A), const Color(0xFF060606)],
                        ),
                        borderRadius: BorderRadius.circular(isWide ? 24 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.business_center,
                            color: const Color(0xFFFFD700),
                            size: isWide ? 48 : 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Choose Your Path',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWide ? 28 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasAgencyProfile 
                                ? 'Manage your agency or explore other agencies'
                                : 'Browse agencies or create your own agency profile',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isWide ? 16 : 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Options Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: isWide ? 20 : 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.2 : 1.4,
                      children: [
                        _buildOptionCard(
                          'Browse Agencies',
                          'Explore different agencies and collaborate on projects',
                          Icons.explore,
                          const Color(0xFFFFD700),
                          isWide,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AgencyProPlanScreen(userId: widget.userId),
                            ),
                          ),
                        ),
                        if (hasAgencyProfile)
                          _buildOptionCard(
                            'My Agency',
                            'Manage and edit your agency profile',
                            Icons.business,
                            const Color(0xFFFFD700),
                            isWide,
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateAgencyProfileScreen(
                                  userId: widget.userId,
                                  isEditing: true,
                                  agencyId: userAgencyId!,
                                ),
                              ),
                            ),
                          )
                        else
                          _buildOptionCard(
                            'Create Agency',
                            'Build your agency profile and attract clients',
                            Icons.add_business,
                            const Color(0xFFFFD700),
                            isWide,
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateAgencyProfileScreen(
                                  userId: widget.userId,
                                  isEditing: false,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOptionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isWide,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isWide ? 24 : 20),
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
            Container(
              padding: EdgeInsets.all(isWide ? 16 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(isWide ? 16 : 12),
              ),
              child: Icon(icon, color: color, size: isWide ? 32 : 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWide ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isWide ? 14 : 12,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(isWide ? 12 : 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: color,
                    size: isWide ? 20 : 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
