/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Sends a push notification (device notification) to a specific user.
 * @param {string} userId The UID of the user to notify.
 * @param {string} title The title of the push notification.
 * @param {string} body The body of the push notification.
 */
async function sendDeviceNotificationToUser(userId, title, body) {
  // 1. Get the user's document to find their device tokens.
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    console.log(`User document ${userId} not found.`);
    return;
  }

  const tokens = userDoc.data().fcmTokens;
  if (!tokens || tokens.length === 0) {
    console.log(`No FCM tokens for user ${userId}.`);
    return;
  }

  // 2. Construct the notification payload.
  const payload = {
    notification: {
      title: title,
      body: body,
      sound: "default", // Plays the default notification sound.
    },
  };

  // 3. Send the notification to all of the user's registered devices.
  console.log(`Sending device notification to user ${userId}`);
  await admin.messaging().sendToDevice(tokens, payload);
}

/**
 * Creates a persistent in-app notification document in Firestore.
 * @param {string} userId The UID of the user who will see the notification.
 * @param {string} title The title of the in-app notification.
 * @param {string} body The body of the in-app notification.
 */
async function createInAppNotification(userId, title, body) {
  console.log(`Creating in-app notification for user ${userId}`);
  await db.collection("notifications").add({
    userId: userId,
    title: title,
    body: body,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(), // Use server time.
  });
}

/**
 * This is the main trigger. It runs whenever a booking document is updated.
 */
exports.onBookingStatusUpdate = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change) => {
      const before = change.before.data();
      const after = change.after.data();

      // Exit if the status hasn't changed.
      if (before.status === after.status) {
        return null;
      }

      const userId = after.requesterId;
      let title = "";
      let body = "";

      switch (after.status) {
        case "Approved":
          title = "Booking Approved!";
          body = `Your request for "${after.title}" has been approved.`;
          // Add a note if the hall was changed by the admin.
          if (before.hall !== after.hall) {
            body += ` It has been re-allocated to ${after.hall}.`;
          }
          break;
        case "Rejected":
          title = "Booking Rejected";
          body = `Your request for "${after.title}" has been rejected. ` +
                    `Reason: ${after.rejectionReason || "Not specified."}`;
          break;
        default:
          return null;
      }

      await Promise.all([
        createInAppNotification(userId, title, body),
        sendDeviceNotificationToUser(userId, title, body),
      ]);
      return null;
    });

/**
 * Deletes a user's Firestore document when their Auth account is deleted.
 * Also allows an admin to trigger a user deletion via a callable function.
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Check if the caller is an admin.
  if (context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Must be an administrative user to delete users.",
    );
  }

  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a 'uid' argument.",
    );
  }

  try {
    // Delete from Firebase Authentication
    await admin.auth().deleteUser(uid);
    // Delete from Firestore
    await db.collection("users").doc(uid).delete();
    return {result: `Successfully deleted user ${uid}`};
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new functions.https.HttpsError("internal", "Unable to delete user.");
  }
});


/**
 * A callable function for an admin to change another user's role.
 * This function sets a custom claim on the user's Auth record, which is
 * the most secure way to manage roles, and also updates the Firestore doc.
 */
exports.changeUserRole = functions.https.onCall(async (data, context) => {
  // 1. Authentication & Authorization Check
  // Check if the user making the request is an authenticated admin.
  if (context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError( // This line has a length of 84. Maximum allowed is 80.

        "permission-denied",
        "Only an administrator can change user roles.",
    );
  }

  const uid = data.uid;
  const newRole = data.newRole;

  // 2. Input Validation
  if (!uid || !newRole || (newRole !== "admin" && newRole !== "Faculty")) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a 'uid' and a valid 'newRole'.",
    );
  }

  // 3. Prevent Self-Demotion
  if (context.auth.uid === uid) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Administrators cannot change their own role.",
    );
  }

  try {
    // 4. Set the custom claim on the Firebase Auth user.
    // This is the primary source of truth for security rules.
    await admin.auth().setCustomUserClaims(uid, {role: newRole});

    // 5. Update the user's document in Firestore to keep the UI in sync.
    await db.collection("users").doc(uid).update({role: newRole});

    return {result: `Successfully changed role for user ${uid} to ${newRole}.`};
  } catch (error) {
    console.error("Error changing user role:", error);
    throw new functions.https.HttpsError("internal", "Unable to change user role.");
  }
});
