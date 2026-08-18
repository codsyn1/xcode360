import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'web_homepage.dart';
import 'subscription_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'payment_screen.dart';
import 'users_profiles_screen.dart';
import 'admin_password_utility.dart';
import 'features/splash/presentation/bloc/splash_cubit.dart';
import 'core/app/app_cubit.dart';
import 'theme_cubit.dart';
import 'core/navigation/navigation_cubit.dart';
import 'web_dashboard_screen.dart';
import 'services/notification_service.dart';
import 'services/auto_notification_permission.dart';
import 'services/admob_service.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("=== BACKGROUND MESSAGE HANDLER ===");
  print("Message ID: ${message.messageId}");
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Data: ${message.data}");
  
  // CRITICAL: Background notification debugging
  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getString('userId');
  final toUserId = message.data['toUserId'];
  final fromUserId = message.data['fromUserId'];
  
  print("🔥 === BACKGROUND NOTIFICATION DEBUG START ===");
  print("📱 CURRENT USER: $currentUserId");
  print("📨 MESSAGE TO USER: $toUserId");
  print("📤 MESSAGE FROM USER: $fromUserId");
  print("📝 MESSAGE TITLE: ${message.notification?.title}");
  print("📝 MESSAGE BODY: ${message.notification?.body}");
  print("📊 MESSAGE DATA: ${message.data}");
  
  // CRITICAL: Determine if current user should receive notification
  bool shouldShowNotification = false;
  String notificationReason = '';
  
  if (toUserId == currentUserId) {
    shouldShowNotification = true;
    notificationReason = "USER IS RECEIVER - SHOW BACKGROUND NOTIFICATION";
    print("✅ $notificationReason");
  } else if (fromUserId == currentUserId) {
    // FOR SAME DEVICE TESTING: Allow sender to see notification
    shouldShowNotification = true;
    notificationReason = "USER IS SENDER - ALLOWING FOR SAME DEVICE TESTING";
    print("⚠️ $notificationReason");
  } else {
    shouldShowNotification = false;
    notificationReason = "USER IS NEITHER SENDER NOR RECEIVER";
    print("❌ $notificationReason");
    print("🚫 NOT SHOWING BACKGROUND NOTIFICATION");
    print("🔥 === BACKGROUND NOTIFICATION DEBUG END ===");
    return; // Don't show notification
  }
  
  print("🎯 FINAL DECISION: $notificationReason");
  print("📱 SHOWING BACKGROUND NOTIFICATION: $shouldShowNotification");
  
  // Show notification when app is in background or terminated
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'xcode360_channel',
        'XCODE360 Notifications',
        channelDescription: 'Notifications from XCODE360 app',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  // Include message data in payload for navigation on tap
  final notificationPayload = jsonEncode({
    'type': message.data['type'] ?? 'chat_message',
    'fromUserId': message.data['fromUserId'],
    'fromUserName': message.data['fromUserName'],
    'toUserId': message.data['toUserId'],
  });

  // Use FCM notification title/body if available, otherwise use data
  final notificationTitle = message.notification?.title ?? 
                           message.data['title'] ?? 
                           'New Message';
  final notificationBody = message.notification?.body ?? 
                          message.data['body'] ?? 
                          'You have a new message';
  
  await flutterLocalNotificationsPlugin.show(
    id: message.hashCode,
    title: notificationTitle,
    body: notificationBody,
    payload: notificationPayload,
    notificationDetails: platformChannelSpecifics,
  );
  
  print("✅ BACKGROUND NOTIFICATION SHOWN");
  print("🔥 === BACKGROUND NOTIFICATION DEBUG END ===");
  
  print("=============================");
}

