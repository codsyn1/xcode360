import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/web_layout.dart';
import '../login_screen.dart';
import '../login_signup_screen.dart';
import '../web_dashboard_screen.dart';
import '../features/splash/presentation/bloc/splash_cubit.dart';
import '../features/splash/presentation/bloc/splash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeader(),
            _buildHeroSection(),
            _buildFeaturesSection(),
            _buildHowItWorksSection(),
            _buildStatsSection(),
            _buildCTASection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _isScrolled ? Colors.white.withOpacity(0.95) : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'X360',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Xcode360',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23272A),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Navigation
            if (MediaQuery.of(context).size.width > 768) ...[
              Row(
                children: [
                  _buildNavItem('How it Works', () {}),
                  _buildNavItem('Features', () {}),
                  _buildNavItem('Pricing', () {}),
                  _buildNavItem('About', () {}),
                ],
              ),
            ],
            
            const SizedBox(width: 24),
            
            // CTA Buttons
            Row(
              children: [
                WebButton(
                  text: 'Log In',
                  onPressed: () => _navigateToLogin(),
                  backgroundColor: Colors.transparent,
                  textColor: const Color(0xFF23272A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                const SizedBox(width: 12),
                WebButton(
                  text: 'Sign Up',
                  onPressed: () => _navigateToSignup(),
                  backgroundColor: const Color(0xFF23272A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF23272A),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text(
            'Connect. Collaborate. Create.',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 768 ? 56 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF23272A),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Join thousands of developers and agencies exchanging projects and growing their careers on Xcode360',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 768 ? 20 : 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WebButton(
                text: 'Start as Developer',
                onPressed: () => _navigateToDashboard(),
                backgroundColor: const Color(0xFF23272A),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                width: 200,
              ),
              const SizedBox(width: 20),
              WebButton(
                text: 'Join as Agency',
                onPressed: () => _navigateToDashboard(),
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                width: 200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(80),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text(
            'Why Choose Xcode360?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23272A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'The complete platform for project exchange and professional growth',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ResponsiveGrid(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                Icons.swap_horiz,
                'Project Exchange',
                'Exchange projects with developers and agencies worldwide',
              ),
              _buildFeatureCard(
                Icons.people,
                'Talent Network',
                'Connect with verified professionals and grow your network',
              ),
              _buildFeatureCard(
                Icons.verified,
                'Verified Profiles',
                'All profiles are verified to ensure quality and trust',
              ),
              _buildFeatureCard(
                Icons.chat,
                'Real-time Chat',
                'Communicate instantly with built-in messaging system',
              ),
              _buildFeatureCard(
                Icons.trending_up,
                'Career Growth',
                'Build your portfolio and advance your career',
              ),
              _buildFeatureCard(
                Icons.support_agent,
                '24/7 Support',
                'Get help whenever you need it from our support team',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return WebCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xFF23272A),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF23272A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.all(80),
      child: Column(
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23272A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ResponsiveGrid(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            children: [
              _buildStepCard('1', 'Create Profile', 'Sign up and build your professional profile'),
              _buildStepCard('2', 'Browse Projects', 'Find interesting projects to work on'),
              _buildStepCard('3', 'Connect & Exchange', 'Collaborate with other professionals'),
              _buildStepCard('4', 'Grow Together', 'Build your portfolio and career'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String step, String title, String description) {
    return WebCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF23272A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF23272A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(80),
      color: const Color(0xFF23272A),
      child: Column(
        children: [
          const Text(
            'Join Our Growing Community',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ResponsiveGrid(
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('10,000+', 'Active Users', Icons.people),
              _buildStatCard('5,000+', 'Projects Exchanged', Icons.swap_horiz),
              _buildStatCard('50+', 'Countries', Icons.public),
              _buildStatCard('99.9%', 'Uptime', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCTASection() {
    return Container(
      padding: const EdgeInsets.all(80),
      child: Column(
        children: [
          const Text(
            'Ready to Get Started?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23272A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Join thousands of professionals already using Xcode360',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          WebButton(
            text: 'Get Started Now',
            onPressed: () => _navigateToDashboard(),
            backgroundColor: const Color(0xFF23272A),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            width: 250,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF23272A),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterSection('Product', ['Features', 'Pricing', 'Use Cases']),
              _buildFooterSection('Company', ['About', 'Blog', 'Careers']),
              _buildFooterSection('Support', ['Help Center', 'Contact', 'Status']),
              _buildFooterSection('Legal', ['Privacy', 'Terms', 'Cookies']),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© 2024 Xcode360. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            item,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }

  void _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToSignup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
      );
    }
  }

  void _navigateToDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebDashboardScreen()),
      );
    }
  }
}
