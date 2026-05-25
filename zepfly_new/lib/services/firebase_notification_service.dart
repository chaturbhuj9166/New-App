import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Comprehensive Firebase notification service handling all notification states:
/// - Foreground (app open)
/// - Background (app minimized)
/// - Terminated (app closed)
///
/// Combines FCM with flutter_local_notifications to display popups and tray notifications
class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =========================================
  // INITIALIZE ALL NOTIFICATION HANDLERS
  // =========================================
  static Future<void> initializeNotifications() async {
    try {
      // 1. Request notification permissions (Android 13+)
      await _requestNotificationPermissions();

      // 2. Setup notification channels
      await _setupNotificationChannels();

      // 3. Initialize local notifications
      await _initializeLocalNotifications();

      // 4. Setup message handlers (must be after initialization)
      _setupMessageHandlers();

      if (kDebugMode) {
        print('✅ Firebase Notification Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Firebase Notification Service: $e');
      }
    }
  }

  // =========================================
  // REQUEST NOTIFICATION PERMISSIONS
  // =========================================
  static Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print(
          '🔔 Notification permission status: ${settings.authorizationStatus}',
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          print('⚠️ Notification permission denied by user');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting notification permissions: $e');
      }
    }
  }

  // =========================================
  // SETUP NOTIFICATION CHANNELS
  // =========================================
  static Future<void> _setupNotificationChannels() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'fcm_channel',
        'FCM Notifications',
        description:
            'This channel is used for important Firebase notifications.',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      if (kDebugMode) {
        print('✅ Notification channel created');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting up notification channels: $e');
      }
    }
  }

  // =========================================
  // INITIALIZE LOCAL NOTIFICATIONS
  // =========================================
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      if (kDebugMode) {
        print('✅ Local notifications initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing local notifications: $e');
      }
    }
  }

  // =========================================
  // SETUP MESSAGE HANDLERS
  // =========================================
  static void _setupMessageHandlers() {
    // Handle foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle message opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });

    if (kDebugMode) {
      print('✅ Message handlers registered');
    }
  }

  // =========================================
  // HANDLE FOREGROUND MESSAGES
  // =========================================
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📲 Foreground message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    }

    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: _convertToStringMap(message.data),
      );
    }
  }

  // =========================================
  // HANDLE MESSAGE OPENED FROM BACKGROUND
  // =========================================
  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 App opened from notification: ${message.notification?.title}');
      print('   Data: ${message.data}');
    }
    // Handle deep linking or navigation here if needed
  }

  // =========================================
  // SHOW LOCAL NOTIFICATION
  // =========================================
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'fcm_channel',
            'FCM Notifications',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        title.hashCode,
        title,
        body,
        notificationDetails,
        payload: payload?['click_action'] ?? '',
      );

      if (kDebugMode) {
        print('✅ Local notification displayed: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  // =========================================
  // HANDLE NOTIFICATION TAP
  // =========================================
  static void _handleNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('👆 Notification tapped: ${response.payload}');
    }
    // Handle navigation or actions based on notification payload
  }

  // =========================================
  // CONVERT MAP TO STRING MAP
  // =========================================
  static Map<String, String> _convertToStringMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, value.toString()));
  }

  // =========================================
  // GET FCM TOKEN
  // =========================================
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('🚀 FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }
}
