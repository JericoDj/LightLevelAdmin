// One-time backfill: turn "phantom" user_tracking/{companyId} docs into real,
// queryable documents so the telemetry dashboard can list them.
//
// Usage:
//   1. Download a service-account key for the llps-mentalapp project from
//      Firebase Console → Project Settings → Service accounts → Generate new private key
//   2. Save it as serviceAccount.json next to this file (do NOT commit it).
//   3. node backfill_tracking.js
//
// Safe to run multiple times (idempotent merge).

const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccount.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

(async () => {
  // listDocuments() returns phantom docs too (unlike .get() on the collection)
  const companyRefs = await db.collection("user_tracking").listDocuments();
  console.log(`Found ${companyRefs.length} company docs under user_tracking`);

  for (const ref of companyRefs) {
    await ref.set(
      { companyId: ref.id, backfilledAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    console.log(`✅ Fixed phantom doc: ${ref.id}`);
  }

  console.log("Done. All company docs are now real and queryable.");
  process.exit(0);
})().catch((e) => {
  console.error("❌ Backfill failed:", e);
  process.exit(1);
});
