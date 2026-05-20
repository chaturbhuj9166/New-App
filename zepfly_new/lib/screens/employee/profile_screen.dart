import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';

import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();

}

class _ProfileScreenState
extends State<ProfileScreen> {

  final AuthService authService =
      AuthService();

  final TextEditingController
  nameController =
  TextEditingController();

  final TextEditingController
  emailController =
  TextEditingController();

  String userRole = "employee";

  String profileImage = "";

  bool isLoading = false;

  File? selectedImage;

  final ImagePicker picker =
      ImagePicker();

  // =========================
  // LOAD USER DATA
  // =========================

  Future<void> loadUserData()
  async {

    SharedPreferences prefs =
    await SharedPreferences
    .getInstance();

    setState(() {

      nameController.text =
          prefs.getString(
            "userName",
          ) ??
          "";

      emailController.text =
          prefs.getString(
            "userEmail",
          ) ??
          "";

      userRole =
          prefs.getString(
            "userRole",
          ) ??
          "employee";

      profileImage =
          prefs.getString(
            "profileImage",
          ) ??
          "";

    });

  }

  // =========================
  // PICK IMAGE
  // =========================

  Future<void> pickImage()
  async {

    final XFile? image =
    await picker.pickImage(

      source:
      ImageSource.gallery,

      imageQuality: 70,

    );

    if(image != null){

      setState(() {

        selectedImage =
            File(image.path);

      });

    }

  }

  // =========================
  // UPLOAD IMAGE
  // =========================

  Future<String?> uploadImage()
  async {

    if(selectedImage == null){

      return null;

    }

    try {

      var request =
      http.MultipartRequest(

        "POST",

        Uri.parse(

          "${ApiService.baseUrl}/upload/profile",

        ),

      );

      request.files.add(

        await http.MultipartFile
        .fromPath(

          "image",

          selectedImage!.path,

        ),

      );

      var response =
      await request.send();

      var responseData =
      await response.stream
      .bytesToString();

      var data =
      jsonDecode(responseData);

      if(data["success"] == true){

        return data["imageUrl"];

      }

      return null;

    }

    catch(error){

      return null;

    }

  }

  // =========================
  // UPDATE PROFILE
  // =========================

  Future<void> updateProfile()
  async {

    setState(() {

      isLoading = true;

    });

    String uploadedImage =
        profileImage;

    if(selectedImage != null){

      final imageUrl =
      await uploadImage();

      if(imageUrl != null){

        uploadedImage =
            imageUrl;

      }

    }

    final response =
    await authService
    .updateProfile(

      name:
      nameController.text.trim(),

      email:
      emailController.text.trim(),

      profileImage:
      uploadedImage,

    );

    SharedPreferences prefs =
    await SharedPreferences
    .getInstance();

    await prefs.setString(

      "profileImage",

      uploadedImage,

    );

    setState(() {

      profileImage =
          uploadedImage;

      isLoading = false;

    });

    ScaffoldMessenger.of(context)
    .showSnackBar(

      SnackBar(

        content: Text(

          response["message"],

        ),

      ),

    );

  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logoutUser()
  async {

    await authService
    .logoutUser();

    if(!mounted) return;

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(

        builder: (context) =>
        const LoginScreen(),

      ),

      (route) => false,

    );

  }

  @override
  void initState() {

    super.initState();

    loadUserData();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFF0F172A),

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        centerTitle: true,

        title: const Text(

          "Profile",

          style: TextStyle(
            color: Colors.white,
          ),

        ),

      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(
              height: 20,
            ),

            // =========================
            // PROFILE IMAGE
            // =========================

            Stack(

              children: [

                CircleAvatar(

                  radius: 65,

                  backgroundColor:
                  Colors.blue,

                  backgroundImage:

                  selectedImage != null

                  ? FileImage(
                      selectedImage!,
                    )

                  : profileImage
                  .isNotEmpty

                  ? NetworkImage(
                      profileImage,
                    )

                  : null,

                  child:

                  selectedImage == null &&
                  profileImage.isEmpty

                  ? Text(

                      nameController
                      .text
                      .isNotEmpty

                      ? nameController
                      .text[0]
                      .toUpperCase()

                      : "E",

                      style:
                      const TextStyle(

                        fontSize: 42,

                        color:
                        Colors.white,

                        fontWeight:
                        FontWeight.bold,

                      ),

                    )

                  : null,

                ),

                Positioned(

                  bottom: 0,

                  right: 0,

                  child: GestureDetector(

                    onTap: pickImage,

                    child: Container(

                      padding:
                      const EdgeInsets.all(12),

                      decoration:
                      BoxDecoration(

                        color:
                        Colors.white,

                        shape:
                        BoxShape.circle,

                        boxShadow: [

                          BoxShadow(

                            color: Colors
                            .black
                            .withOpacity(0.2),

                            blurRadius: 10,

                          ),

                        ],

                      ),

                      child: const Icon(

                        Icons.camera_alt,

                        size: 22,

                      ),

                    ),

                  ),

                ),

              ],

            ),

            const SizedBox(
              height: 35,
            ),

            // NAME FIELD

            TextField(

              controller:
              nameController,

              style:
              const TextStyle(

                color:
                Colors.white,

              ),

              decoration:
              InputDecoration(

                labelText:
                "Name",

                labelStyle:
                const TextStyle(

                  color:
                  Colors.white70,

                ),

                prefixIcon:
                const Icon(

                  Icons.person,

                  color:
                  Colors.white,

                ),

                filled: true,

                fillColor:
                Colors.white10,

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(20),

                  borderSide:
                  BorderSide.none,

                ),

              ),

            ),

            const SizedBox(
              height: 20,
            ),

            // EMAIL FIELD

            TextField(

              controller:
              emailController,

              style:
              const TextStyle(

                color:
                Colors.white,

              ),

              decoration:
              InputDecoration(

                labelText:
                "Email",

                labelStyle:
                const TextStyle(

                  color:
                  Colors.white70,

                ),

                prefixIcon:
                const Icon(

                  Icons.email,

                  color:
                  Colors.white,

                ),

                filled: true,

                fillColor:
                Colors.white10,

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(20),

                  borderSide:
                  BorderSide.none,

                ),

              ),

            ),

            const SizedBox(
              height: 20,
            ),

            // ROLE

            Container(

              width: double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration:
              BoxDecoration(

                color:
                Colors.white10,

                borderRadius:
                BorderRadius.circular(20),

              ),

              child: Row(

                children: [

                  const Icon(

                    Icons.badge,

                    color:
                    Colors.white,

                  ),

                  const SizedBox(
                    width: 15,
                  ),

                  Text(

                    userRole
                    .toUpperCase(),

                    style:
                    const TextStyle(

                      color:
                      Colors.white,

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(
              height: 35,
            ),

            // UPDATE BUTTON

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton(

                onPressed:

                isLoading
                    ? null
                    : updateProfile,

                style:
                ElevatedButton
                .styleFrom(

                  backgroundColor:
                  Colors.blue,

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(18),

                  ),

                ),

                child:

                isLoading

                ? const CircularProgressIndicator(

                    color:
                    Colors.white,

                  )

                : const Text(

                    "Update Profile",

                    style: TextStyle(

                      fontSize: 18,

                    ),

                  ),

              ),

            ),

            const SizedBox(
              height: 20,
            ),

            // LOGOUT BUTTON

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton.icon(

                onPressed:
                logoutUser,

                icon: const Icon(
                  Icons.logout,
                ),

                label: const Text(
                  "Logout",
                ),

                style:
                ElevatedButton
                .styleFrom(

                  backgroundColor:
                  Colors.red,

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(18),

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}