import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();

  // =========================================
  // INITIALIZE FCM (Permissions & Token)
  // =========================================
  static Future<void> initialize() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 User notification permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Fetch FCM Token
        await updateTokenToServer();

        // 3. Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) async {
          if (kDebugMode) {
            print('🔔 FCM Token refreshed: $newToken');
          }
          await _authService.updateFcmToken(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM Service: $e');
      }
    }
  }

  // =========================================
  // FETCH & UPDATE TOKEN ON SERVER
  // =========================================
  static Future<void> updateTokenToServer() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('🚀 Current FCM Token: $token');
        }
        final response = await _authService.updateFcmToken(token);
        if (kDebugMode) {
          print('🚀 Server response for token update: $response');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ FCM Token is null');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating token to server: $e');
      }
    }
  }
}
