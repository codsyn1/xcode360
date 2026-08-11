# Notification Debugging Guide

## Problem Statement:
Jab user dusre user ko message bhejta hai chat mein, to notification receiver ko nahi balki sender ko ja rahi hai.

## Debugging Steps:

### 1. Check FCM Token Storage
When app starts, check console logs for:
```
🔑 FCM TOKEN FOR USER [USER_ID]: [TOKEN]...
✅ FCM token stored for user: [USER_ID]
📱 TOKEN LENGTH: [LENGTH]
```

### 2. Check Notification Sending
When user sends message, check for these logs:
```
=== SENDING CHAT MESSAGE NOTIFICATION ===
FROM: [SENDER_ID] ([SENDER_NAME])
TO: [RECEIVER_ID] ([RECEIVER_NAME])
MESSAGE: [MESSAGE_TEXT]
RECEIVER FCM TOKEN: [TOKEN] OR NULL
RECEIVER DATA KEYS: [KEYS]
✅ FCM TOKEN FOUND: [TOKEN]...
📝 NOTIFICATION DOC ID: [DOC_ID]
📱 PUSH NOTIFICATION TRIGGERED FOR USER: [RECEIVER_ID]
```

### 3. Check Cloud Function Logs
Check Firebase Console > Functions > Logs for:
```
=== CLOUD FUNCTION TRIGGERED ===
DOCUMENT ID: [DOC_ID]
DOCUMENT DATA: [DATA]
📱 SENDING NOTIFICATION TO: [RECEIVER_ID]
🔑 FCM TOKEN: [TOKEN]...
📝 TITLE: New Message
💬 BODY: [SENDER_NAME]: [MESSAGE_TEXT]
🚀 SENDING FCM MESSAGE...
✅ SUCCESSFULLY SENT MESSAGE: [MESSAGE_ID]
📊 MESSAGE ID: [MESSAGE_ID]
📈 UPDATED UNREAD COUNT FOR USER: [RECEIVER_ID]
```

## Common Issues & Solutions:

### Issue 1: Receiver has no FCM token
**Symptoms:**
```
❌ NO FCM TOKEN FOUND FOR RECEIVER: [USER_ID]
⚠️ Chat notification will be stored for offline access only
```

**Solution:** 
- Receiver must open app at least once to get FCM token
- Check if receiver's app has notification permissions

### Issue 2: Cloud Function not triggered
**Symptoms:** No logs in Firebase Console

**Solution:**
- Check if `push_notifications` collection has new documents
- Verify Cloud Function is deployed and active

### Issue 3: FCM sending fails
**Symptoms:**
```
❌ ERROR SENDING MESSAGE: [ERROR]
🔍 ERROR DETAILS: [DETAILS]
```

**Solution:**
- Check if FCM token is valid
- Verify app has proper Firebase configuration
- Check device notification settings

## Testing Steps:

1. **Open app on two different devices/users**
2. **Check FCM tokens are stored** (look for 🔑 logs)
3. **User A sends message to User B**
4. **Check notification logs** in User A's app
5. **Check Cloud Function logs** in Firebase Console
6. **User B should receive notification**

## Expected Behavior:
- ✅ Sender sees: "✅ Chat notification sent successfully"
- ✅ Cloud Function triggers and sends push notification
- ✅ Receiver gets push notification even if app is closed/minimized
- ✅ Notification appears in receiver's device notification tray

## If Still Not Working:
1. Check Firebase Console > Authentication > Users - both users exist
2. Check Firebase Console > Firestore > users > [userId] - fcmToken field exists
3. Check Firebase Console > Functions > Logs - for any errors
4. Check device notification permissions
5. Try clearing app data and logging in again
