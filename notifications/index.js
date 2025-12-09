const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

admin.initializeApp();

exports.sendAdminNotification = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
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
      };

      const response = await admin.messaging().send(message);
      console.log("✅ Notification sent:", response);

      return res.status(200).send("Notification sent");
    } catch (error) {
      console.error("❌ Error sending notification:", error);
      return res.status(500).send("Error sending notification");
    }
  });
});
