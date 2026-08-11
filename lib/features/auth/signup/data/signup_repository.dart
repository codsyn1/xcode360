import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../services/notification_service.dart';

class SignupRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  SignupRepository({FirebaseAuth? auth, FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<String?> _uploadImage(String? filePath, String folder, String uid) async {
    try {
      if (filePath == null || filePath.isEmpty) return null;
      final file = File(filePath);
      if (!await file.exists()) return null;
      final fileName = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage.ref().child(fileName);
      // Simple content type detection
      final ext = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png') contentType = 'image/png';
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      // Swallow storage errors so signup continues without images
      return null;
    }
  }

  Future<(String userId, String? profileUrl, String? coverUrl)> createUserAndUpload({
    required String fullName,
    required String jobTitle,
    required String email,
    required String password,
    required String username,
    required String mobile,
    required String website,
    required List<String> skills,
    required String? country,
    required String city,
    required String bio,
    required String? experienceLevel,
    required String? category,
    required String? subcategory,
    String? profileImagePath,
    String? coverImagePath,
  }) async {
    // 1) Create auth user or sign in if already exists
    String userId;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      userId = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Try to sign in with the provided password
        final signin = await _auth.signInWithEmailAndPassword(email: email, password: password);
        userId = signin.user!.uid;
      } else {
        rethrow;
      }
    }

    // 2) Upload images (parallel, non-fatal)
    String? profileUrl;
    String? coverUrl;
    try {
      final profileF = _uploadImage(profileImagePath, 'profile_images', userId);
      final coverF = _uploadImage(coverImagePath, 'cover_images', userId);
      final urls = await Future.wait([profileF, coverF]);
      profileUrl = urls[0];
      coverUrl = urls[1];
    } catch (_) {
      // Ignore upload errors; proceed with null URLs
      profileUrl = null;
      coverUrl = null;
    }

    // 3) Save/Update Firestore user document
    // Generate a pseudo-unique 6-digit PIN similar to previous implementation
    final millis = DateTime.now().millisecondsSinceEpoch;
    final pin = ((millis % 900000) + 100000).toString();
    await _db.collection('users').doc(userId).set({
      'fullName': fullName,
      'jobTitle': jobTitle,
      'email': email,
      'password': password,
      'username': username,
      'mobileNumber': mobile,
      'website': website,
      'skills': skills,
      'country': country,
      'city': city,
      'bio': bio,
      'experienceLevel': experienceLevel,
      'profileImageUrl': profileUrl,
      'coverImageUrl': coverUrl,
      'category': category,
      'subcategory': subcategory,
      'createdAt': FieldValue.serverTimestamp(),
      'plan': 'Free',
      'subscriptionCompleted': false,
      'userPin': pin,
    }, SetOptions(merge: true));

    // 4) Store FCM token for push notifications
    try {
      await NotificationService().storeUserToken(userId);
      // Listen for token refresh for this user
      NotificationService().listenForTokenRefresh(userId);
      print('✅ FCM token stored for new user: $userId');
      print('✅ Token refresh listener started for user: $userId');
    } catch (e) {
      print('❌ Error storing FCM token during signup: $e');
    }

    return (userId, profileUrl, coverUrl);
  }
}
