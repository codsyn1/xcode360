import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import 'professional_ad_placeholder.dart';

class DashboardAdBanner extends StatefulWidget {
  const DashboardAdBanner({Key? key}) : super(key: key);

  @override
  State<DashboardAdBanner> createState() => _DashboardAdBannerState();
}

class _DashboardAdBannerState extends State<DashboardAdBanner> {
  final AdMobService _adMobService = AdMobService();
  bool _isAdLoaded = false;
  bool _adFailed = false;
  AdSize? _adSize;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeAd();
      
      // For test ads, also try a quick refresh after 2 seconds if not loaded
      if (AdMobService.isTestMode) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isAdLoaded && !_adFailed) {
            print('🔄 Quick refresh for test ad...');
            _initializeAd();
          }
        });
      }
    }
  }

  void _initializeAd() {
    // Get responsive ad size based on screen width
    _adSize = _adMobService.getResponsiveAdSize(context);
    
    print('📱 Initializing Dashboard Ad Banner in ${AdMobService.currentMode}');
    print('📱 Using Ad Unit ID: ${AdMobService.bannerAdUnitId}');
    
    _adMobService.createBannerAd(
      adKey: 'dashboard_banner',
      adUnitId: AdMobService.bannerAdUnitId, // Use service ad unit ID for test/production
      adSize: _adSize,
      onAdLoaded: (Ad ad) {
        setState(() {
          _isAdLoaded = true;
          _adFailed = false;
        });
        print('✅ Dashboard banner ad loaded successfully');
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        print('❌ Dashboard banner ad failed to load: $error');
        ad.dispose();
        setState(() {
          _adFailed = true;
        });
        
        // Retry loading after delay
        _retryLoadAd();
      },
      onAdOpened: (Ad ad) {
        print('📱 Dashboard banner ad opened');
      },
      onAdClosed: (Ad ad) {
        print('📱 Dashboard banner ad closed');
      },
      onAdImpression: (Ad ad) {
        print('👁️ Dashboard banner ad impression');
      },
    );
  }
  
  void _retryLoadAd() {
    // Retry after 30 seconds for test ads (they should load immediately)
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _adFailed) {
        print('🔄 Retrying to load dashboard banner ad...');
        setState(() {
          _adFailed = false;
        });
        _initializeAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmall = screenWidth < 360;
        final isMedium = screenWidth < 600;
        
        // Responsive height based on screen size
        double adHeight;
        if (isSmall) {
          adHeight = 44.0; // Very small screens - reduced from 48
        } else if (isMedium) {
          adHeight = 46.0; // Medium screens - reduced from 52
        } else {
          adHeight = 48.0; // Large screens - reduced from 56
        }
        
        if (_isAdLoaded) {
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
                color: Colors.white,
                child: _adMobService.getBannerAdWidget(adKey: 'dashboard_banner'),
              ),
            ),
          );
        }
        
        if (_adFailed) {
          return const ProfessionalAdPlaceholder();
        }
        
        // Loading state
        return _buildLoadingPlaceholder(adHeight, isSmall);
      },
    );
  }

  // Build loading placeholder while ad is loading
  Widget _buildLoadingPlaceholder(double adHeight, bool isSmall) {
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
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isSmall ? 12 : 16,
                  height: isSmall ? 12 : 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6)),
                  ),
                ),
                SizedBox(height: isSmall ? 2 : 4),
                Text(
                  'Loading Ad...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: isSmall ? 8 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build placeholder widget when ad fails to load
  Widget _buildAdPlaceholder() {
    final adHeight = _adSize?.height.toDouble() ?? 50.0;
    
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 4),
      height: adHeight + 8,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.ad_units,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                'Ad Space',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the service here as it might be used elsewhere
    super.dispose();
  }
}
