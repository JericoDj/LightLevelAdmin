const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendAdminNotification = onRequest({ cors: true, serviceAccount: "llps-mentalapp@appspot.gserviceaccount.com" }, async (req, res) => {
  try {
    const { token, title, body } = req.body;

    if (!token || !title || !body) {
      return res.status(400).send("Missing required fields");
    }

    const message = {
      notification: {
        title,
        body,
      },
      token,
      // iOS-specific: ensure the notification is displayed with sound
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            sound: "default",
            "content-available": 1,
          },
        },
      },
      // Android-specific: high priority with sound
      android: {
        priority: "high",
        notification: {
          sound: "default",
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("✅ Notification sent:", response);

    return res.status(200).send("Notification sent");
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    return res.status(500).send("Error sending notification");
  }
});

