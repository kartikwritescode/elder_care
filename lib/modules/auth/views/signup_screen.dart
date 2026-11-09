import 'package:elder_care/modules/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../widgets/social_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController authController = Get.find<AuthController>();
  // final CareLinkController careLinkController = Get.find<CareLinkController>();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final h = Get.height;
    final w = Get.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: h,
          width: w,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.08),

              // Screen Title
              Text(
                "Join ElderCare",
                style: GoogleFonts.nunito(
                  fontSize: w * 0.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.008),
              Text(
                "Create an account to start caring",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: w * 0.04,
                  color: Colors.black54,
                ),
              ),

              SizedBox(height: h * 0.05),

              // Sign-Up Card
              Card(
                elevation: 12,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.06),
                ),
                color: Colors.white.withAlpha(92),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.035),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: authController.nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter your name';
                            if (value.trim().length < 3) return 'Name must be at least 3 characters';
                            return null;
                          },
                          decoration: _inputDecoration('Name', Icons.person, w),
                        ),
                        SizedBox(height: h * 0.025),

                        // Email
                        TextFormField(
                          controller: authController.emailController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter your email';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                            return null;
                          },
                          decoration: _inputDecoration('Email', Icons.email_outlined, w),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: h * 0.025),

                        // Password
                        TextFormField(
                          controller: authController.passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter your password';
                            if (value.trim().length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          decoration: _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                            w,
                            trailingIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.025),

                        // Confirm Password
                        TextFormField(
                          controller: authController.confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please confirm your password';
                            if (value.trim() != authController.passwordController.text.trim()) return 'Passwords do not match';
                            return null;
                          },
                          decoration: _inputDecoration(
                            'Confirm Password',
                            Icons.lock,
                            w,
                            trailingIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.04),

                        // Sign Up Button
                        Obx(() => ElevatedButton(
                          onPressed: authController.isLoading.value
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) {
                              authController.signUp();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7AB7A7),
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, h * 0.065),
                            textStyle: GoogleFonts.nunito(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(w * 0.04),
                            ),
                            elevation: 6,
                          ),
                          child: authController.isLoading.value
                              ? SizedBox(
                            height: w * 0.05,
                            width: w * 0.05,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text("Sign Up"),
                        )),

                        SizedBox(height: h * 0.03),

                        // Divider + Continue With
                        Row(
                          children: [
                            Expanded(
                              child: Divider(thickness: 1, color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                              child: Text(
                                "or continue with",
                                style: GoogleFonts.nunito(color: Colors.grey, fontSize: w * 0.035),
                              ),
                            ),
                            Expanded(
                              child: Divider(thickness: 1, color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                        SizedBox(height: h * 0.02),

                        // Social Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            socialButton("Google", "assets/auth/google.png", w, h),
                            SizedBox(width: w * 0.05),
                            socialButton("Facebook", "assets/auth/facebook.png", w, h),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.035),

              // Already have account?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.nunito(fontSize: w * 0.038, color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      "Login",
                      style: GoogleFonts.nunito(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7AB7A7),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, double w, {Widget? trailingIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal.shade400),
      suffixIcon: trailingIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(w * 0.05),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(w * 0.05),
        borderSide: BorderSide(color: Colors.teal.shade300, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: w * 0.035, horizontal: w * 0.04),
    );
  }


}
