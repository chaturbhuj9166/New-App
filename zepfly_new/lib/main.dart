import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'services/firebase_notification_service.dart';

// =========================
// BACKGROUND MESSAGE HANDLER
// =========================

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Local notification will be handled by FirebaseNotificationService
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================
  // FIREBASE INIT
  // =========================

  await Firebase.initializeApp();

  // =========================
  // TIMEZONE INIT
  // =========================

  tz.initializeTimeZones();

  // =========================
  // INITIALIZE FIREBASE NOTIFICATIONS
  // =========================

  await FirebaseNotificationService.initializeNotifications();

  // =========================
  // SET BACKGROUND MESSAGE HANDLER
  // =========================

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // =========================
  // RUN APP
  // =========================

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "PunchIn Pro",

      // =========================
      // THEME
      // =========================
      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.dark,

      // =========================
      // ROUTES
      // =========================
      initialRoute: AppRoutes.splash,

      routes: AppRoutes.routes,
    );
  }
}
