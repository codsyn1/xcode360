import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgencyUpgradeProScreen extends StatefulWidget {
  final String userId;
  final String agencyId;

  const AgencyUpgradeProScreen({
    Key? key,
    required this.userId,
    required this.agencyId,
  }) : super(key: key);

  @override
  State<AgencyUpgradeProScreen> createState() => _AgencyUpgradeProScreenState();
}

class _AgencyUpgradeProScreenState extends State<AgencyUpgradeProScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isLoading = false;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _upgradeToPro() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Update user plan to Pro
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'plan': 'Pro'});

      // Update agency plan to Pro
      await FirebaseFirestore.instance
          .collection('agencies')
          .doc(widget.agencyId)
          .update({'plan': 'Pro'});

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully upgraded to Pro!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to dashboard
      Navigator.of(context).pop();

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upgrading: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isWide ? 32 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFD700).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isWide ? 24 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: isWide ? 80 : 60,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Go Pro',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isWide ? 32 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock premium features for your agency',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: isWide ? 18 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Features Section
              Text(
                'Pro Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildFeatureCard(
                'Unlimited Projects',
                'Post and manage unlimited projects without any restrictions',
                Icons.all_inclusive,
                isWide,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                'Priority Support',
                'Get 24/7 priority customer support for faster resolutions',
                Icons.support_agent,
                isWide,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                'Advanced Analytics',
                'Detailed insights and analytics for your agency performance',
                Icons.analytics,
                isWide,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                'Custom Branding',
                'Customize your agency profile with advanced branding options',
                Icons.palette,
                isWide,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                'Direct Client Access',
                'Connect directly with high-value clients and projects',
                Icons.people,
                isWide,
              ),

              const SizedBox(height: 32),

              // Pricing Section
              Container(
                width: double.infinity,
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
                    Text(
                      'Pricing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWide ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isWide ? 16 : 14,
                              ),
                            ),
                            Text(
                              '\$29.99',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: isWide ? 28 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yearly',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isWide ? 16 : 14,
                              ),
                            ),
                            Text(
                              '\$299.99',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: isWide ? 28 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Save 17%',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: isWide ? 60 : 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _upgradeToPro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                    ),
                  ),
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Upgrade to Pro Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(isWide ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 60 : 50,
            height: isWide ? 60 : 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(isWide ? 16 : 12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: isWide ? 30 : 24,
            ),
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
                    height: 1.4,
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
