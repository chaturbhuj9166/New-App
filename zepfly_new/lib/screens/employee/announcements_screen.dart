import 'package:flutter/material.dart';

import '../../services/announcement_service.dart';

import 'announcement_detail_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AnnouncementService announcementService = AnnouncementService();

  List announcements = [];

  List filteredAnnouncements = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  // =========================
  // GET ANNOUNCEMENTS
  // =========================

  Future<void> getAnnouncements() async {
    try {
      final response = await announcementService.getAnnouncements();

      if (!mounted) return;

      if (response["success"] == true) {
        setState(() {
          announcements = response["announcements"] ?? [];

          filteredAnnouncements = announcements;

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // FILTER
  // =========================

  void filterAnnouncements() {
    List tempAnnouncements = announcements;

    // SEARCH

    if (searchController.text.isNotEmpty) {
      tempAnnouncements = tempAnnouncements.where((announcement) {
        final title = announcement["title"]?.toString().toLowerCase() ?? "";

        return title.contains(searchController.text.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredAnnouncements = tempAnnouncements;
    });
  }

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
          "Announcements",

          style: TextStyle(color: Colors.white),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SEARCH
                Padding(
                  padding: const EdgeInsets.all(15),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {
                      filterAnnouncements();
                    },

                    style: const TextStyle(color: Colors.white),

                    decoration: InputDecoration(
                      hintText: "Search Announcements",

                      hintStyle: const TextStyle(color: Colors.white54),

                      prefixIcon: const Icon(Icons.search, color: Colors.white),

                      filled: true,

                      fillColor: Colors.white10,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // TOTAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        "Total Announcements: ${filteredAnnouncements.length}",

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 16,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed: getAnnouncements,

                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // LIST
                Expanded(
                  child: filteredAnnouncements.isEmpty
                      ? const Center(
                          child: Text(
                            "No Announcements Found",

                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),

                          itemCount: filteredAnnouncements.length,

                          itemBuilder: (context, index) {
                            final announcement = filteredAnnouncements[index];

                            final String title =
                                announcement["title"] ?? "No Title";

                            final String description =
                                announcement["description"] ?? "No Description";

                            final String status =
                                announcement["status"] ?? "Unread";

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
                                  // TOP ROW
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,

                                          maxLines: 2,

                                          overflow: TextOverflow.ellipsis,

                                          style: const TextStyle(
                                            color: Colors.white,

                                            fontSize: 22,

                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,

                                          vertical: 8,
                                        ),

                                        decoration: BoxDecoration(
                                          color: status == "Seen"
                                              ? Colors.green
                                              : Colors.orange,

                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child: Text(
                                          status,

                                          style: const TextStyle(
                                            color: Colors.white,

                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // DESCRIPTION
                                  Text(
                                    description,

                                    style: const TextStyle(
                                      color: Colors.white70,

                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // REPLY BOX
                                Container(

  width: double.infinity,

  padding: const EdgeInsets.all(15),

  decoration: BoxDecoration(

    color: Colors.black26,

    borderRadius: BorderRadius.circular(18),

  ),

  child: Column(

    crossAxisAlignment:
    CrossAxisAlignment.start,

    children: [

      const Text(

        "Replies",

        style: TextStyle(

          color: Colors.white,

          fontWeight: FontWeight.bold,

          fontSize: 16,

        ),

      ),

      const SizedBox(height: 15),

      replies.isEmpty

      ? const Text(

          "No Replies Yet",

          style: TextStyle(

            color: Colors.white70,

          ),

        )

      : Column(

          children: replies.map<Widget>((replyData) {

            final user =
            replyData["user"];

            final message =
            replyData["message"] ?? "";

            final userName =
            user != null

            ? user["name"] ?? "Employee"

            : "Employee";

            return Container(

              margin:
              const EdgeInsets.only(bottom: 12),

              padding:
              const EdgeInsets.all(12),

              decoration: BoxDecoration(

                color: Colors.white10,

                borderRadius:
                BorderRadius.circular(14),

              ),

              child: Row(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const CircleAvatar(

                    backgroundColor:
                    Colors.blue,

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

                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height: 5),

                        Text(

                          message,

                          style: const TextStyle(

                            color: Colors.white70,

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

  ),


                                  const SizedBox(height: 20),

                                  // BUTTON
                                  SizedBox(
                                    width: double.infinity,

                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,

                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),

                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),

                                      onPressed: () {
                                        Navigator.push(
                                          context,

                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AnnouncementDetailScreen(
                                                  announcement: announcement,
                                                ),
                                          ),
                                        );
                                      },

                                      icon: const Icon(Icons.open_in_new),

                                      label: const Text("Open Announcement"),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
