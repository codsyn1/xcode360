import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'users_profiles_screen.dart';
import 'dart:ui';
import 'dart:async'; // Added for Timer
import 'dashboard_screen.dart';
import 'subscription_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryImage;
  final String userId;
  SubcategoriesScreen({
    Key? key, 
    required this.categoryTitle, 
    required this.categoryImage,
    required this.userId,
  }) : super(key: key);

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  int? _tappedIndex;
  int _selectedSliderIndex = 0;
  int _currentImageIndex = 0;
  int _selectedIndex = 0;
  final _verticalScrollController = ScrollController();
  final _sliderController = ScrollController();
  final PageController _imagePageController = PageController();
  Timer? _sliderTimer; // Added for auto-scroll

  List<String> get _sliderImages => subcategories.map((s) => s['image'] as String).toList();

  List<Map<String, dynamic>> get subcategories => _getSubcategories();

  List<Map<String, dynamic>> _getSubcategories() {
    switch (widget.categoryTitle) {
      case 'Mobile Apps\nDevelopment':
        return [
          {
            'title': 'iOS Development',
            'description': 'Swift, SwiftUI, UIKit',
            'icon': Icons.phone_iphone,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Android Development',
            'description': 'Kotlin, Java, Jetpack Compose',
            'icon': Icons.phone_android,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Cross-Platform',
            'description': 'Flutter, React Native, Xamarin',
            'icon': Icons.devices,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Mobile UI/UX',
            'description': 'Mobile Design Patterns',
            'icon': Icons.design_services,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Web\nDevelopment':
        return [
          {
            'title': 'Frontend Development',
            'description': 'React, Vue, Angular',
            'icon': Icons.web,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Backend Development',
            'description': 'Node.js, Python, PHP',
            'icon': Icons.storage,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Full Stack Development',
            'description': 'MERN, MEAN, LAMP',
            'icon': Icons.layers,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Database Design',
            'description': 'SQL, NoSQL, MongoDB',
            'icon': Icons.storage,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Web\nDesigning':
        return [
          {
            'title': 'UI/UX Design',
            'description': 'User Interface & Experience',
            'icon': Icons.design_services,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Responsive Design',
            'description': 'Mobile-First Approach',
            'icon': Icons.phone_android,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Wireframing',
            'description': 'Figma, Adobe XD, Sketch',
            'icon': Icons.draw,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Prototyping',
            'description': 'Interactive Prototypes',
            'icon': Icons.touch_app,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Graphics\nDesigning':
        return [
          {
            'title': 'Logo Design',
            'description': 'Brand Identity',
            'icon': Icons.brush,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Illustration',
            'description': 'Digital Art & Drawings',
            'icon': Icons.palette,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Print Design',
            'description': 'Brochures, Flyers, Posters',
            'icon': Icons.print,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Photo Editing',
            'description': 'Photoshop, Lightroom',
            'icon': Icons.camera_alt,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Digital\nMarketing':
        return [
          {
            'title': 'Social Media Marketing',
            'description': 'Facebook, Instagram, LinkedIn',
            'icon': Icons.share,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'SEO Optimization',
            'description': 'Search Engine Optimization',
            'icon': Icons.search,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Content Marketing',
            'description': 'Blogs, Videos, Infographics',
            'icon': Icons.article,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Email Marketing',
            'description': 'Newsletters, Campaigns',
            'icon': Icons.email,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Management':
        return [
          {
            'title': 'Project Management',
            'description': 'Agile, Scrum, Kanban',
            'icon': Icons.assignment,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Team Leadership',
            'description': 'Team Building & Motivation',
            'icon': Icons.people,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Product Management',
            'description': 'Product Strategy & Roadmap',
            'icon': Icons.inventory,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Business Analysis',
            'description': 'Requirements & Analysis',
            'icon': Icons.analytics,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'AI & Machine\nLearning':
        return [
          {
            'title': 'Machine Learning',
            'description': 'Python, TensorFlow, PyTorch',
            'icon': Icons.psychology,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Deep Learning',
            'description': 'Neural Networks, CNN, RNN',
            'icon': Icons.memory,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Data Science',
            'description': 'Pandas, NumPy, Scikit-learn',
            'icon': Icons.analytics,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Computer Vision',
            'description': 'OpenCV, Image Processing',
            'icon': Icons.visibility,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      case 'Business':
        return [
          {
            'title': 'Business Strategy',
            'description': 'Strategic Planning & Analysis',
            'icon': Icons.trending_up,
            'color': Colors.blue,
            'image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Entrepreneurship',
            'description': 'Startup Development',
            'icon': Icons.rocket_launch,
            'color': Colors.green,
            'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Finance & Accounting',
            'description': 'Financial Management',
            'icon': Icons.account_balance,
            'color': Colors.purple,
            'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
          },
          {
            'title': 'Marketing Strategy',
            'description': 'Business Marketing',
            'icon': Icons.campaign,
            'color': Colors.orange,
            'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
          },
        ];
      
      default:
        return [];
    }
  }

  void _onCardTap(BuildContext context, int index, bool down) {
    if (down) {
      setState(() => _tappedIndex = index);
    } else {
      setState(() => _tappedIndex = null);
    }
  }

  void _onSliderTap(int index) {
    setState(() => _selectedSliderIndex = index);
    // Scroll vertical timeline to the selected subcategory
    final itemExtent = 120.0; // Approximate height of each timeline item
    _verticalScrollController.animateTo(
      index * itemExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_imagePageController.hasClients && subcategories.isNotEmpty) {
        int nextPage = (_currentImageIndex + 1) % subcategories.length;
        _imagePageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _sliderController.dispose();
    _imagePageController.dispose();
    _sliderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        title: Text(widget.categoryTitle.replaceAll('\n', ' ')),
      ),
      body: Column(
        children: [
          // Unique horizontal slider
          SizedBox(
            height: isWide ? 220 : 140,
            child: ListView.separated(
              controller: _sliderController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: isWide ? 18 : 10),
              itemCount: subcategories.length,
              separatorBuilder: (context, idx) => SizedBox(width: isWide ? 24 : 14),
              itemBuilder: (context, idx) {
                final sub = subcategories[idx];
                final selected = idx == _selectedSliderIndex;
                return GestureDetector(
                  onTap: () => _onSliderTap(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: isWide ? 340 : 260,
                    height: isWide ? 200 : 120,
                    margin: EdgeInsets.symmetric(vertical: isWide ? 8 : 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(isWide ? 32 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: isWide ? 18 : 10,
                          offset: Offset(0, isWide ? 8 : 4),
                        ),
                      ],
                      border: selected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isWide ? 18 : 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              sub['icon'],
                              color: Colors.white,
                              size: isWide ? 48 : 32,
                            ),
                          ),
                          SizedBox(height: isWide ? 18 : 10),
                          Text(
                            sub['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isWide ? 18 : 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Vertical timeline (expanded)
          Expanded(
            child: ListView.builder(
              controller: _verticalScrollController,
              padding: const EdgeInsets.only(top: 18, bottom: 32, left: 0, right: 0),
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UsersProfilesScreen(
                            subcategory: subcategory['title'] as String,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      width: isWide ? 420 : MediaQuery.of(context).size.width * 0.94,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2C2C2C),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                        border: _selectedSliderIndex == index
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              subcategory['icon'],
                              color: Colors.white,
                              size: isWide ? 32 : 26,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subcategory['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subcategory['description'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF232323),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen(userId: widget.userId, selectedIndex: idx)),
            (route) => false,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: 'Subscription',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showSubcategoryDetails(BuildContext context, Map<String, dynamic> subcategory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: subcategory['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                subcategory['icon'],
                color: subcategory['color'],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subcategory['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subcategory['description'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: subcategory['color'],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // Here you can navigate to a specific screen for this subcategory
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${subcategory['title']}...'),
                      backgroundColor: subcategory['color'],
                    ),
                  );
                },
                child: const Text(
                  'Explore This Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 