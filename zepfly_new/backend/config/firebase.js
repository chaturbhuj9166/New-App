const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require("./serviceAccountKey.json");

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔥 Firebase Admin SDK Initialized Successfully.");
} catch (error) {
  console.error("❌ Error initializing Firebase Admin SDK:", error);
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
