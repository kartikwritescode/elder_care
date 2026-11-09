import 'dart:io';
import 'package:elder_care/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/widgets/app_cached_image.dart';

import '../controllers/profile_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.find<AuthController>();
  ProfileController get controller => Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final h = Get.height;
    final w = Get.width;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,

      body: RefreshIndicator(
        onRefresh: () =>controller.refreshProfile(),
        child: Container(
          width: w,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/auth/login_bg.png"),
              fit: BoxFit.cover,
              opacity: 0.12,
            ),
            gradient: LinearGradient(
              colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            children: [

              SizedBox(height: h * 0.035),

              /// ---------- HEADER ----------
              Center(
                child: Text(
                  "Profile",
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.08,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),

              /// ---------------------------------------
              /// PROFILE AVATAR + NAME + EMAIL + ROLE
              /// ---------------------------------------
              Obx(() {
                final user = authController.user.value;
                final imageUrl = user?.profileImage;

                return Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() => EditProfileScreen(),
                            transition: Transition.cupertino,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            /// HERO AVATAR WRAPPER
                            Hero(
                              tag: "profile-avatar",
                              child: Container(
                                padding: EdgeInsets.all(w * 0.006),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: AppCachedAvatar(
                                  radius: w * 0.18,
                                  backgroundColor: Colors.grey.shade100,
                                  imageUrl: (imageUrl != null && imageUrl.startsWith("http"))
                                      ? imageUrl
                                      : null,
                                  localFile: (imageUrl != null && !imageUrl.startsWith("http") && imageUrl.isNotEmpty)
                                      ? File(imageUrl)
                                      : null,
                                  iconFallback: Icons.person,
                                  iconColor: Colors.grey,
                                ),
                              ),
                            ),

                            /// Upload Loader Overlay
                            if (controller.isUploading.value)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: w * 0.08,
                                      height: w * 0.08,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            /// EDIT BUTTON
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: GestureDetector(
                            //     onTap: () {
                            //       Get.to(() => EditProfileScreen(),
                            //         transition: Transition.rightToLeftWithFade,
                            //         duration: const Duration(milliseconds: 300),
                            //       );
                            //     },
                            //     child: Container(
                            //       width: w * 0.12,
                            //       height: w * 0.12,
                            //       decoration: BoxDecoration(
                            //         color: Colors.white,
                            //         shape: BoxShape.circle,
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black26,
                            //             blurRadius: 6,
                            //             offset: Offset(0, 3),
                            //           )
                            //         ],
                            //       ),
                            //       child: CircleAvatar(
                            //         backgroundColor: const Color(0xFF7AB7A7),
                            //         child: Icon(Icons.edit, color: Colors.white, size: w * 0.06),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),


                    SizedBox(height: h * 0.025),

                    /// Name
                    Hero(
                      tag: "profile-name",
                      child: Text(
                        user?.fullName ?? "Loading...",
                        style: GoogleFonts.nunito(
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.006),

                    /// Email
                    Text(
                      user?.email ?? "",
                      style: GoogleFonts.nunito(
                        fontSize: w * 0.038,
                        color: Colors.black54,
                      ),
                    ),

                    SizedBox(height: h * 0.01),

                    /// Role + Care ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.03,
                            vertical: h * 0.006,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F8F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role?.capitalizeFirst ?? "Role not set",
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF007B6F),
                              fontWeight: FontWeight.w700,
                              fontSize: w * 0.039,
                            ),
                          ),
                        ),

                        if (user?.careId != null) ...[
                          SizedBox(width: w * 0.03),
                          Text(
                            "•  Care ID: ${user!.careId}",
                            style: GoogleFonts.nunito(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                );
              }),

              SizedBox(height: h * 0.03),

              /// --------------------------------------
              ///  BIG CARD : ACCOUNT + SETTINGS
              /// --------------------------------------
              Card(
                elevation: 12,
                shadowColor: Colors.black26,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.06),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.03),
                  child: Column(
                    children: [

                      _menuTile(
                        icon: Icons.person_outline,
                        label: "Edit Profile",
                        onTap: controller.onEditProfileTap,
                        w: w,
                      ),
                      Divider(color: Colors.grey.shade200),

                      _menuTile(
                        icon: Icons.link,
                        label: (authController.user.value?.role == "caregiver")
                            ? "Manage Care Receivers"
                            : "My Caregivers",
                        onTap: controller.onLinkedTap,
                        w: w,
                      ),
                      Divider(color: Colors.grey.shade200),

                      _menuTile(
                        icon: Icons.privacy_tip_outlined,
                        label: "Privacy & Security",
                        onTap: controller.onPrivacyTap,
                        w: w,
                      ),
                      Divider(color: Colors.grey.shade200),

                      _menuTile(
                        icon: Icons.help_outline,
                        label: "Help & Support",
                        onTap: controller.onHelpTap,
                        w: w,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.025),

              /// ---------------- LOGOUT BUTTON ----------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.onLogoutTap,
                  icon: Icon(Icons.logout, size: w * 0.045),
                  label: Text(
                    "Log Out",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: w * 0.040,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: h * 0.014),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                    elevation: 6,
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),

              /// Footer
              Center(
                child: Text(
                  "ElderCare v1.0.1",
                  style: GoogleFonts.nunito(
                    color: Colors.black45,
                    fontSize: w * 0.032,
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }


  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double w,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: const Color(0xFF7AB7A7).withValues(alpha: 0.15),

        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.010),
          child: Row(
            children: [

              /// Icon box
              Container(
                width: w * 0.10,
                height: w * 0.10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF0B6B60), size: w * 0.055),
              ),

              SizedBox(width: w * 0.03),

              /// Label
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.044,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(Icons.arrow_forward_ios, size: w * 0.035, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

}
