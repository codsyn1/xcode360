import 'package:flutter/material.dart';
import 'group_chat_screen.dart';

class DepartmentListScreen extends StatelessWidget {
  final String userId;
  const DepartmentListScreen({Key? key, required this.userId}) : super(key: key);

  static final List<Map<String, dynamic>> departments = [
    {
      'title': 'Mobile Apps\nDevelopment',
      'icon': Icons.phone_iphone,
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'AI Services',
      'icon': Icons.psychology,
      'image': 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Web\nDevelopment',
      'icon': Icons.code,
      'image': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Web\nDesigning',
      'icon': Icons.design_services,
      'image': 'https://images.unsplash.com/photo-1503676382389-4809596d5290?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Graphics\nDesigning',
      'icon': Icons.brush,
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Digital\nMarketing',
      'icon': Icons.trending_up,
      'image': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Management',
      'icon': Icons.people,
      'image': 'https://images.unsplash.com/photo-1521737852567-6949f3f9f2b5?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Business',
      'icon': Icons.business,
      'image': 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final cardRadius = isWide ? 32.0 : 22.0;
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Select Department'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 0.85,
          ),
          itemCount: departments.length,
          itemBuilder: (context, index) {
            final dept = departments[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      userId: userId,
                      department: dept['title'],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      dept['image'],
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cardRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              dept['icon'],
                              color: Colors.white,
                              size: isWide ? 32 : 28,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            dept['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWide ? 24 : 18,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
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
            );
          },
        ),
      ),
    );
  }
} 