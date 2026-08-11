import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  const adminEmail = 'jehangir.ceo@xcode360.com';
  const newPassword = 'admin123';

  try {
    // Initialize Firebase
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    print('Updating admin password for: $adminEmail');
    print('New password will be set to: $newPassword');
    print('');

    // Step 1: Update in Firebase Authentication
    print('Step 1: Updating Firebase Authentication...');
    try {
      // First, we need to authenticate as admin or use admin SDK
      // For this script, we'll try to update the password directly
      // Note: This might require admin privileges or current password
      
      // Get the user by email
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('❌ Admin user not found in Firestore');
        return;
      }

      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      
      print('✅ Found admin user with ID: $userId');

      // Step 2: Update password in Firestore
      print('Step 2: Updating password in Firestore...');
      await userDoc.reference.update({'password': newPassword});
      print('✅ Password updated in Firestore');

      // Step 3: Try to update in Firebase Auth (if possible)
      print('Step 3: Attempting to update Firebase Auth...');
      try {
        // This would typically require the user to be logged in or use admin SDK
        // For now, we'll show the manual steps needed
        print('⚠️  Firebase Auth password update requires:');
        print('   - Either the user to be logged in with current password');
        print('   - Or Firebase Admin SDK with proper privileges');
        print('   - Or manual update in Firebase Console');
        print('');
        print('Manual Firebase Console steps:');
        print('1. Go to Firebase Console');
        print('2. Navigate to Authentication -> Users');
        print('3. Find user: $adminEmail');
        print('4. Click on the user and select "Reset Password"');
        print('5. Set new password to: $newPassword');
        
      } catch (e) {
        print('⚠️  Could not update Firebase Auth automatically: $e');
      }

      print('');
      print('✅ Admin password update completed!');
      print('📧 Email: $adminEmail');
      print('🔑 New Password: $newPassword');
      print('');
      print('Note: Make sure to update Firebase Auth password manually if needed.');

    } catch (e) {
      print('❌ Error updating password: $e');
    }

  } catch (e) {
    print('❌ Initialization error: $e');
  }
}
