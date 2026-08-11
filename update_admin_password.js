const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// You'll need to replace this with your actual service account key
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function updateAdminPassword() {
  const adminEmail = 'jehangir.ceo@xcode360.com';
  const newPassword = 'admin123';

  try {
    console.log('🔧 Updating admin password...');
    console.log(`📧 Email: ${adminEmail}`);
    console.log(`🔑 New Password: ${newPassword}`);
    console.log('');

    // Step 1: Find admin user in Firestore
    console.log('📋 Step 1: Finding admin user in Firestore...');
    const userQuery = await db
      .collection('users')
      .where('email', isEqualTo: adminEmail)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log('❌ Admin user not found in Firestore');
      return;
    }

    const userDoc = userQuery.docs[0];
    const userId = userDoc.id;
    console.log(`✅ Found admin user with ID: ${userId}`);

    // Step 2: Update password in Firestore
    console.log('📋 Step 2: Updating password in Firestore...');
    await userDoc.ref.update({ password: newPassword });
    console.log('✅ Password updated in Firestore');

    // Step 3: Update password in Firebase Auth
    console.log('📋 Step 3: Updating password in Firebase Auth...');
    try {
      await auth.updateUser(userId, {
        password: newPassword
      });
      console.log('✅ Password updated in Firebase Auth');
    } catch (authError) {
      console.log('⚠️  Could not update Firebase Auth automatically:', authError.message);
      console.log('📝 Manual steps required:');
      console.log('   1. Go to Firebase Console');
      console.log('   2. Navigate to Authentication -> Users');
      console.log(`   3. Find user: ${adminEmail}`);
      console.log('   4. Click on the user and select "Reset Password"');
      console.log(`   5. Set new password to: ${newPassword}`);
    }

    console.log('');
    console.log('🎉 Admin password update completed!');
    console.log('📧 Email:', adminEmail);
    console.log('🔑 New Password:', newPassword);

  } catch (error) {
    console.error('❌ Error updating admin password:', error);
  } finally {
    await admin.app().delete();
  }
}

updateAdminPassword();
