import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get Firebase Messaging instance
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get and print FCM token
  String? token = await messaging.getToken();
  print("=================================");
  print("YOUR FCM TOKEN:");
  print(token);
  print("=================================");
  
  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    print("FCM Token Refreshed: $newToken");
  });
}
