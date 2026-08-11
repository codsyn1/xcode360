import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Firebase initialized!");

  // Get Firebase Messaging instance
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print("Permission granted: ${settings.authorizationStatus}");

  // Get FCM token
  String? token = await messaging.getToken();
  
  print("\n" + "="*60);
  print("FCM TOKEN:");
  print(token ?? "No token received");
  print("="*60);
  
  exit(0);
}
