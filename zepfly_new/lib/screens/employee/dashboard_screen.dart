import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hold_down_button/hold_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../routes/app_routes.dart';

import '../../services/announcement_service.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isPunching = false;
  final AttendanceService attendanceService = AttendanceService();

  final AuthService authService = AuthService();

  final AnnouncementService announcementService = AnnouncementService();

  final double officeLat = 26.942596;

  final double officeLng = 75.726550;

  bool isLoading = false;

  bool reminderShown = false;

  String attendanceStatus = "Not Punched In";

  String currentTime = "";

  String userName = "Employee";

  String profileImage = "";

  Timer? timer;

  Timer? reminderTimer;

  List latestAnnouncements = [];

  @override
  void initState() {
    super.initState();

    startClock();

    getUserData();

    getLatestAnnouncements();

    getTodayAttendance();

    _requestNotificationPermission();

    _startPunchReminderWatcher();

    FcmService.initialize();
  }

  // =====================================
  // USER DATA
  // =====================================

  Future<void> getUserData() async {
    final name = await authService.getUserName();

    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = name;

      profileImage = prefs.getString("profileImage") ?? "";
    });
  }

  // =====================================
  // ANNOUNCEMENTS
  // =====================================

  Future<void> getLatestAnnouncements() async {
    final announcements = await announcementService.getLatestAnnouncements();

    if (!mounted) return;

    setState(() {
      latestAnnouncements = announcements;
    });
  }

  // =====================================
  // ATTENDANCE
  // =====================================

  Future<void> getTodayAttendance() async {
    try {
      final response = await attendanceService.getTodayAttendance();

      final attendance = response["attendance"];

      if (!mounted) return;

      setState(() {
        if (attendance == null) {
          attendanceStatus = "Not Punched In";
        } else if (attendance["punchOutTime"] == null) {
          attendanceStatus = "Present";
        } else {
          attendanceStatus = "Punched Out";
        }
      });
    } catch (e) {
      setState(() {
        attendanceStatus = "Not Punched In";
      });
    }
  }

  // =====================================
  // CLOCK
  // =====================================

  void startClock() {
    updateClock();

    timer = Timer.periodic(const Duration(seconds: 1), (_) => updateClock());
  }

  void updateClock() {
    final now = DateTime.now();

    if (!mounted) return;

    setState(() {
      currentTime =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
    });
  }

  // =====================================
  // PUNCH IN
  // =====================================

  Future<void> punchIn() async {
    if (attendanceStatus == "Present") {
      _showMessage("Already Punched In");

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final insideOffice = await _isInsideOfficeRange();

      if (!insideOffice) {
        _showMessage("You are outside office range");

        return;
      }

      final response = await attendanceService.punchIn();

      final success = response["success"] != false;

      if (success) {
        await getTodayAttendance();
      }

      _showMessage(response["message"] ?? "Punch In Success");
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================
  // PUNCH OUT
  // =====================================

  Future<void> punchOut() async {
    if (attendanceStatus != "Present") {
      _showMessage("Please Punch In First");

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await attendanceService.punchOut();

      final success = response["success"] != false;

      if (success) {
        await getTodayAttendance();
      }

      _showMessage(response["message"] ?? "Punch Out Success");
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================
  // LOCATION
  // =====================================

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<bool> _isInsideOfficeRange() async {
    final position = await _getCurrentPosition();

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      officeLat,
      officeLng,
    );

    return distance <= 200;
  }

  // =====================================
  // NOTIFICATIONS
  // =====================================

  void _startPunchReminderWatcher() {
    reminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => checkPunchReminder(),
    );
  }

  Future<void> checkPunchReminder() async {
    final now = DateTime.now();

    if (now.hour != 10 || now.minute > 5 || reminderShown) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final todayKey = _dateKey(now);

    if (prefs.getString("lastPunchReminderDate") == todayKey) {
      reminderShown = true;

      return;
    }

    try {
      final insideOffice = await _isInsideOfficeRange();

      if (!insideOffice) return;

      reminderShown = true;

      await prefs.setString("lastPunchReminderDate", todayKey);

      await _showPunchReminderNotification();
    } catch (_) {}
  }

  Future<void> _showPunchReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      "punch_in_reminder_channel",
      "Punch In Reminder",
      channelDescription: "Reminder shown near office",
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Show punch-in reminder notification
    try {
      // This is handled by FirebaseNotificationService
      // Keeping this code for local reminder functionality
      debugPrint('Punch In Reminder triggered at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Error showing punch-in reminder: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    // Permissions are already requested in FirebaseNotificationService
    debugPrint('Notification permission check completed');
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // =====================================
  // LOGOUT
  // =====================================

  void logout() async {
    await authService.logoutUser();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  // =====================================
  // MESSAGE
  // =====================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    timer?.cancel();

    reminderTimer?.cancel();

    super.dispose();
  }

  // =====================================
  // UI
  // =====================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07112B),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================
              // TOP BAR
              // =====================================
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.profile);
                      getUserData();
                    },

                    child: CircleAvatar(
                      radius: 28,

                      backgroundColor: Colors.blue,

                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,

                      child: profileImage.isEmpty
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : "E",

                              style: const TextStyle(
                                color: Colors.white,

                                fontSize: 20,

                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),

                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.adminPin);
                    },
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  IconButton(
                    onPressed: logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // =====================================
              // STATUS CARD
              // =====================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,

                    colors: [Color(0xFF2962FF), Color(0xFF00C6FF)],
                  ),

                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.35),

                      blurRadius: 18,

                      spreadRadius: 2,

                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Current Time",

                      style: TextStyle(
                        color: Colors.white70,

                        fontSize: 18,

                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      currentTime,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 42,

                        fontWeight: FontWeight.bold,

                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.only(left: 4),

                      child: Text(
                        attendanceStatus,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 22,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =====================================
              // HOLD BUTTON
              // =====================================
              GestureDetector(
                onLongPress: () async {
                  if (isPunching) return;

                  setState(() {
                    isPunching = true;
                  });

                  await Future.delayed(const Duration(seconds: 1));

                  await punchIn();

                  setState(() {
                    isPunching = false;
                  });
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),

                  width: double.infinity,

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [Color(0xFF1ED760), Color(0xFF06A94D)],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.35),

                        blurRadius: 18,

                        spreadRadius: 2,

                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 58,

                        height: 58,

                        decoration: const BoxDecoration(
                          color: Colors.white,

                          shape: BoxShape.circle,
                        ),

                        child: isPunching
                            ? const Padding(
                                padding: EdgeInsets.all(14),

                                child: CircularProgressIndicator(
                                  strokeWidth: 3,

                                  color: Colors.green,
                                ),
                              )
                            : const Icon(
                                Icons.fingerprint,

                                color: Colors.green,

                                size: 30,
                              ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              isPunching
                                  ? "Punching In..."
                                  : "Hold to Punch In",

                              style: const TextStyle(
                                color: Colors.white,

                                fontSize: 22,

                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              isPunching
                                  ? "Please wait..."
                                  : "Hold fingerprint for 1 second",

                              style: const TextStyle(
                                color: Colors.white70,

                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),

                        child: isPunching
                            ? const SizedBox(
                                width: 28,

                                height: 28,

                                child: CircularProgressIndicator(
                                  strokeWidth: 3,

                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward,

                                color: Colors.white,

                                size: 30,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // =====================================
              // PUNCH OUT
              // =====================================
              GestureDetector(
                onTap: punchOut,

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),

                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    vertical: 20,

                    horizontal: 22,
                  ),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [Color(0xFFFF4B4B), Color(0xFFFF2D2D)],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.35),

                        blurRadius: 18,

                        spreadRadius: 2,

                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 24),

                      SizedBox(width: 12),

                      Text(
                        "Punch Out",

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 22,

                          fontWeight: FontWeight.bold,

                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =====================================
              // ANNOUNCEMENTS
              // =====================================
              const Center(
                child: Text(
                  "Latest Announcements",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              latestAnnouncements.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.campaign_rounded,
                              color: Colors.orange,
                              size: 42,
                            ),

                            SizedBox(height: 14),

                            Text(
                              "No Announcements Yet",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              "Waiting For Announcements",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: latestAnnouncements.map((announcement) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: Colors.cyanAccent,
                                size: 34,
                              ),

                              const SizedBox(height: 14),

                              Text(
                                announcement["title"] ?? "",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                announcement["message"] ?? "",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
