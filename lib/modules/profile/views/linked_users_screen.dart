import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/widgets/app_cached_image.dart';
import '../../../core/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/linked_users_controller.dart';

class LinkedUsersScreen extends StatelessWidget {
  LinkedUsersScreen({super.key});

  final LinkedUsersController controller = Get.put(LinkedUsersController());
  final AuthController auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    final h = Get.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Manage Care Receivers",
          style: GoogleFonts.nunito(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () => controller.showAddDialog(),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF7AB7A7)),
          );
        }

        if (controller.linkedUsers.isEmpty) {
          return Center(
            child: Text(
              "No linked users found.",
              style: GoogleFonts.nunito(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.015),
          itemCount: controller.linkedUsers.length,
          itemBuilder: (_, index) {
            final UserModel user = controller.linkedUsers[index];

            return Container(
              margin: EdgeInsets.only(bottom: h * 0.02),
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(w * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  AppCachedAvatar(
                    radius: w * 0.10,
                    backgroundColor: Colors.grey.shade200,
                    imageUrl: (user.profileImage != null && user.profileImage!.startsWith("http"))
                        ? user.profileImage
                        : null,
                    iconFallback: Icons.person,
                    iconColor: Colors.grey,
                  ),

                  SizedBox(width: w * 0.04),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName ?? "Unknown",
                          style: GoogleFonts.nunito(
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Care ID: ${user.careId ?? '-'}",
                          style: GoogleFonts.nunito(
                            color: Colors.black54,
                            fontSize: w * 0.034,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: w * 0.08),
                    onPressed: () => controller.removeLink(user),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
