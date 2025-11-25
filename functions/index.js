/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// --- HELPER FUNCTIONS (NEW AND EXISTING) ---

/**
 * Sends a push notification (device notification) to a specific user.
 */
async function sendDeviceNotificationToUser(userId, title, body) {
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
  const payload = {
    notification: {
      title: title,
      body: body,
      sound: "default",
    },
  };
  console.log(`Sending device notification to user ${userId}`);
  await admin.messaging().sendToDevice(tokens, payload);
}

/**
 * Creates a persistent in-app notification document in Firestore.
 */
async function createInAppNotification(userId, title, body) {
  console.log(`Creating in-app notification for user ${userId}`);
  await db.collection("notifications").add({
    userId: userId,
    title: title,
    body: body,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * ✅ NEW HELPER
 * Gets a list of all user IDs that have the 'admin' role.
 */
async function getAllAdminIds() {
  const adminUsers = [];
  try {
    const usersSnapshot = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();
    if (usersSnapshot.empty) {
      console.log("No admin users found.");
      return [];
    }
    usersSnapshot.forEach((doc) => {
      adminUsers.push(doc.id);
    });
    return adminUsers;
  } catch (error) {
    console.error("Error getting admin users:", error);
    return [];
  }
}

/**
 * ✅ NEW HELPER
 * Creates an in-app notification with an optional bookingId.
 */
async function createInAppNotificationWithBooking(
  userId,
  title,
  body,
  bookingId = null
) {
  const notificationData = {
    userId: userId,
    title: title,
    body: body,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (bookingId) {
    notificationData.bookingId = bookingId;
  }
  console.log(`Creating in-app notification for user ${userId}`);
  await db.collection("notifications").add(notificationData);
}

exports.onBookingCreate = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snapshot) => {
    const bookingId = snapshot.id; // Get the document ID
    const newBooking = snapshot.data();

    if (newBooking.status !== "Pending") {
      return null;
    }

    const adminIds = await getAllAdminIds();
    if (adminIds.length === 0) {
      return null;
    }

    const title = "New Booking Request";
    const body =
      `A new request for "${newBooking.title}" ` +
      `was submitted by ${newBooking.requestedBy}.`;

    // Create a notification for every admin (with bookingId for linking)
    const promises = [];
    adminIds.forEach((adminId) => {
      promises.push(
        createInAppNotificationWithBooking(adminId, title, body, bookingId)
      );
      promises.push(sendDeviceNotificationToUser(adminId, title, body));
    });

    await Promise.all(promises);
    return null;
  });


exports.onBookingStatusUpdate = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change) => {
    const bookingId = change.after.ref.id; // Get the document ID
    const before = change.before.data();
    const after = change.after.data();

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
        if (before.hall !== after.hall) {
          body += ` It has been re-allocated to ${after.hall}.`;
        }
        break;
      case "Rejected":
        title = "Booking Rejected";
        body =
          `Your request for "${after.title}" has been rejected. ` +
          `Reason: ${after.rejectionReason || "Not specified."}`;
        break;
      default:
        return null;
    }

    await Promise.all([
      createInAppNotificationWithBooking(userId, title, body, bookingId),
      sendDeviceNotificationToUser(userId, title, body),
    ]);
    return null;
  });


exports.deleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Must be an administrative user to delete users."
    );
  }

  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a 'uid' argument."
    );
  }

  try {
    await admin.auth().deleteUser(uid);
    await db.collection("users").doc(uid).delete();
    return { result: `Successfully deleted user ${uid}` };
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new functions.https.HttpsError("internal", "Unable to delete user.");
  }
});
ts.changeUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only an administrator can change user roles."
    );
  }

  const uid = data.uid;
  const newRole = data.newRole;

  // 2. Input Validation
  if (!uid || !newRole || (newRole !== "admin" && newRole !== "Faculty")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a 'uid' and a valid 'newRole'."
    );
  }

  if (context.auth.uid === uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Administrators cannot change their own role."
    );
  }

  try {
    await admin.auth().setCustomUserClaims(uid, { role: newRole });

    await db.collection("users").doc(uid).update({ role: newRole });

    return {
      result: `Successfully changed role for user ${uid} to ${newRole}.`,
    };
  } catch (error) {
    console.error("Error changing user role:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to change user role."
    );
  }
});

