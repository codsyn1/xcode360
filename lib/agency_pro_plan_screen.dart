import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'subscription_screen.dart';
import 'agency_screen.dart';
import 'agency_payment_page.dart';
import 'agency_options_screen.dart';

class AgencyProPlanScreen extends StatefulWidget {
  final String userId;
  const AgencyProPlanScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AgencyProPlanScreen> createState() => _AgencyProPlanScreenState();
}

class _AgencyProPlanScreenState extends State<AgencyProPlanScreen> with SingleTickerProviderStateMixin {
  String? userPlan;
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
    _fetchUserPlan();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _showProPlanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Upgrade to Pro Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Get unlimited access to all agencies and unlock premium features like exchange requests, priority support, and advanced collaboration tools.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white70)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          'Agency Pro Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                            color: Colors.blue,
                            size: isWide ? 48 : 40,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connect with Top Agencies',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWide ? 28 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upgrade to Pro Plan to unlock unlimited access to premium agencies and start collaborating on amazing projects.',
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
                    
                    // Pro Plan Features
                    _buildFeatureCard(
                      'Unlimited Messaging',
                      'Chat with any agency without restrictions',
                      Icons.chat,
                      Colors.blue,
                      isWide,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureCard(
                      'Send Exchange Requests',
                      'Propose projects and collaborate with agencies',
                      Icons.swap_horiz,
                      Colors.green,
                      isWide,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureCard(
                      'Priority Support',
                      'Get faster responses from agencies',
                      Icons.priority_high,
                      Colors.orange,
                      isWide,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureCard(
                      'Advanced Tools',
                      'Access premium collaboration features',
                      Icons.build,
                      Colors.purple,
                      isWide,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: isWide ? 56 : 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AgencyPaymentPage(userId: widget.userId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                          ),
                        ),
                        child: const Text(
                          'Upgrade to Agency Pro Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: isWide ? 56 : 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AgencyScreen(userId: widget.userId),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2C2C2C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                          ),
                        ),
                        child: const Text(
                          'Browse Agencies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(isWide ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWide ? 16 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isWide ? 16 : 12),
            ),
            child: Icon(icon, color: color, size: isWide ? 28 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWide ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
