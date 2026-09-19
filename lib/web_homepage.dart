import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'login_signup_screen.dart';
import 'web_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// XCODE360 Web Homepage — Upwork-Inspired Layout
// ─────────────────────────────────────────────────────────────────────────────

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // Hero toggle: 0 = Developer, 1 = Agency
  int _heroTabIndex = 0;

  // How-it-works toggle: 0 = For Developers, 1 = For Agencies
  int _howItWorksTabIndex = 0;

  // Section keys for scroll-to navigation
  final _howItWorksKey = GlobalKey();
  final _categoriesKey = GlobalKey();
  final _pricingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 50;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });

  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  // ── Brand constants ──────────────────────────────────────────────────────
  static const _brandDark = Color(0xFF23272A);
  static const _brandDarkAlt = Color(0xFF1A1D21);
  static const _brandAccent = Color(0xFF3B82F6); // blue accent
  static const _brandAccentLight = Color(0xFFDBEAFE);
  static const _sectionBg = Color(0xFFF9FAFB);
  static const _cardBorder = Color(0xFFE4E7EC);
  static const _maxWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 72), // space for sticky header
                _buildHeroSection(),
                _buildStatsStrip(),
                _buildCategoryGrid(),
                _buildHowItWorks(),
                _buildTestimonials(),
                _buildCtaBanner(),
                _buildPricingComparison(),
                _buildFooter(),
              ],
            ),
          ),
          // Sticky header on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. HEADER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final sw = MediaQuery.of(context).size.width;
    final showNav = sw >= 900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isScrolled ? Colors.white.withValues(alpha: 0.97) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isScrolled ? 0.08 : 0.03),
            blurRadius: _isScrolled ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  // Logo
                  InkWell(
                    onTap: () => _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _brandDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Xcode360',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _brandDark, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (showNav)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _navLink('How it Works', () => _scrollToKey(_howItWorksKey)),
                        _navLink('Categories', () => _scrollToKey(_categoriesKey)),
                        _navLink('Pricing', () => _scrollToKey(_pricingKey)),
                      ],
                    ),
                  if (showNav) const SizedBox(width: 24),
                  // Auth buttons
                  TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: _brandDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    child: const Text('Log In'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _navigateToSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    child: const Text('Sign Up Free'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _brandDark)),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. HERO SECTION
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection() {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 960;

    final textContent = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Headline
        Text(
          'Exchange Projects.\nGrow Together.',
          style: TextStyle(
            fontSize: isDesktop ? 52 : 36,
            fontWeight: FontWeight.w800,
            color: _brandDark,
            height: 1.15,
            letterSpacing: -1.0,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Join a thriving community of developers, designers, and agencies\nexchanging projects, sharing expertise, and scaling their careers.',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 15,
            color: Colors.grey.shade600,
            height: 1.6,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Toggle tabs
        _buildHeroTabs(isDesktop),
        const SizedBox(height: 20),

        // Search bar
        _buildSearchBar(isDesktop),
      ],
    );

    // PLACEHOLDER: Hero visual (swap with real illustration)
    final heroVisual = Container(
      height: isDesktop ? 420 : 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative floating elements
          Positioned(
            top: 40,
            left: 30,
            child: _floatingIcon(Icons.code, 56),
          ),
          Positioned(
            top: 80,
            right: 50,
            child: _floatingIcon(Icons.handshake_outlined, 48),
          ),
          Positioned(
            bottom: 60,
            left: 60,
            child: _floatingIcon(Icons.groups, 44),
          ),
          Positioned(
            bottom: 40,
            right: 30,
            child: _floatingIcon(Icons.rocket_launch, 52),
          ),
          // Center label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '// PLACEHOLDER: Hero Image',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isDesktop ? 60 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 55, child: Padding(padding: const EdgeInsets.only(right: 48), child: textContent)),
                    Expanded(flex: 45, child: heroVisual),
                  ],
                )
              : Column(children: [textContent, const SizedBox(height: 40), heroVisual]),
        ),
      ),
    );
  }

  Widget _floatingIcon(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: size * 0.5),
    );
  }

  Widget _buildHeroTabs(bool isDesktop) {
    return Align(
      alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _heroTab("I'm a Developer", 0),
            _heroTab("I'm an Agency", 1),
          ],
        ),
      ),
    );
  }

  Widget _heroTab(String label, int index) {
    final active = _heroTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _heroTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? _brandDark : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    final hint = _heroTabIndex == 0
        ? 'Describe the project you want to exchange...'
        : 'Find developers for your agency project...';

    return Align(
      alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey.shade400, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: ElevatedButton(
                  onPressed: _navigateToSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. TRUSTED-BY STATS STRIP
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStatsStrip() {
    final sw = MediaQuery.of(context).size.width;
    final stats = [
      _StatItem('10,000+', 'Active Users'),
      _StatItem('5,000+', 'Projects Exchanged'),
      _StatItem('50+', 'Countries'),
      _StatItem('99.9%', 'Uptime'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _sectionBg,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: sw >= 700
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats.map((s) => _buildStatBlock(s)).toList(),
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 20,
                  children: stats.map((s) => _buildStatBlock(s)).toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(_StatItem stat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. CATEGORY GRID
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildCategoryGrid() {
    final categories = [
      _CategoryItem(Icons.phone_iphone, 'Mobile Apps Development', '1,200+ projects'),
      _CategoryItem(Icons.language, 'Web Development', '2,400+ projects'),
      _CategoryItem(Icons.brush, 'Web Designing', '980+ projects'),
      _CategoryItem(Icons.palette, 'Graphics Designing', '750+ projects'),
      _CategoryItem(Icons.campaign, 'Digital Marketing', '620+ projects'),
      _CategoryItem(Icons.business_center, 'Management', '340+ projects'),
      _CategoryItem(Icons.trending_up, 'Business', '510+ projects'),
    ];

    final sw = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (sw < 900) crossAxisCount = 2;
    if (sw < 500) crossAxisCount = 1;

    return Container(
      key: _categoriesKey,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              const Text(
                'Explore Project Categories',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Find the perfect project to exchange across every discipline',
                style: TextStyle(fontSize: 17, color: Colors.grey.shade500, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) => _buildCategoryCard(categories[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryItem cat) {
    return StatefulBuilder(builder: (context, setLocalState) {
      bool hovered = false;
      return MouseRegion(
        onEnter: (_) => setLocalState(() => hovered = true),
        onExit: (_) => setLocalState(() => hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hovered ? _brandAccent.withValues(alpha: 0.4) : _cardBorder),
            boxShadow: [
              BoxShadow(
                color: hovered ? _brandAccent.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                blurRadius: hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _brandAccentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: _brandAccent, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                cat.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _brandDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                cat.subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. HOW IT WORKS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHowItWorks() {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 900;

    final devSteps = [
      _StepItem('01', 'Create Your Profile', 'Showcase your skills, portfolio, and experience to stand out.', Icons.person_add_alt_1),
      _StepItem('02', 'Browse Projects', 'Discover projects that match your expertise and interests.', Icons.search),
      _StepItem('03', 'Connect & Exchange', 'Collaborate directly with agencies and fellow developers.', Icons.swap_horiz),
      _StepItem('04', 'Grow Together', 'Build your reputation, expand your network, and level up.', Icons.trending_up),
    ];

    final agencySteps = [
      _StepItem('01', 'Register Your Agency', 'Create your agency profile with team details and capabilities.', Icons.business),
      _StepItem('02', 'Post Your Projects', 'Share projects you need help with or want to exchange.', Icons.post_add),
      _StepItem('03', 'Find Talent', 'Browse skilled developers and agencies to collaborate with.', Icons.people_outline),
      _StepItem('04', 'Scale & Deliver', 'Grow your agency by exchanging work with trusted partners.', Icons.rocket_launch),
    ];

    final steps = _howItWorksTabIndex == 0 ? devSteps : agencySteps;

    return Container(
      key: _howItWorksKey,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: _sectionBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              const Text(
                'How Xcode360 Works',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Get started in just a few steps',
                style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Audience toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _howItWorksTab('For Developers', 0),
                    _howItWorksTab('For Agencies', 1),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Step cards
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps
                          .map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _buildStepCard(s))))
                          .toList(),
                    )
                  : Column(
                      children: steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildStepCard(s))).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howItWorksTab(String label, int index) {
    final active = _howItWorksTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _howItWorksTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _brandAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(_StepItem step) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PLACEHOLDER: step illustration area
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [_brandAccent.withValues(alpha: 0.08), _brandAccent.withValues(alpha: 0.04)],
              ),
            ),
            child: Center(child: Icon(step.icon, size: 40, color: _brandAccent.withValues(alpha: 0.6))),
          ),
          const SizedBox(height: 20),
          // Step number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _brandAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(step.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brandDark),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 6. TESTIMONIALS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildTestimonials() {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 900;

    final testimonials = [
      _TestimonialItem(
        'Honestly didn\'t expect much — signed up on a whim after a client ghosted me. Within two weeks I\'d exchanged a React Native project for a backend API build, and both shipped on time. That was seven months ago and I\'ve done 14 exchanges since.',
        'Amara Obi',
        'Freelance Mobile Developer',
        'AO',
        const Color(0xFF6366F1),
      ),
      _TestimonialItem(
        'We\'re a five-person agency in São Paulo. Our bottleneck was always UI/UX — we\'d lose bids because we couldn\'t staff designers fast enough. On Xcode360 we partnered with a design studio in Kraków, exchanged our Laravel work for their Figma-to-code, and landed three enterprise contracts in Q2 alone. The platform\'s chat could use threading, but the exchange workflow itself is solid.',
        'Lucas Ferreira',
        'Co-founder, PixelForge Studio',
        'LF',
        const Color(0xFF059669),
      ),
      _TestimonialItem(
        'Simple and effective. Swapped a Vue.js dashboard project for DevOps help migrating to AWS. Took about a week to find the right match.',
        'Priya Sharma',
        'Full-Stack Developer',
        'PS',
        const Color(0xFFDB2777),
      ),
      _TestimonialItem(
        'Last year our agency handled \$40K in exchanged project work through the platform — stuff we would have either turned down or outsourced at a loss. The verified badge actually matters; clients notice it. My only gripe is the free plan\'s 5-exchange cap, but upgrading to Pro was a no-brainer once we saw the ROI.',
        'Daniel Krueger',
        'Director, CodeBridge Agency',
        'DK',
        const Color(0xFFD97706),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              const Text(
                'What Our Community Says',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Hear from developers and agencies who are growing with Xcode360',
                style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 2 : 1,
                  childAspectRatio: isDesktop ? 2.0 : 2.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: testimonials.length,
                itemBuilder: (context, index) => _buildTestimonialCard(testimonials[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(_TestimonialItem t) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              '"${t.quote}"',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.avatarColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(t.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _brandDark)),
                  Text(t.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 7. CTA BANNER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildCtaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_brandDark, Color(0xFF3A3F47)],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Ready to Start Exchanging Projects?',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  'Join 10,000+ developers and agencies already growing together.',
                  style: TextStyle(fontSize: 17, color: Colors.grey.shade400, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _navigateToSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Get Started Free'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 8. PRICING COMPARISON
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPricingComparison() {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 800;

    return Container(
      key: _pricingKey,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: _sectionBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start free, upgrade when you\'re ready',
                style: TextStyle(fontSize: 17, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFreePlanCard()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildProPlanCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFreePlanCard(),
                        const SizedBox(height: 24),
                        _buildProPlanCard(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreePlanCard() {
    final freeFeatures = [
      _PlanFeature('5 Project Exchanges', true),
      _PlanFeature('Skill Tags', true),
      _PlanFeature('Priority Chat Visibility', true),
      _PlanFeature('Advanced Exchange Form', true),
      _PlanFeature('Skill & Country Filters', true),
      _PlanFeature('Exchange Status Tracking', true),
      _PlanFeature('Dev Rooms Access', true),
      _PlanFeature('Dedicated Support', true),
      _PlanFeature('Verified Badge', false),
      _PlanFeature('Featured Profile Listing', false),
      _PlanFeature('Profile View Analytics', false),
      _PlanFeature('Online Availability Status', false),
    ];

    return _buildPlanCard(
      title: 'Free',
      price: '\$0',
      period: '/month',
      subtitle: 'Perfect for getting started',
      features: freeFeatures,
      buttonLabel: 'Get Started',
      buttonColor: Colors.white,
      buttonTextColor: _brandDark,
      buttonBorderColor: _cardBorder,
      isPopular: false,
      accentColor: _brandDark,
    );
  }

  Widget _buildProPlanCard() {
    final proFeatures = [
      _PlanFeature('Unlimited Project Exchanges', true),
      _PlanFeature('Skill Tags', true),
      _PlanFeature('Priority Chat Visibility', true),
      _PlanFeature('Advanced Exchange Form', true),
      _PlanFeature('Skill & Country Filters', true),
      _PlanFeature('Exchange Status Tracking', true),
      _PlanFeature('Dev Rooms Access', true),
      _PlanFeature('Dedicated Support', true),
      _PlanFeature('Verified Badge', true),
      _PlanFeature('Featured Profile Listing', true),
      _PlanFeature('Profile View Analytics', true),
      _PlanFeature('Online Availability Status', true),
    ];

    return _buildPlanCard(
      title: 'Pro',
      price: '\$9.99',
      period: '/month',
      subtitle: 'For professionals who want more',
      features: proFeatures,
      buttonLabel: 'Upgrade to Pro',
      buttonColor: _brandAccent,
      buttonTextColor: Colors.white,
      buttonBorderColor: _brandAccent,
      isPopular: true,
      accentColor: _brandAccent,
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String subtitle,
    required List<_PlanFeature> features,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required Color buttonBorderColor,
    required bool isPopular,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? _brandAccent : _cardBorder, width: isPopular ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isPopular ? _brandAccent.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular badge
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _brandAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          if (isPopular) const SizedBox(height: 16),

          // Title
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: accentColor)),
          const SizedBox(height: 8),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: _brandDark, height: 1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(period, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 24),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: buttonBorderColor),
                ),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 28),

          // Divider
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 20),

          // Features list
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: f.included ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        f.included ? Icons.check : Icons.close,
                        size: 14,
                        color: f.included ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: f.included ? _brandDark : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                          decoration: f.included ? null : TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 9. FOOTER
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 768;

    final sections = [
      _FooterSection('Product', ['Features', 'Pricing', 'Categories', 'Pro Plan']),
      _FooterSection('Company', ['About', 'Blog', 'Careers', 'Press']),
      _FooterSection('Support', ['Help Center', 'Contact Us', 'System Status', 'Community']),
      _FooterSection('Legal', ['Privacy Policy', 'Terms of Service', 'Cookie Policy', 'GDPR']),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
      color: _brandDarkAlt,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              // Link columns
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + description
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                        child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Xcode360', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'The platform where developers and agencies exchange projects and grow together.',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              // Social icons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _socialIcon(Icons.language), // placeholder for Twitter/X
                                  const SizedBox(width: 12),
                                  _socialIcon(Icons.code), // placeholder for GitHub
                                  const SizedBox(width: 12),
                                  _socialIcon(Icons.work_outline), // placeholder for LinkedIn
                                  const SizedBox(width: 12),
                                  _socialIcon(Icons.camera_alt_outlined), // placeholder for Instagram
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 60),
                        // Link sections
                        ...sections.map((s) => Expanded(child: _buildFooterColumn(s))),
                      ],
                    )
                  : Column(
                      children: [
                        // Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset('assets/logo.png', width: 32, height: 32, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                  child: const Center(child: Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Xcode360', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 40,
                          runSpacing: 32,
                          children: sections.map((s) => SizedBox(width: 160, child: _buildFooterColumn(s))).toList(),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialIcon(Icons.language),
                            const SizedBox(width: 12),
                            _socialIcon(Icons.code),
                            const SizedBox(width: 12),
                            _socialIcon(Icons.work_outline),
                            const SizedBox(width: 12),
                            _socialIcon(Icons.camera_alt_outlined),
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 40),
              Divider(color: Colors.grey.shade800),
              const SizedBox(height: 20),
              Text(
                '© 2024 Xcode360. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.grey.shade400, size: 18),
    );
  }

  Widget _buildFooterColumn(_FooterSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...section.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {},
                child: Text(
                  item,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            )),
      ],
    );
  }

  // ── Navigation helpers ───────────────────────────────────────────────────
  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  void _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _navigateToSignup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginSignupScreen()));
    }
  }

  void _navigateToDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WebDashboardScreen()));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────
class _StatItem {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);
}

class _CategoryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CategoryItem(this.icon, this.title, this.subtitle);
}

class _StepItem {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  const _StepItem(this.number, this.title, this.description, this.icon);
}

class _TestimonialItem {
  final String quote;
  final String name;
  final String title;
  final String initials;
  final Color avatarColor;
  const _TestimonialItem(this.quote, this.name, this.title, this.initials, this.avatarColor);
}

class _PlanFeature {
  final String name;
  final bool included;
  const _PlanFeature(this.name, this.included);
}

class _FooterSection {
  final String title;
  final List<String> items;
  const _FooterSection(this.title, this.items);
}
