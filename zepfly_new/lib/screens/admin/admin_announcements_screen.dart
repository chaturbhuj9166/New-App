import 'package:flutter/material.dart';

import '../../services/announcement_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final AnnouncementService announcementService = AnnouncementService();

  List announcements = [];

  bool isLoading = true;

  // =========================================
  // GET ANNOUNCEMENTS
  // =========================================

  Future<void> getAnnouncements() async {
    try {
      final response = await announcementService.getAnnouncements();

      if (response["success"] == true) {
        setState(() {
          announcements = response["announcements"] ?? [];

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================
  // INIT
  // =========================================

  @override
  void initState() {
    super.initState();

    getAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        centerTitle: true,

        title: const Text(
          "Employee Replies",

          style: TextStyle(color: Colors.white),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
          ? const Center(
              child: Text(
                "No Announcements Found",

                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),

              itemCount: announcements.length,

              itemBuilder: (context, index) {
                final announcement = announcements[index];

                final List replies = announcement["replies"] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white10,

                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // TITLE
                      Text(
                        announcement["title"] ?? "No Title",

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 22,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // DESCRIPTION
                      Text(
                        announcement["description"] ?? "",

                        style: const TextStyle(
                          color: Colors.white70,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // REPLY COUNT
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,

                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.blue,

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          "Replies (${replies.length})",

                          style: const TextStyle(
                            color: Colors.white,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // REPLIES
                      replies.isEmpty
                          ? Container(
                              width: double.infinity,

                              padding: const EdgeInsets.all(15),

                              decoration: BoxDecoration(
                                color: Colors.black26,

                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: const Text(
                                "No Replies Yet",

                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : Column(
                              children: replies.map<Widget>((reply) {
                                final user = reply["user"];

                                final userName = user != null
                                    ? user["name"] ?? "Employee"
                                    : "Employee";

                                final message = reply["message"] ?? "";

                                return Container(
                                  width: double.infinity,

                                  margin: const EdgeInsets.only(bottom: 15),

                                  padding: const EdgeInsets.all(15),

                                  decoration: BoxDecoration(
                                    color: Colors.black26,

                                    borderRadius: BorderRadius.circular(18),
                                  ),

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.blue,

                                        child: Icon(
                                          Icons.person,

                                          color: Colors.white,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              userName,

                                              style: const TextStyle(
                                                color: Colors.white,

                                                fontWeight: FontWeight.bold,

                                                fontSize: 16,
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              message,

                                              style: const TextStyle(
                                                color: Colors.white70,

                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
