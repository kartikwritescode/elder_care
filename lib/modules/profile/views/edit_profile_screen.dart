import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/widgets/app_cached_image.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  // final EditProfileController controller = Get.put(EditProfileController());
  final EditProfileController controller = Get.find();
  @override
  Widget build(BuildContext context) {
    final h = Get.height;
    final w = Get.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.nunito(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
      ),
      body: Container(
        width: w,
        height: h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: h * 0.03),
          child: Column(
            children: [
              SizedBox(height: h * 0.10),

              Obx(() {
                final preview = controller.imagePreview.value;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: "profile-avatar",
                      child: AppCachedAvatar(
                        radius: w * 0.20,
                        backgroundColor: Colors.grey.shade100,
                        localFile: controller.selectedImage.value,
                        imageUrl: (controller.selectedImage.value == null && preview.startsWith("http"))
                            ? preview
                            : null,
                        iconFallback: Icons.person,
                        iconColor: Colors.grey,
                      ),
                    ),

                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: controller.pickImage,
                        child: Container(
                          width: w * 0.12,
                          height: w * 0.12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF7AB7A7),
                            child: Icon(Icons.edit, color: Colors.white, size: w * 0.06),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              SizedBox(height: h * 0.03),

              buildField("Full Name", controller.nameController, w),
              SizedBox(height: h * 0.02),

              buildField("Email", controller.emailController, w, email: true),

              SizedBox(height: h * 0.02),
              buildPhoneField(w),
              SizedBox(height: h * 0.04),

              Obx(() {
                return ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                    await controller.saveProfileChanges();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AB7A7),
                    minimumSize: Size(double.infinity, h * 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.04),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    'Save Changes',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: w * 0.045,
                    ),
                  ),
                );
              }),

              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPhoneField(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: w * 0.14,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(w * 0.04),
          ),
          child: Row(
            children: [
              /// COUNTRY PICKER BUTTON
              GestureDetector(
                onTap: _openCountryPicker,
                child: Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.selectedCountryCode.value,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                )),
              ),


              /// PHONE INPUT
              Expanded(
                child: TextField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Enter phone number",
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  void _openCountryPicker() {
    showCountryPicker(
      context: Get.context!,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(20),
        inputDecoration: InputDecoration(
          hintText: "Search country",
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) {
        controller.selectedCountryCode.value = "+${country.phoneCode}";
        // controller.selectedCountryFlag.value = country.flagEmoji;
      },
    );
  }




  Widget buildField(String label, TextEditingController controller, double w,
      {bool email = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.04),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}


BoxDecoration inputFieldDecoration(double w) {
  return BoxDecoration(
    color: const Color(0xFFF6F8F7), // slightly darker than bg
    borderRadius: BorderRadius.circular(w * 0.04),
    border: Border.all(
      color: Colors.black.withValues(alpha: 0.06),
    ),
  );
}

