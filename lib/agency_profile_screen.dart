import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'agency_chat_screen.dart';
import 'create_agency_profile_screen.dart';

class AgencyProfileScreen extends StatefulWidget {
  final String userId;
  final String agencyId;
  const AgencyProfileScreen({Key? key, required this.userId, required this.agencyId}) : super(key: key);

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> with SingleTickerProviderStateMixin {
  DocumentSnapshot? agencyData;
  bool isLoading = true;
  bool isOwner = false; // Track if current user owns this agency
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
    _animationController.forward();
    _fetchAgencyData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgencyData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('agencies')
          .doc(widget.agencyId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        
        setState(() {
          agencyData = doc;
          isLoading = false;
          isOwner = ownerId == widget.userId; // Check if current user owns this agency
        });
      } else {
        setState(() {
          agencyData = null;
          isLoading = false;
          isOwner = false;
        });
      }
    } catch (e) {
      setState(() {
        agencyData = null;
        isLoading = false;
      });
    }
  }

  void _startChat() async {
    if (agencyData == null) return;
    
    try {
      final agencyId = widget.agencyId;
      final agencyName = agencyData!['name'] ?? 'Unknown Agency';
      final agencyLogo = agencyData!['logoUrl'];
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgencyChatScreen(
            currentUserId: widget.userId,
            agencyId: agencyId,
            agencyName: agencyName,
            agencyLogo: agencyLogo,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _launchUrl(String url) async {
    try {
      // Ensure URL has proper format
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      
      final Uri uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch URL: $formattedUrl'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching URL: $e'),
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
          'Agency Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Only show "View as Admin" button if user owns this agency
          if (isOwner)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateAgencyProfileScreen(
                      userId: widget.userId,
                      isEditing: true,
                      agencyId: widget.agencyId,
                      isAdmin: true, // Admin mode
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
              label: const Text(
                'View as Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : agencyData == null
                    ? const Center(
                        child: Text(
                          'Agency not found',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 32 :16,
                            vertical: isWide ? 24 :16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover Image and Logo
                              _buildHeaderSection(isWide),
                              
                              const SizedBox(height: 16),
                              
                              // Start Chat Button
                              _buildActionButtons(isWide),
                              
                              const SizedBox(height: 24),
                              
                              // Agency Name and Description
                              _buildBasicInfo(isWide),
                              
                              const SizedBox(height: 24),
                              
                              // Services
                              if (agencyData!['services'] != null && 
                                  (agencyData!['services'] as List).isNotEmpty) ...[
                                _buildServicesSection(isWide),
                                const SizedBox(height: 24),
                              ],
                              
                              // Experience
                              if (agencyData!['experience'] != null && 
                                  agencyData!['experience'].toString().isNotEmpty) ...[
                                _buildExperienceSection(isWide),
                                const SizedBox(height: 24),
                              ],
                              
                              // Ratings & Reviews
                              _buildRatingsSection(isWide),
                              const SizedBox(height: 24),
                              
                              const SizedBox(height: 100), // Space for bottom navigation
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isWide) {
    final coverUrl = agencyData!['coverUrl'];
    final logoUrl = agencyData!['logoUrl'];
    
    return Container(
      height: isWide ? 200 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isWide ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cover Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isWide ? 20 : 16),
              color: const Color(0xFF2C2C2C),
            ),
            child: coverUrl != null && coverUrl.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF2C2C2C),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2C2C2C),
                        child: const Icon(Icons.image, color: Colors.white, size: 50),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF2C2C2C),
                    child: const Icon(Icons.business, color: Colors.white, size: 50),
                  ),
          ),
          
          // Logo
          Positioned(
            bottom: 20,
            left: isWide ? 32 : 16,
            child: Container(
              width: isWide ? 70 : 60,
              height: isWide ? 70 : 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: logoUrl != null && logoUrl.toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.business,
                          color: Colors.white54,
                        ),
                      )
                    : const Icon(Icons.business, color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(bool isWide) {
    final name = agencyData!['name'] ?? 'Unknown Agency';
    final description = agencyData!['description'] ?? '';
    final country = agencyData!['country'] ?? '';
    
    return Container(
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
          const SizedBox(height: 20), // Space for logo
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (country.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 4),
                Text(
                  _getCountryFlag(country),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  country,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWide ? 18 : 16,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isWide ? 16 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(bool isWide) {
    final contact = agencyData!['contact'] ?? '';
    final email = agencyData!['email'] ?? '';
    final website = agencyData!['website'] ?? '';
    
    return Container(
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
            'Contact Information',
            style: TextStyle(
              color: Colors.white, 
              fontSize: isWide ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (contact.isNotEmpty)
            _buildContactItem(Icons.phone, contact, () {
              // Launch phone dialer
            }),
          if (email.isNotEmpty)
            _buildContactItem(Icons.email, email, () {
              // Launch email
            }),
          if (website.isNotEmpty)
            _buildContactItem(Icons.language, website, () {
              _launchUrl(website);
            }),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(bool isWide) {
    final services = List<String>.from(agencyData!['services'] ?? []);
    final predefinedServices = [
      'Web Development', 'Mobile Apps', 'UI/UX Design', 'Digital Marketing', 
      'SEO Services', 'Content Writing', 'Graphic Design', 'Video Production',
      'Social Media Marketing', 'E-commerce Solutions', 'Cloud Services',
      'Data Analytics', 'AI/ML Solutions', 'Blockchain Development'
    ];
    
    // Separate custom and predefined services
    final customServices = services.where((service) => !predefinedServices.contains(service)).toList();
    final selectedPredefinedServices = services.where((service) => predefinedServices.contains(service)).toList();
    
    return Container(
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
            'Services Offered',
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: isWide ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Predefined services
          if (selectedPredefinedServices.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedPredefinedServices.map((service) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  service,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
          
          // Custom services
          if (customServices.isNotEmpty) ...[
            if (selectedPredefinedServices.isNotEmpty) const SizedBox(height: 16),
            Text(
              'Specialized Services',
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: isWide ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customServices.map((service) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF757575),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFD700),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceSection(bool isWide) {
    final experience = agencyData!['experience'] ?? '';
    
    return Container(
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
            'Experience',
            style: TextStyle(
              color: Colors.white, // Changed to light black/white
              fontSize: isWide ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            experience,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isWide ? 16 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection(bool isWide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchanges')
          .where('receiverId', isEqualTo: widget.agencyId)
          .where('receiverReview', isNotEqualTo: null)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Don't show card while loading
        }
        
        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return const SizedBox.shrink(); // Don't show card if no reviews
        }

        // Calculate average rating
        double totalRating = 0;
        int reviewCount = 0;
        for (var doc in reviews) {
          final review = doc.data() as Map<String, dynamic>?;
          final receiverReview = review?['receiverReview'];
          if (receiverReview != null) {
            totalRating += (receiverReview['rating'] ?? 0).toDouble();
            reviewCount++;
          }
        }
        final averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

        // Show card only when reviews exist
        return Container(
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
                'Ratings & Reviews',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Average rating display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '⭐',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($reviewCount reviews)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Recent reviews
              ...reviews.map((doc) {
                final review = doc.data() as Map<String, dynamic>?;
                final receiverReview = review?['receiverReview'];
                if (receiverReview == null) return const SizedBox.shrink();
                
                final rating = receiverReview['rating'] ?? 0;
                final comment = receiverReview['comment'] ?? '';
                final country = receiverReview['country'] ?? 'US';
                final timestamp = receiverReview['timestamp'] as Timestamp?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getCountryFlag(country),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RatingBarIndicator(
                              rating: rating.toDouble(),
                              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 16.0,
                              direction: Axis.horizontal,
                            ),
                          ),
                          Text(
                            _formatReviewDate(timestamp?.toDate()),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          comment,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  String _getCountryFlag(String country) {
    switch (country) {
      case 'US': return '🇺🇸';
      case 'PK': return '🇵🇰';
      case 'IN': return '🇮🇳';
      case 'GB': return '🇬🇧';
      case 'CA': return '🇨🇦';
      case 'AU': return '🇦🇺';
      case 'DE': return '🇩🇪';
      case 'FR': return '🇫🇷';
      case 'JP': return '🇯🇵';
      case 'KR': return '🇰🇷';
      case 'CN': return '🇨🇳';
      case 'BR': return '🇧🇷';
      case 'RU': return '🇷🇺';
      case 'SA': return '🇸🇦';
      case 'AE': return '🇦🇪';
      default: return '';
    }
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActionButtons(bool isWide) {
    final website = agencyData!['website'] ?? '';
    
    return Row(
      children: [
        // Start Chat Button
        Expanded(
          child: GestureDetector(
            onTap: _startChat,
            child: Container(
              height: isWide ? 56 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(isWide ? 16 : 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Website Button
        Expanded(
          child: GestureDetector(
            onTap: website.isNotEmpty ? () => _launchUrl(website) : () {},
            child: Container(
              height: isWide ? 56 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(isWide ? 16 : 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Visit Website',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
