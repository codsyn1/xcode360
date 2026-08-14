import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'support_chat_screen.dart';

void main() => runApp(const LiveSupportScreen());

class LiveSupportScreen extends StatelessWidget {
  final bool showOnlyCards;
  const LiveSupportScreen({Key? key, this.showOnlyCards = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId') ?? '';
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => DashboardScreen(userId: userId)),
                (route) => false,
              );
            },
          ),
          title: Text('Live Support', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F7),
          elevation: 0,
        ),
        backgroundColor: isDarkMode ? Colors.black12 : const Color(0xFFF2F2F7),
        body: _SupportCards(
          onCardTap: (category) async {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('userId') ?? '';
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SupportChatScreen(userId: userId, category: category),
              ),
            );
          },
        ),
      ),

    );
  }
}
class _SupportCards extends StatelessWidget {
  final Function(String category) onCardTap;
  const _SupportCards({required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final isMobile = screenWidth < 400;
    final cardRadius = isWide ? 32.0 : 22.0;
    final iconSize = isWide ? 48.0 : 32.0;
    final titleFont = isWide ? 20.0 : 16.0;
    final subtitleFont = isWide ? 14.0 : 11.0;
    final List<Map<String, dynamic>> cards = [
      {'title': 'Live Chat', 'icon': Icons.support_agent, 'subtitle': 'Instant help from our team'},
      {'title': 'General Inquiries', 'icon': Icons.info_outline, 'subtitle': 'Ask anything general'},
      {'title': 'Technical Issues', 'icon': Icons.build, 'subtitle': 'Get tech help'},
      {'title': 'Account & Profile', 'icon': Icons.person_outline, 'subtitle': 'Profile/account support'},
      {'title': 'Payments & Billing', 'icon': Icons.payment, 'subtitle': 'Payment & billing help'},
      {'title': 'Exchange Order Support', 'icon': Icons.swap_horiz, 'subtitle': 'Order & exchange help'},
      {'title': 'Report a User', 'icon': Icons.report, 'subtitle': 'Report inappropriate user'},
      {'title': 'Privacy & Security', 'icon': Icons.security, 'subtitle': 'Privacy & security info'},
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : isMobile ? 4 : 12, vertical: isWide ? 32 : isMobile ? 4 : 12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: isWide ? 28 : isMobile ? 8 : 16,
          crossAxisSpacing: isWide ? 28 : isMobile ? 8 : 16,
          childAspectRatio: isWide ? 1.5 : isMobile ? 0.85 : 1.05,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return _AnimatedCard(
            onTap: () => onCardTap(card['title']),
            cardRadius: cardRadius,
            icon: card['icon'],
            iconSize: iconSize,
            title: card['title'],
            subtitle: card['subtitle'],
            titleFont: titleFont,
            subtitleFont: subtitleFont,
          );
        },
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final VoidCallback onTap;
  final double cardRadius;
  final IconData icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final double titleFont;
  final double subtitleFont;
  const _AnimatedCard({
    required this.onTap,
    required this.cardRadius,
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.subtitle,
    required this.titleFont,
    required this.subtitleFont,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF353535), Color(0xFF232323)],
            ),
            borderRadius: BorderRadius.circular(widget.cardRadius),
            border: Border.all(color: Colors.white12, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.cardRadius * 0.5, vertical: widget.cardRadius * 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(widget.cardRadius * 0.6),
                  ),
                  padding: EdgeInsets.all(widget.cardRadius * 0.38),
                  child: Icon(widget.icon, color: Colors.white, size: widget.iconSize),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.titleFont,
                      height: 1.1,
                      overflow: TextOverflow.ellipsis,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 7),
                Flexible(
                  child: Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: widget.subtitleFont,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF3A3A3A),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}