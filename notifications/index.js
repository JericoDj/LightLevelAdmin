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


// Returns Firebase Auth account info (uid, created, last sign-in) for a list
// of emails. Only signed-in admins (a doc in /admins/{uid}) may call it.
// POST { emails: ["a@b.com", ...] } with header Authorization: Bearer <ID token>
exports.getAuthUserDates = onRequest({ cors: true, serviceAccount: "llps-mentalapp@appspot.gserviceaccount.com" }, async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send({ success: false, message: "Use POST." });
  }

  try {
    const header = req.headers.authorization || "";
    const idToken = header.startsWith("Bearer ") ? header.substring(7) : null;
    if (!idToken) {
      return res.status(401).send({ success: false, message: "Missing ID token." });
    }

    const decoded = await admin.auth().verifyIdToken(idToken);
    const adminDoc = await admin.firestore().collection("admins").doc(decoded.uid).get();
    if (!adminDoc.exists) {
      return res.status(403).send({ success: false, message: "Admins only." });
    }

    const emails = Array.isArray(req.body.emails) ?
      [...new Set(req.body.emails
          .filter((e) => typeof e === "string" && e.trim())
          .map((e) => e.trim().toLowerCase()))] :
      [];

    const users = {};
    // getUsers accepts at most 100 identifiers per call
    for (let i = 0; i < emails.length; i += 100) {
      const chunk = emails.slice(i, i + 100).map((email) => ({ email }));
      const result = await admin.auth().getUsers(chunk);
      for (const user of result.users) {
        if (!user.email) continue;
        users[user.email.toLowerCase()] = {
          uid: user.uid,
          createdAt: user.metadata.creationTime ? new Date(user.metadata.creationTime).toISOString() : null,
          lastSignInAt: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toISOString() : null,
        };
      }
    }

    return res.status(200).send({ success: true, users });
  } catch (error) {
    console.error("❌ Error fetching auth user dates:", error);
    const status = error.code && error.code.startsWith("auth/") ? 401 : 500;
    return res.status(status).send({ success: false, message: error.message || "Internal server error" });
  }
});
