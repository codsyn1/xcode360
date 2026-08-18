import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Your AdMob Publisher ID: pub-8909088774883808
  
  // Test IDs for development
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Production IDs - Your provided ad unit ID
  static String get _bannerAdUnitId {
    return 'ca-app-pub-8909088774883808/8546251228'; // Dashboard ads
  }
  
  // Specific ad unit ID for chat screens
  static String get _chatAdUnitId {
    return 'ca-app-pub-8909088774883808/3948201092'; // Chat screens ads
  }
  
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8909088774883808/8546251228'; // Use same banner ID for now
    } else {
      return 'ca-app-pub-8909088774883808/8546251228';
    }
  }
  
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8909088774883808/8546251228'; // Use same banner ID for now
    } else {
      return 'ca-app-pub-8909088774883808/8546251228';
    }
  }

  // Use test ads in debug mode
  static String get bannerAdUnitId => _isTestMode ? _testBannerAdUnitId : _bannerAdUnitId;
  static String get interstitialAdUnitId => _isTestMode ? _testInterstitialAdUnitId : _interstitialAdUnitId;
  static String get rewardedAdUnitId => _isTestMode ? _testRewardedAdUnitId : _rewardedAdUnitId;
  
  // Chat screen ad unit ID with test/production support
  static String get chatAdUnitId => _isTestMode ? _testBannerAdUnitId : _chatAdUnitId;

  static bool get _isTestMode => false; // Production ads enabled - use your real IDs

  // Public getter to check if test mode is enabled
  static bool get isTestMode => _isTestMode;

  // Method to switch between test and production ads
  static void setTestMode(bool enabled) {
    // This would require rebuilding the app or using a state management solution
    // For now, you can manually change the _isTestMode value above
    print('📱 AdMob test mode: ${enabled ? "ENABLED" : "DISABLED"}');
  }

  // Method to get current mode info
  static String get currentMode => _isTestMode ? "Test Mode" : "Production Mode";

  // Banner Ad - Support for multiple ads
  final Map<String, BannerAd?> _bannerAds = {};
  final Map<String, bool> _isBannerAdLoaded = {};

  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob initialized successfully');
      print('📱 Mode: ${_isTestMode ? "Test Ads" : "Production Ads"}');
      print('🆔 Publisher ID: pub-8909088774883808');
      print('📊 Banner Ad Unit ID: $bannerAdUnitId');
      
      // Set test device IDs for development (optional)
      // final requestConfiguration = RequestConfiguration(
      //   testDeviceIds: ['YOUR_TEST_DEVICE_ID'],
      // );
      // MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    } catch (e) {
      print('❌ Error initializing AdMob: $e');
    }
  }

  // Create and load Banner Ad with unique key
  void createBannerAd({
    required String adKey,
    String? adUnitId,
    AdSize? adSize,
    required void Function(Ad ad) onAdLoaded,
    required void Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    required void Function(Ad ad) onAdOpened,
    required void Function(Ad ad) onAdClosed,
    required void Function(Ad ad) onAdImpression,
  }) {
    // Dispose existing ad with same key if any
    _bannerAds[adKey]?.dispose();
    
    // Use provided ad unit ID or default banner ID
    final unitId = adUnitId ?? bannerAdUnitId;
    
    _bannerAds[adKey] = BannerAd(
      adUnitId: unitId,
      size: adSize ?? AdSize.banner,
      request: const AdRequest(
        // Add extra parameters to improve ad fill
        keywords: ['technology', 'business', 'education', 'apps', 'mobile', 'social', 'networking'],
        contentUrl: 'https://play.google.com/store',
        nonPersonalizedAds: false,
      ),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _isBannerAdLoaded[adKey] = true;
          onAdLoaded(ad);
          print('✅ Banner ad loaded for key: $adKey with unit ID: $unitId');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _isBannerAdLoaded[adKey] = false;
          ad.dispose();
          _bannerAds[adKey] = null;
          onAdFailedToLoad(ad, error);
          
          // Enhanced error logging for production
          print('❌ Banner ad failed to load for key $adKey:');
          print('   Error Code: ${error.code}');
          print('   Error Domain: ${error.domain}');
          print('   Error Message: ${error.message}');
          print('   Ad Unit ID: $unitId');
          print('   Response Info: ${error.responseInfo}');
          
          // Common issues and suggestions
          if (error.code == 3) {
            print('💡 "No fill" suggestions:');
            print('   1. Wait 24-48 hours for new AdMob accounts');
            print('   2. Ensure app is linked in AdMob dashboard');
            print('   3. Add payment info to AdMob account');
            print('   4. Check if ad unit is active');
          }
        },
        onAdOpened: (Ad ad) {
          onAdOpened(ad);
          print('📱 Banner ad opened for key: $adKey');
        },
        onAdClosed: (Ad ad) {
          onAdClosed(ad);
          print('📱 Banner ad closed for key: $adKey');
        },
        onAdImpression: (Ad ad) {
          onAdImpression(ad);
          print('👁️ Banner ad impression for key: $adKey');
        },
      ),
    );
    _bannerAds[adKey]!.load();
  }

  // Get Banner Ad widget with specific key
  Widget getBannerAdWidget({required String adKey}) {
    final ad = _bannerAds[adKey];
    final isLoaded = _isBannerAdLoaded[adKey] ?? false;
    
    if (isLoaded && ad != null) {
      return SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
    }
    return const SizedBox.shrink();
  }

  // Get responsive ad size based on screen width
  AdSize getResponsiveAdSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive ad sizes based on screen width
    if (screenWidth >= 728) {
      // Tablets and large screens
      return AdSize.mediumRectangle;
    } else if (screenWidth >= 468) {
      // Large phones and small tablets
      return AdSize.largeBanner;
    } else if (screenWidth >= 320) {
      // Standard phones
      return AdSize.banner;
    } else {
      // Very small phones
      return AdSize.banner;
    }
  }

  // Load Interstitial Ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          print('✅ Interstitial ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdLoaded = false;
          print('❌ Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Show Interstitial Ad
  void showInterstitialAd({
    required void Function() onAdDismissedFullScreenContent,
    required void Function() onAdFailedToShowFullScreenContent,
  }) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          print('📱 Interstitial ad showed');
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdDismissedFullScreenContent();
          print('📱 Interstitial ad dismissed');
          // Preload next interstitial ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdFailedToShowFullScreenContent();
          print('❌ Interstitial ad failed to show: $error');
        },
      );
      _interstitialAd!.show();
    } else {
      print('⚠️ Interstitial ad not ready, loading...');
      loadInterstitialAd();
    }
  }

  // Dispose ads
  void dispose() {
    // Dispose all banner ads
    for (final ad in _bannerAds.values) {
      ad?.dispose();
    }
    _bannerAds.clear();
    _isBannerAdLoaded.clear();
    
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
  }

  // Check if ads are ready
  bool isBannerAdReady(String adKey) => _isBannerAdLoaded[adKey] ?? false;
  bool get isInterstitialAdReady => _isInterstitialAdLoaded;
  bool get isRewardedAdReady => _isRewardedAdLoaded;
}
