const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Send push notification to all coordinators
 * Triggered when a new document is created in notifications collection with target: 'all_coordinators'
 */
exports.sendNotificationToCoordinators = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Only process if target is 'all_coordinators' and not already sent
    if (notification.target !== 'all_coordinators' || notification.sent === true) {
      return null;
    }

    try {
      // Get all coordinators
      const coordinatorsSnapshot = await db
        .collection('users')
        .where('role', '==', 'koordinator')
        .get();

      if (coordinatorsSnapshot.empty) {
        console.log('No coordinators found');
        await snap.ref.update({ sent: true, error: 'No coordinators found' });
        return null;
      }

      // Collect FCM tokens
      const tokens = [];
      coordinatorsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log('No FCM tokens found for coordinators');
        await snap.ref.update({ sent: true, error: 'No FCM tokens found' });
        return null;
      }

      // Prepare notification message
      const message = {
        notification: {
          title: notification.title || 'Notifikasi',
          body: notification.body || '',
        },
        data: {
          type: notification.type || 'general',
          ...notification.data,
        },
        tokens: tokens,
      };

      // Send notification
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Successfully sent notification to ${response.successCount} coordinators`);
      if (response.failureCount > 0) {
        console.log(`Failed to send to ${response.failureCount} coordinators`);
      }

      // Update notification document
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      return null;
    } catch (error) {
      console.error('Error sending notification to coordinators:', error);
      await snap.ref.update({
        sent: true,
        error: error.message,
      });
      return null;
    }
  });

/**
 * Send push notification to admin
 * Triggered when a new document is created in notifications collection with target: 'admin'
 */
exports.sendNotificationToAdmin = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Only process if target is 'admin' and not already sent
    if (notification.target !== 'admin' || notification.sent === true) {
      return null;
    }

    try {
      // Get admin user
      const adminSnapshot = await db
        .collection('users')
        .where('role', '==', 'admin')
        .limit(1)
        .get();

      if (adminSnapshot.empty) {
        console.log('No admin found');
        await snap.ref.update({ sent: true, error: 'No admin found' });
        return null;
      }

      const adminData = adminSnapshot.docs[0].data();
      const adminToken = adminData.fcmToken;

      if (!adminToken) {
        console.log('Admin FCM token not found');
        await snap.ref.update({ sent: true, error: 'Admin FCM token not found' });
        return null;
      }

      // Prepare notification message
      const message = {
        notification: {
          title: notification.title || 'Notifikasi',
          body: notification.body || '',
        },
        data: {
          type: notification.type || 'general',
          ...notification.data,
        },
        token: adminToken,
      };

      // Send notification
      const response = await admin.messaging().send(message);
      
      console.log(`Successfully sent notification to admin: ${response}`);

      // Update notification document
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

      return null;
    } catch (error) {
      console.error('Error sending notification to admin:', error);
      await snap.ref.update({
        sent: true,
        error: error.message,
      });
      return null;
    }
  });
