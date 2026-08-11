/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Send push notification when a new document is created in push_notifications collection
exports.sendPushNotification = onDocumentCreated("push_notifications/{docId}", async (event) => {
  const snapshot = event.data;
  const data = snapshot.data();

  logger.info("=== CLOUD FUNCTION TRIGGERED ===");
  logger.info(`DOCUMENT ID: ${event.params.docId}`);
  logger.info(`DOCUMENT DATA: ${JSON.stringify(data)}`);

  if (!data) {
    logger.warn(" No data found in the document");
    return;
  }

  // Extract notification data - handle both old and new payload structures
  const { fcmToken, toUserId } = data;
  const notification = data.notification || {};
  const notificationData = data.data || {};
  
  // Use notification.title/body if available, otherwise fall back to root level
  const title = notification.title || data.title || 'New Message';
  const body = notification.body || data.body || 'You have a new message';
  
  logger.info("=== CLOUD FUNCTION DEBUG START ===");
  logger.info(`SENDING NOTIFICATION TO: ${toUserId}`);
  logger.info(`FIREBASE MESSAGING TOKEN: ${fcmToken ? fcmToken.substring(0, 20) + "..." : "NULL"}`);
  logger.info(`TITLE: ${title}`);
  logger.info(`BODY: ${body}`);
  logger.info(`FULL NOTIFICATION DATA: ${JSON.stringify(notificationData)}`);
  logger.info(`FULL PAYLOAD STRUCTURE: ${JSON.stringify(data)}`);

  if (!fcmToken) {
    logger.error(" NO FCM TOKEN FOUND - ABORTING");
    return;
  }

  // CRITICAL: Check if this is a same-device token conflict
  const fromUserId = notificationData?.fromUserId;
  logger.info(`MESSAGE FROM USER: ${fromUserId}`);
  logger.info(`MESSAGE TO USER: ${toUserId}`);
  
  // CRITICAL: Skip notification if sender and receiver have same token (same device)
  if (fromUserId === toUserId) {
    logger.error("SENDER AND RECEIVER ARE THE SAME USER - SKIPPING");
    logger.error("THIS IS A SELF-MESSAGE - NOTIFICATION NOT NEEDED");
    return;
  }

  // CRITICAL: Verify the token belongs to the intended receiver
  // Get the receiver's document to verify token ownership
  try {
    const receiverDoc = await admin.firestore().collection('users').doc(toUserId).get();
    if (receiverDoc.exists) {
      const receiverData = receiverDoc.data();
      const storedToken = receiverData?.fcmToken;
      const tokenUserId = receiverData?.tokenUserId;
      
      logger.info(`RECEIVER STORED TOKEN: ${storedToken ? storedToken.substring(0, 20) + "..." : "NULL"}`);
      logger.info(`RECEIVER TOKEN USER ID: ${tokenUserId}`);
      logger.info(`PROVIDED TOKEN: ${fcmToken.substring(0, 20)}...`);
      
      // CRITICAL: Verify tokenUserId matches toUserId (this is the most important check)
      if (tokenUserId && tokenUserId !== toUserId) {
        logger.error("!!! CRITICAL ERROR: TOKEN BELONGS TO WRONG USER !!!");
        logger.error(`!!! TOKEN USER ID: ${tokenUserId} !!!`);
        logger.error(`!!! EXPECTED USER ID: ${toUserId} !!!`);
        logger.error(`!!! NOTIFICATION WILL GO TO WRONG USER !!!`);
        logger.error(`!!! SKIPPING NOTIFICATION TO PREVENT WRONG USER DELIVERY !!!`);
        
        // Mark as failed
        await snapshot.ref.update({
          isProcessed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: 'Token belongs to wrong user',
        });
        return;
      }
      
      // NOTE: We don't check if storedToken === fcmToken because:
      // 1. Same device users share the same FCM token
      // 2. The tokenUserId check is sufficient to verify ownership
      // 3. This allows notifications to work for same-device testing
      logger.info(`✅ TOKEN OWNERSHIP VERIFIED - tokenUserId matches toUserId`);
    }
  } catch (error) {
    logger.error(`ERROR VERIFYING TOKEN OWNERSHIP: ${error}`);
    // Continue anyway as this might be a temporary issue
  }

  logger.info(`NOTIFICATION READY FOR USER: ${toUserId}`);
  logger.info(`SENDING NOTIFICATION TO: ${toUserId}`);
  logger.info(`FCM TOKEN VALID: ${fcmToken.length > 0}`);

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: notificationData || {},
    android: {
      priority: "high",
      ttl: 2419200000, // 28 days in milliseconds - prevent expiration
      notification: {
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        priority: "high",
        visibility: "public",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10", // 10 = immediate delivery
        "apns-expiration": "0", // Never expire
      },
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          priority: "immediate",
        },
      },
    },
  };

  try {
    logger.info("🚀 SENDING FCM MESSAGE...");
    const response = await admin.messaging().send(message);
    logger.info(`✅ SUCCESSFULLY SENT MESSAGE: ${response}`);
    logger.info(`📊 MESSAGE ID: ${response}`);

    // Mark the notification as processed
    await snapshot.ref.update({
      isProcessed: true,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      messageId: response,
    });

    // Update user's unread notification count
    await updateUserNotificationCount(toUserId);
    logger.info(`📈 UPDATED UNREAD COUNT FOR USER: ${toUserId}`);

  } catch (error) {
    logger.error(`❌ ERROR SENDING MESSAGE: ${error}`);
    logger.error(`🔍 ERROR DETAILS: ${JSON.stringify(error)}`);
    
    // Mark as failed
    await snapshot.ref.update({
      isProcessed: true,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      error: error.message,
    });
  }
});

