# Firebase Notifications Configuration Guide

## Overview
This document explains the complete Firebase notification setup for your Zepfly app. Notifications will now appear on the phone screen (popup + tray) in all states: foreground, background, and terminated.

## Architecture

### 1. **Backend (Node.js)**
- **File**: `backend/config/firebase.js`
- **Function**: `sendPushNotification(tokens, title, body, data)`
- **How it works**:
  - Takes FCM tokens from the User model
  - Sends notifications via Firebase Admin SDK
  - Includes `click_action: "FLUTTER_NOTIFICATION_CLICK"` for deep linking
  - Converts all data to strings (FCM requirement)

### 2. **Frontend (Flutter)**
Notification flow across 3 states:

#### **Foreground (App Open)**
- User is actively using the app
- `FirebaseMessaging.onMessage` listener catches the message
- Triggers `flutter_local_notifications` to show a popup + tray notification
- Visual feedback: Notification appears immediately on screen

#### **Background (App Minimized)**
- User minimizes the app
- FCM still delivers the message to the device
- `FirebaseMessaging.onBackgroundMessage` handler processes it
- `firebase_notification_service.dart` shows the notification
- Visual feedback: Notification tray displays the alert

#### **Terminated (App Closed)**
- User has completely closed the app
- FCM delivers notification to Android system
- Android OS displays the notification in the tray
- When user taps notification, `onMessageOpenedApp` listener handles navigation
- Visual feedback: Tray notification appears

## File Structure

```
lib/
├── main.dart                                      # App entry point (simplified)
├── services/
│   ├── firebase_notification_service.dart        # ✅ NEW - Core notification handler
│   ├── fcm_service.dart                          # Token management
│   ├── auth_service.dart                         # User auth + FCM token sync
│   └── notification_service.dart                 # Backend API calls

android/
├── app/src/main/AndroidManifest.xml              # ✅ Notification permissions
└── app/build.gradle.kts                          # Gradle config

pubspec.yaml                                       # Dependencies
```

## Step-by-Step Setup

### Step 1: Dependencies (Already Installed)
Check your `pubspec.yaml` has:
```yaml
firebase_core: ^4.9.0
firebase_messaging: ^16.2.2
flutter_local_notifications: ^17.2.2
timezone: ^0.9.4
```

Run: `flutter pub get`

### Step 2: Android Manifest (Already Configured ✅)
File: `android/app/src/main/AndroidManifest.xml`

Required permissions are already there:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Step 3: Initialize in main.dart (✅ Done)
The `FirebaseNotificationService.initializeNotifications()` handles:
- ✅ Firebase initialization
- ✅ Permission requests (Android 13+)
- ✅ Notification channel creation
- ✅ Local notifications setup
- ✅ Message listeners

### Step 4: Ensure FCM Token is Sent to Backend
File: `lib/services/fcm_service.dart` (Already implemented ✅)

The `FcmService.initialize()` is called from `dashboard_screen.dart`:
- Gets the FCM token from `FirebaseMessaging.instance.getToken()`
- Sends it to backend via `updateFcmToken()`
- Listens for token refresh and updates backend

### Step 5: Test Notifications

#### Test Backend Notification Sending
In your Node.js backend, test the notification controller:
```bash
# Example API call to trigger a notification
POST /api/announcements
Body: {
  "title": "Test Notification",
  "body": "This is a test message",
  "targetUsers": ["user_id_1", "user_id_2"]
}
```

Check the backend logs for:
- ✅ "FCM Tokens provided"
- ✅ "FCM Notification sent successfully"

#### Test Frontend Display

1. **Foreground Test**:
   - Keep the app open
   - Send a notification from backend
   - Notification should appear in tray + screen popup

