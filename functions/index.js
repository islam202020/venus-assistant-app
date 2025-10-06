const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new document is created in the 'notifications' collection.
 * It sends a push notification to the specified recipients.
 */
exports.sendPushNotification = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
      const notificationData = snapshot.data();

      if (!notificationData) {
        console.log("No data associated with the event");
        return;
      }

      const message = notificationData.message || "لديك رسالة جديدة";
      const sender = notificationData.sender || "مساعد فينوس";
      const recipientIds = notificationData.recipients || [];

      if (recipientIds.length === 0) {
        console.log("No recipients specified.");
        return;
      }

      console.log(`Sending notification from ${sender} to ${recipientIds.length} recipients.`);
      
      const payload = {
        notification: {
          title: `رسالة جديدة من: ${sender}`,
          body: message,
          sound: "default",
          badge: "1",
        },
      };

      // 1. Get tokens for managers/admins (based on UID)
      const usersByUidQuery = admin.firestore().collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", recipientIds)
          .get();

      // 2. Get tokens for delegates (based on portId)
      const usersByPortIdQuery = admin.firestore().collection("users")
          .where("portId", "in", recipientIds)
          .get();
      
      const [uidSnapshot, portIdSnapshot] = await Promise.all([usersByUidQuery, usersByPortIdQuery]);

      const tokens = new Set(); // Use a Set to avoid duplicate tokens

      uidSnapshot.forEach((doc) => {
        const fcmToken = doc.data().fcmToken;
        if (fcmToken) {
          tokens.add(fcmToken);
        }
      });

      portIdSnapshot.forEach((doc) => {
        const fcmToken = doc.data().fcmToken;
        if (fcmToken) {
          tokens.add(fcmToken);
        }
      });
      
      const tokenList = Array.from(tokens);

      if (tokenList.length === 0) {
        console.log("No registered FCM tokens found for the recipients.");
        return;
      }

      console.log(`Found ${tokenList.length} tokens. Sending notifications...`);
      
      try {
        const response = await admin.messaging().sendToDevice(tokenList, payload);
        console.log("Successfully sent message:", response);
        // Clean up invalid tokens if any
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error("Failure sending notification to", tokenList[index], error);
            }
        });
      } catch (error) {
        console.error("Error sending message:", error);
      }
    });