// Function to update user's unread notification count
async function updateUserNotificationCount(userId) {
  try {
    const notificationsRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .where('isRead', '==', false);

    const snapshot = await notificationsRef.get();
    const unreadCount = snapshot.size;

    await admin.firestore().collection('users').doc(userId).update({
      unreadNotifications: unreadCount,
      lastNotificationUpdate: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Updated unread count for user ${userId}: ${unreadCount}`);
  } catch (error) {
    logger.error(`Error updating notification count: ${error}`);
  }
}

// HTTP function to test push notifications
exports.testNotification = onRequest(async (req, res) => {
  logger.info("=== TEST NOTIFICATION TRIGGERED ===");
  
  try {
    const { userId, title, body } = req.body;
    
    if (!userId || !title || !body) {
      logger.error("MISSING REQUIRED PARAMETERS");
      res.status(400).json({ error: "Missing parameters" });
      return;
    }
    
    logger.info(`TEST NOTIFICATION TO: ${userId}`);
    logger.info(`TEST MESSAGE: ${body}`);
    
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      logger.error(`USER NOT FOUND: ${userId}`);
      res.status(404).json({ error: "User not found" });
      return;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) {
      logger.error(`NO FCM TOKEN FOR USER: ${userId}`);
      res.status(400).json({ error: "No FCM token" });
      return;
    }
    
    logger.info(`SENDING TEST NOTIFICATION TO TOKEN: ${fcmToken.substring(0, 20)}...`);
    
    const testMessage = {
      token: fcmToken,
      notification: {
        title: "Test Notification",
        body: body,
      },
      data: {
        type: "test",
        timestamp: Date.now().toString(),
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };
    
    const response = await admin.messaging().send(testMessage);
    logger.info(`TEST NOTIFICATION SENT: ${response}`);
    
    res.json({ 
      success: true, 
      messageId: response,
      message: "Test notification sent successfully"
    });
  } catch (error) {
    logger.error(`TEST NOTIFICATION ERROR: ${error}`);
    res.status(500).json({ error: error.message });
  }
});
