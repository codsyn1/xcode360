import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/notification_service.dart';

class LoginResult {
  final String userId;
  final String email;
  const LoginResult({required this.userId, required this.email});
}

class LoginRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  LoginRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  static const String _adminEmail = 'jehangir.ceo@xcode360.com';

  /// Updates the admin password in Firestore
  /// Note: Firebase Auth password must be updated separately through Firebase Console
  Future<void> updateAdminPassword(String newPassword) async {
    try {
      final q = await _db
          .collection('users')
          .where('email', isEqualTo: _adminEmail)
          .limit(1)
          .get();
      
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update({'password': newPassword});
        print('✅ Admin password updated in Firestore');
      } else {
        throw Exception('Admin user not found');
      }
    } catch (e) {
      throw Exception('Failed to update admin password: $e');
    }
  }

  bool _isEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value);
  }

  Future<LoginResult> login({required String identifier, required String password}) async {
    String? email;
    String? userId;

    if (_isEmail(identifier)) {
      // Only admin is allowed to login using email
      if (identifier.toLowerCase() != _adminEmail) {
        throw Exception('Email login is restricted to admin only');
      }
      // Identifier is admin email, try Firebase Auth directly
      email = identifier;
      try {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        userId = cred.user?.uid;
      } catch (_) {
        // fall through to Firestore fallback for admin
      }
    } else {
      // identifier is a username -> lookup email/userId in Firestore
      final userSnap = await _db
          .collection('users')
          .where('username', isEqualTo: identifier)
          .limit(1)
          .get();
      if (userSnap.docs.isNotEmpty) {
        final data = userSnap.docs.first.data();
        email = (data['email'] ?? '').toString();
        userId = userSnap.docs.first.id;
        if (email.isNotEmpty) {
          // If the looked-up email is admin, allow email-based FirebaseAuth; otherwise we'll rely on legacy Firestore password check below
          final allowEmailAuth = email.toLowerCase() == _adminEmail;
          if (allowEmailAuth) {
            try {
              final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
              userId = cred.user?.uid; // prefer auth uid
            } catch (_) {
              // will try Firestore password match below
            }
          }
        }
      }
    }

    // If FirebaseAuth failed (legacy users), try Firestore plaintext match by email OR username
    if (userId == null) {
      // Gate email-based Firestore lookup to admin only
      if ((email ?? identifier).toLowerCase() == _adminEmail) {
        final q1 = await _db
            .collection('users')
            .where('email', isEqualTo: _adminEmail)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();
        if (q1.docs.isNotEmpty) {
          final doc = q1.docs.first;
          return LoginResult(userId: doc.id, email: (doc['email'] ?? '').toString());
        }
      }
      final q2 = await _db
          .collection('users')
          .where('username', isEqualTo: identifier)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();
      if (q2.docs.isNotEmpty) {
        final doc = q2.docs.first;
        return LoginResult(userId: doc.id, email: (doc['email'] ?? '').toString());
      }
    }

    if (userId != null && email != null && email.isNotEmpty) {
      // Store FCM token for push notifications after successful login
      try {
        await NotificationService().storeUserToken(userId);
        // Listen for token refresh for this user
        NotificationService().listenForTokenRefresh(userId);
        print('✅ FCM token stored for logged in user: $userId');
        print('✅ Token refresh listener started for user: $userId');
      } catch (e) {
        print('❌ Error storing FCM token during login: $e');
      }
      return LoginResult(userId: userId, email: email);
    }
    throw Exception('Invalid credentials');
  }
}
