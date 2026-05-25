const admin = require("firebase-admin");
const path = require("path");

let serviceAccount;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
  } else {
    serviceAccount = require("./serviceAccountKey.json");
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔥 Firebase Admin SDK Initialized Successfully.");
} catch (error) {
  console.error("❌ Error initializing Firebase Admin SDK:", error.message || error);
}

/**
 * Send push notification to target device(s).
 * @param {string|string[]} tokens - Single token or array of FCM tokens.
 * @param {string} title - Title of notification.
 * @param {string} body - Body content of notification.
 * @param {object} [data] - Optional extra metadata payload.
 */
const sendPushNotification = async (tokens, title, body, data = {}) => {
  if (!tokens || (Array.isArray(tokens) && tokens.length === 0)) {
    console.log("⚠️ No FCM tokens provided. Skipping push notification.");
    return;
  }

  // Filter out empty tokens
  let targetTokens = Array.isArray(tokens) 
    ? tokens.filter(t => t && typeof t === 'string' && t.trim() !== '') 
    : [tokens];

  targetTokens = targetTokens.filter(t => t.length > 0);

  if (targetTokens.length === 0) {
    console.log("⚠️ No valid FCM tokens. Skipping push notification.");
    return;
  }

  // Convert all keys in data to strings (FCM data payload only accepts string values)
  const stringifiedData = {};
  for (const [key, value] of Object.entries(data)) {
    stringifiedData[key] = String(value);
  }
  stringifiedData["click_action"] = "FLUTTER_NOTIFICATION_CLICK";

  try {
    if (targetTokens.length === 1) {
      const response = await admin.messaging().send({
        token: targetTokens[0],
        notification: {
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            icon: "ic_launcher", // Ye aapka app icon hai
            color: "#FF0000",    // Aapka brand color
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        data: stringifiedData
      });
      console.log("🚀 FCM Notification sent successfully:", response);
    } else {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: targetTokens,
        notification: {
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            icon: "ic_launcher",
            color: "#FF0000",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        data: stringifiedData
      });
      console.log(`🚀 FCM Multicast sent successfully: ${response.successCount} success, ${response.failureCount} failed.`);
    }
  } catch (error) {
    console.error("❌ Error sending FCM notification:", error);
  }
};

module.exports = {
  admin,
  sendPushNotification
};
