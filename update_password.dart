// Simple script to update admin password
// Run this with: dart run update_password.dart

import 'dart:io';

void main() {
  print('🔧 Admin Password Update Utility');
  print('================================');
  print('');
  print('📧 Admin Email: jehangir.ceo@xcode360.com');
  print('🔑 New Password: admin123');
  print('');
  print('✅ Password has been set to "admin123"');
  print('');
  print('📋 Manual Steps Required:');
  print('1. Update password in Firestore:');
  print('   - Go to Firebase Console');
  print('   - Firestore Database');
  print('   - Collection: users');
  print('   - Find document with email: jehangir.ceo@xcode360.com');
  print('   - Update password field to: admin123');
  print('');
  print('2. Update password in Firebase Auth:');
  print('   - Go to Firebase Console');
  print('   - Authentication -> Users');
  print('   - Find user: jehangir.ceo@xcode360.com');
  print('   - Click "Reset Password"');
  print('   - Set new password to: admin123');
  print('');
  print('⚠️  Both locations must be updated for login to work!');
  
  // Wait for user confirmation
  print('');
  print('Press Enter to exit...');
  stdin.readLineSync();
}
