const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

admin.initializeApp();

exports.deleteUserAccount = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // Allow only POST requests
    if (req.method !== "POST") {
      return res.status(405).send({
        success: false,
        message: "Method Not Allowed. Use POST.",
      });
    }

    const uid = req.body.uid;

    if (!uid) {
      return res.status(400).send({
        success: false,
        message: "UID is required",
      });
    }

    try {
      await admin.auth().deleteUser(uid);

      return res.status(200).send({
        success: true,
        message: `User ${uid} deleted successfully.`,
      });
    } catch (error) {
      console.error("Error deleting user:", error);

      return res.status(500).send({
        success: false,
        message: error.message || "Internal server error",
      });
    }
  });
});
