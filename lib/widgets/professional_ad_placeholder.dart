import 'package:flutter/material.dart';

class ProfessionalAdPlaceholder extends StatefulWidget {
  const ProfessionalAdPlaceholder({Key? key}) : super(key: key);

  @override
  State<ProfessionalAdPlaceholder> createState() => _ProfessionalAdPlaceholderState();
}

class _ProfessionalAdPlaceholderState extends State<ProfessionalAdPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLarge = screenWidth >= 728;
        final isMedium = screenWidth >= 468;
        final isSmall = screenWidth < 360; // Very small screens
        
        // Responsive height based on screen size - match the ad banner heights
        double adHeight;
        if (isSmall) {
          adHeight = 44.0; // Very small screens - match ChatAdBanner
        } else if (isMedium) {
          adHeight = 46.0; // Medium screens - match ChatAdBanner
        } else {
          adHeight = 48.0; // Large screens - match ChatAdBanner
        }
        
        final padding = isLarge ? 24.0 : isSmall ? 8.0 : 12.0;
        final iconSize = isLarge ? 20.0 : isSmall ? 12.0 : 14.0;
        final titleFontSize = isLarge ? 9.0 : isSmall ? 7.0 : 8.0;
        final subtitleFontSize = isLarge ? 6.0 : isSmall ? 5.0 : 6.0;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            child: Container(
              constraints: BoxConstraints(
                minHeight: adHeight,
                maxHeight: adHeight,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PatternPainter(),
                    ),
                  ),
                  
                  // Content with flexible layout
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated icon
                        Flexible(
                          child: AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Icon(
                                Icons.monetization_on,
                                color: Colors.white.withOpacity(0.6),
                                size: iconSize,
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: isSmall ? 1 : 2),
                        
                        // Text content with responsive sizing
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isSmall ? 'Ad' : 'Advertisement',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              if (!isSmall) ...[
                                SizedBox(height: 1),
                                Text(
                                  'Premium Position',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: subtitleFontSize,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Only show dots on larger screens
                        if (screenWidth > 500 && !isSmall) ...[
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDot(true),
                              const SizedBox(width: 2),
                              _buildDot(false),
                              const SizedBox(width: 2),
                              _buildDot(false),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 4, // Reduced size
      height: 4, // Reduced size
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.white.withOpacity(0.6)
            : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle pattern
    final dotSize = 2.0;
    final spacing = 20.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
