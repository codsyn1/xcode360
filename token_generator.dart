import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🔥 Initializing Firebase...");
  await Firebase.initializeApp();
  print("✅ Firebase initialized!");

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  print("📱 Requesting permissions...");
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print("Permission: ${settings.authorizationStatus}");

  print("🔑 Getting FCM Token...");
  String? token = await messaging.getToken();
  
  print("\n" + "="*60);
  print("🎯 FCM TOKEN:");
  print(token ?? "❌ TOKEN NULL");
  print("="*60);
  
  exit(0);
}