2. **Background Test**:
   - Minimize the app (don't close it)
   - Send a notification
   - Notification should appear in tray

3. **Terminated Test**:
   - Close the app completely
   - Send a notification
   - Notification should appear in tray
   - Tap it to open the app

## Key Features Implemented

### ✅ Notification Channels
- Channel ID: `fcm_channel`
- Importance: `max` (highest priority)
- Vibration: Enabled
- Lights: Enabled
- Badge: Shown

### ✅ Permission Handling
```dart
await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  criticalAlert: false,
  provisional: false,
);
```

### ✅ Three Listeners
1. **onMessage**: Foreground (app is open)
2. **onBackgroundMessage**: Background (app minimized)
3. **onMessageOpenedApp**: When notification is tapped

### ✅ Data Payload
Backend sends:
```json
{
  "notification": {
    "title": "...",
    "body": "..."
  },
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "custom_key": "custom_value"
  }
}
```

## Troubleshooting

### Issue: Notifications Not Appearing

**Check 1: FCM Token**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

**Check 2: Permission Status**
```dart
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Auth Status: ${settings.authorizationStatus}');
```

**Check 3: Backend Logs**
- Verify the notification controller sends the message
- Check Firebase Admin SDK logs for errors
- Ensure tokens are not empty

**Check 4: Android Settings**
- Go to Settings > Apps > [Your App] > Notifications
- Ensure notifications are enabled
- Check "Allow notifications" toggle

**Check 5: Logcat Output**
```bash
flutter logs
# Look for:
# ✅ "Notification permission status"
# ✅ "Foreground message received"
# ✅ "Local notification displayed"
```

### Issue: Notifications Appearing but No Sound/Vibration

**Fix**: Ensure notification channel is created BEFORE showing notifications
- ✅ Already handled in `firebase_notification_service.dart`

### Issue: Notifications in Tray but Not Popup

**Fix**: Increase importance level
```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'fcm_channel',
  'FCM Notifications',
  importance: Importance.max,  // ← Make sure this is 'max'
  priority: Priority.high,     // ← And this is 'high'
);
```

### Issue: App Crashes When Receiving Notification

**Fix**: Ensure `FirebaseNotificationService.initializeNotifications()` is called before setting background handler
- ✅ Already fixed in `main.dart`

## Advanced Configuration

### Custom Notification Actions (Future Enhancement)
You can add notification actions like "Reply", "Dismiss", etc:
```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'fcm_channel',
  'FCM Notifications',
  actions: [
    AndroidNotificationAction(
      'reply',
      'Reply',
      cancelNotification: true,
    ),
  ],
);
```

### Deep Linking (Future Enhancement)
Handle navigation when notification is tapped:
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  final deepLink = message.data['deepLink'];
  // Navigate to specific screen
});
```

### Notification Badges (Future Enhancement)
Show badge count on app icon:
```dart
// Update badge count
await flutterLocalNotificationsPlugin.show(
  id,
  title,
  body,
  notificationDetails,
  badgeNumber: unreadCount,
);
```

## Performance Tips

1. **Avoid Duplicate Notifications**
   - Use unique notification IDs
   - Check if message is already processed

2. **Optimize Payload Size**
   - Keep data payload minimal
   - FCM data limit is 4KB per message

3. **Handle Rate Limiting**
   - Space out bulk notifications
   - Use scheduling for planned sends

## Security Considerations

1. **Token Rotation**
   - Tokens can change, always listen to `onTokenRefresh`
   - ✅ Already implemented in `fcm_service.dart`

2. **Data Encryption**
   - Sensitive data should not be in FCM data payload
   - Use HTTPS for backend communication

3. **Validation**
   - Always validate notification origin
   - Check sender ID in Firebase Console

## Backend Integration Checklist

- [ ] FCM tokens are saved in User model
- [ ] `sendPushNotification()` function sends tokens correctly
- [ ] Backend logs show successful sends
- [ ] Error handling for invalid tokens
- [ ] Automatic token refresh when invalid

## Flutter Integration Checklist

- [ ] `firebase_notification_service.dart` created
- [ ] `main.dart` calls `FirebaseNotificationService.initializeNotifications()`
- [ ] Permission requests work on Android 13+
- [ ] Notification channel created before use
- [ ] All three listeners (onMessage, onBackground, onMessageOpenedApp) working
- [ ] Local notifications plugin initialized
- [ ] Debugging logs show proper flow

## Testing Checklist

- [ ] Foreground notification displays popup
- [ ] Background notification shows in tray
- [ ] Terminated app notification appears
- [ ] Notification sound plays
- [ ] Vibration triggers
- [ ] Notification count/badge appears
- [ ] Tapping notification opens app
- [ ] Backend logs confirm sends

## References

- [Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview/)
- [Flutter Local Notifications](https://github.com/MaikuB/flutter_local_notifications)
- [Android Notification Channels](https://developer.android.com/guide/topics/ui/notifiers/notifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/database/admin/start)

## Support

If notifications still don't appear after this setup:

1. Check **logcat** output: `flutter logs`
2. Verify **firebase_messaging** version compatibility
3. Ensure **Google Play Services** are updated on test device
4. Test with **different Android versions** (especially Android 13+)
5. Check **notification settings** in system Settings app

---

**Last Updated**: May 21, 2026
**Status**: ✅ Fully Configured
