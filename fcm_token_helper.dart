import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  print("Initializing Firebase...");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print("Firebase initialized successfully!");
  
  // Get Firebase Messaging instance
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  print("Requesting notification permissions...");
  
  // Request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  print("Permission status: ${settings.authorizationStatus}");
  
  print("Getting FCM token...");
  
  // Get and print FCM token
  String? token = await messaging.getToken();
  
  print("\n" + "="*50);
  print("FCM TOKEN FOR ANDROID:");
  print(token);
  print("="*50);
  print("\nCopy this token and use it for testing push notifications.");
  
  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    print("\nFCM Token Refreshed: $newToken");
  });
  
  print("\nScript completed. Token generated successfully!");
}