/// Use silent auto-grant notification permissions on Android
Future<void> _autoGrantNotificationPermissions() async {
  if (Platform.isAndroid) {
    try {
      print("🔐 Attempting silent notification permission grant...");
      
      // Try silent permission grant first
      final granted = await AutoNotificationPermission.grantPermissionSilently();
      
      if (granted) {
        print("✅ Notification permission granted silently");
      } else {
        print("⚠️ Silent grant failed, trying force enable...");
        
        // Try force enable as fallback
        final forceEnabled = await AutoNotificationPermission.forceEnableNotifications();
        
        if (forceEnabled) {
          print("✅ Notifications force enabled successfully");
        } else {
          print("⚠️ Force enable failed, checking current status...");
          
          // Check current permission status
          final isGranted = await AutoNotificationPermission.isPermissionGranted();
          if (isGranted) {
            print("✅ Permission already available");
          } else {
            print("⚠️ Permission not available, but app will continue");
          }
        }
      }
      
      // Small delay to allow permission processing
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      print("❌ Error in silent permission handling: $e");
      print("⚠️ App will continue without guaranteed notifications");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first - wait for completion
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Start the app
  runApp(const MyApp());
  
  // Initialize services after app starts
  _initializeServices();
}

Future<void> _initializeServices() async {
  print('🔥 === STARTING SERVICE INITIALIZATION ===');
  
  // Auto-grant notification permissions without dialog
  await _autoGrantNotificationPermissions();

  // Firebase Messaging Token & Permission Request
  if (!kIsWeb) {
    print("🔥 === INITIALIZING FIREBASE MESSAGING ===");
    
    // Check network connectivity first
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("❌ NO INTERNET CONNECTION - Push notifications will not work");
        print("⚠️ Offline notifications will still be stored locally");
      } else {
        print("✅ Internet connection available - ${connectivityResult.toString()}");
      }
    } catch (e) {
      print("❌ Error checking connectivity: $e");
    }
    
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      print("🔔 Requesting notification permissions...");
      // Request notification permissions - CRITICAL for reliable notifications
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print("Permission status: ${settings.authorizationStatus}");
      print("Alert: ${settings.alert}");
      print("Badge: ${settings.badge}");
      print("Sound: ${settings.sound}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("✅ Notification permissions granted");
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print("⚠️ Provisional notification permissions granted");
      } else {
        print("❌ Notification permissions denied - notifications may not work");
      }

      print("🔍 Getting FCM token...");
      // Get and print FCM token
      String? token = await messaging.getToken();
      
      if (token != null) {
        print("✅ FCM Token Generated Successfully:");
        print("🔑 Token: $token");
        print("📱 Platform: Android");
        print("=====================================");
        
        // Store FCM token for logged-in user if exists
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          print("🔥 USER IS LOGGED IN - STORING FCM TOKEN IN _initializeServices");
          print("🔥 USER ID: $userId");
          print("🔥 FCM TOKEN: $token");
          await NotificationService().storeUserToken(userId);
        } else {
          print("🔥 NO USER LOGGED IN - FCM TOKEN WILL BE STORED ON LOGIN");
        }
      } else {
        print("❌ FCM Token is NULL - Check Firebase configuration");
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        print("🔄 FCM Token Refreshed: $newToken");
        // Store refreshed token for logged-in user
        SharedPreferences.getInstance().then((prefs) {
          final userId = prefs.getString('userId');
          if (userId != null && userId.isNotEmpty) {
            NotificationService().storeUserToken(userId);
          }
        });
      });

      // Check if app can receive messages and handle terminated state
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print("� === APP OPENED FROM TERMINATED STATE ===");
        print("� App opened from terminated state via notification");
        print("Message ID: ${initialMessage.messageId}");
        print("Title: ${initialMessage.notification?.title}");
        print("Body: ${initialMessage.notification?.body}");
        print("Data: ${initialMessage.data}");
        
        // Handle navigation when app is opened from terminated state
        if (initialMessage.data['type'] == 'chat_message') {
          print("📱 This is a chat message notification from terminated state");
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');
          final fromUserId = initialMessage.data['fromUserId'];
          final fromUserName = initialMessage.data['fromUserName'];
          
          print("📤 From User ID: $fromUserId");
          print("📤 From User Name: $fromUserName");
          print("📱 Current User ID: $currentUserId");
          
          if (currentUserId != null && fromUserId != null) {
            // Store navigation data for later use
            await prefs.setString('pending_notification_type', 'chat_message');
            await prefs.setString('pending_notification_from_user_id', fromUserId);
            await prefs.setString('pending_notification_from_user_name', fromUserName ?? 'Unknown User');
            await prefs.setString('current_user_id_for_nav', currentUserId);
            print("✅ Navigation data stored for chat screen (terminated state)");
            
            // Verify storage
            final storedType = prefs.getString('pending_notification_type');
            final storedFromUserId = prefs.getString('pending_notification_from_user_id');
            print("🔍 Verification - Stored type: $storedType");
            print("🔍 Verification - Stored fromUserId: $storedFromUserId");
          } else {
            print("❌ Cannot store navigation data - currentUserId or fromUserId is null");
          }
        }
        print("🔥 === TERMINATED STATE HANDLER END ===");
      } else {
        print("ℹ️ No initial message - app was not opened from notification");
      }

    } catch (e) {
      print("❌ Error in Firebase Messaging setup: $e");
      print("❌ Stack trace: ${StackTrace.current}");
    }

    // Initialize Local Notifications for mobile
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // Create notification channels for Android 8.0+
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'xcode360_channel',
        'XCODE360 Notifications',
        description: 'Notifications from XCODE360 app',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print("✅ Notification channel created");
    }
    
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print("🔥 === LOCAL NOTIFICATION TAP DETECTED ===");
        print("📩 Local notification tapped: ${response.payload}");
        print("📩 Response type: ${response.notificationResponseType}");
        
        // Parse the notification payload
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            print("🔍 Parsing payload: ${response.payload}");
            final payloadData = jsonDecode(response.payload!);
            final type = payloadData['type'];
            print("🔍 Notification type: $type");
            
            if (type == 'chat_message') {
              print("📱 Local notification is for chat message");
              
              final prefs = await SharedPreferences.getInstance();
              final fromUserId = payloadData['fromUserId'];
              final fromUserName = payloadData['fromUserName'];
              final currentUserId = prefs.getString('userId');
              
              print("📤 From User ID: $fromUserId");
              print("📤 From User Name: $fromUserName");
              print("📱 Current User ID: $currentUserId");
              
              // Store navigation data for dashboard screen to handle
              await prefs.setString('pending_notification_type', 'chat_message');
              await prefs.setString('pending_notification_from_user_id', fromUserId);
              await prefs.setString('pending_notification_from_user_name', fromUserName ?? 'Unknown User');
              await prefs.setString('current_user_id_for_nav', currentUserId ?? '');
              print("✅ Navigation data stored from local notification tap");
              
              // Verify storage
              final storedType = prefs.getString('pending_notification_type');
              final storedFromUserId = prefs.getString('pending_notification_from_user_id');
              print("🔍 Verification - Stored type: $storedType");
              print("🔍 Verification - Stored fromUserId: $storedFromUserId");
              
              // Trigger immediate navigation check
              print("⏰ Triggering immediate navigation check...");
            } else {
              print("⚠️ Notification type is not chat_message: $type");
            }
          } catch (e) {
            print("❌ Error parsing notification payload: $e");
            print("❌ Stack trace: ${StackTrace.current}");
          }
        } else {
          print("⚠️ Notification payload is null or empty");
        }
        print("🔥 === LOCAL NOTIFICATION TAP HANDLER END ===");
      },
    );

    // Handle incoming messages and show notifications on mobile
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("=== FOREGROUND MESSAGE RECEIVED ===");
      print("Message ID: ${message.messageId}");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");
      print("=================================");

      // CRITICAL: Real-time notification debugging
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');
      final toUserId = message.data['toUserId'];
      final fromUserId = message.data['fromUserId'];
      
      print("🔥 === NOTIFICATION DEBUG START ===");
      print("📱 CURRENT USER: $currentUserId");
      print("📨 MESSAGE TO USER: $toUserId");
      print("📤 MESSAGE FROM USER: $fromUserId");
      print("📝 MESSAGE TITLE: ${message.notification?.title}");
      print("📝 MESSAGE BODY: ${message.notification?.body}");
      print("📊 MESSAGE DATA: ${message.data}");
      
      // CRITICAL: Determine if current user should receive notification
      bool shouldShowNotification = false;
      String notificationReason = '';
      
      if (toUserId == currentUserId) {
        shouldShowNotification = true;
        notificationReason = "USER IS RECEIVER - SHOW NOTIFICATION";
        print("✅ $notificationReason");
      } else if (fromUserId == currentUserId) {
        // CRITICAL FIX: Sender should NOT see notification when they send message
        shouldShowNotification = false;
        notificationReason = "USER IS SENDER - NOT SHOWING NOTIFICATION";
        print("❌ $notificationReason");
        print("🚫 NOT SHOWING NOTIFICATION");
        print("🔥 === NOTIFICATION DEBUG END ===");
        return; // Don't show notification
      } else {
        shouldShowNotification = false;
        notificationReason = "USER IS NEITHER SENDER NOR RECEIVER";
        print("❌ $notificationReason");
        print("🚫 NOT SHOWING NOTIFICATION");
        print("🔥 === NOTIFICATION DEBUG END ===");
        return; // Don't show notification
      }
      
      print("🎯 FINAL DECISION: $notificationReason");
      print("📱 SHOWING NOTIFICATION: $shouldShowNotification");
      print("🔥 === NOTIFICATION DEBUG END ===");

      // Show notification on mobile
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'xcode360_channel',
            'XCODE360 Notifications',
            channelDescription: 'Notifications from XCODE360 app',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      // Include message data in payload for navigation on tap
      final notificationPayload = jsonEncode({
        'type': message.data['type'] ?? 'chat_message',
        'fromUserId': message.data['fromUserId'],
        'fromUserName': message.data['fromUserName'],
        'toUserId': message.data['toUserId'],
      });
      
      // Use FCM notification title/body if available, otherwise use data
      final notificationTitle = message.notification?.title ?? 
                           message.data['title'] ?? 
                           'New Message';
      final notificationBody = message.notification?.body ?? 
                          message.data['body'] ?? 
                          'You have a new message';
      
      await flutterLocalNotificationsPlugin.show(
        id: message.hashCode,
        title: notificationTitle,
        body: notificationBody,
        payload: notificationPayload,
        notificationDetails: platformChannelSpecifics,
      );
    });

    // Handle messages when app is in background and opened by notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("🔥 === APP OPENED FROM BACKGROUND NOTIFICATION ===");
      print("Message ID: ${message.messageId}");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");
      print("===============================");
      
      // Handle navigation or other actions based on message data
      if (message.data['type'] == 'chat_message') {
        print("📱 This is a chat message notification from background");
        // Navigate to chat screen
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getString('userId');
        final fromUserId = message.data['fromUserId'];
        final fromUserName = message.data['fromUserName'];
        
        print("📤 From User ID: $fromUserId");
        print("📤 From User Name: $fromUserName");
        print("📱 Current User ID: $currentUserId");
        
        if (currentUserId != null && fromUserId != null) {
          // Store navigation data for later use
          await prefs.setString('pending_notification_type', 'chat_message');
          await prefs.setString('pending_notification_from_user_id', fromUserId);
          await prefs.setString('pending_notification_from_user_name', fromUserName ?? 'Unknown User');
          await prefs.setString('current_user_id_for_nav', currentUserId);
          print("✅ Navigation data stored for chat screen (background)");
          
          // Verify storage
          final storedType = prefs.getString('pending_notification_type');
          final storedFromUserId = prefs.getString('pending_notification_from_user_id');
          print("🔍 Verification - Stored type: $storedType");
          print("🔍 Verification - Stored fromUserId: $storedFromUserId");
          
          // Force a navigation check after a short delay
          print("⏰ Scheduling navigation check in 1 second...");
          Future.delayed(const Duration(seconds: 1), () {
            print("⏰ Navigation check triggered");
            // The dashboard screen will handle the actual navigation
          });
          
          // Also trigger immediate check
          print("⏰ Triggering immediate navigation check...");
        } else {
          print("❌ Cannot store navigation data - currentUserId or fromUserId is null");
        }
      } else if (message.data['type'] == 'exchange_request') {
        print("📱 This is an exchange request notification");
        // Navigate to exchange requests screen
      }
      print("🔥 === BACKGROUND NOTIFICATION HANDLER END ===");
    });
  }

  // Initialize AdMob (non-blocking)
  try {
    await AdMobService().initialize();
    print('✅ AdMob initialized successfully');
  } catch (e) {
    print('❌ Error initializing AdMob: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SplashCubit()),
        BlocProvider(create: (_) => AppCubit()..loadSession()),
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'xcode360',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: kIsWeb ? const WebHomePage() : SplashScreen(),
      routes: {
        '/admin_password': (context) => const AdminPasswordUtility(),
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map) {
            return PaymentScreen(
              userId: args['userId'] as String,
              plan: args['plan'] as String?,
              price: args['price'] as int?,
            );
          } else {
            final userId = args as String;
            return PaymentScreen(userId: userId);
          }
        },
      },
    );
        },
      ),
    );
  }
}
