import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../widgets/social_button.dart';
import '../../../modules/auth/views/forgotpassemail_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

    @override
    _LoginScreenState createState()
    => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    // final CareLinkController careLinkController = Get.find<CareLinkController>();
    // final CareLinkController careLinkController = Get.put(CareLinkController(),permanent: true);
    final AuthController authController = Get.find<AuthController>();
    // final DashboardController dashboardController = Get.find<DashboardController>();
    final _formKey = GlobalKey<FormState>();
    bool _isPasswordVisible = false;

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
            padding: EdgeInsets.symmetric(horizontal: w * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Image.asset('assets/images/eldercare_logo.png',height: h*0.17,),
                SizedBox(height: h * 0.01),

                Text(
                  "Welcome to ElderCare",
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.07,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: h * 0.006),

                Text(
                  "Caring made simpler, for your loved ones.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.04,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: h * 0.05),

                Card(
                  elevation: 12,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.06),
                  ),
                  color: Colors.white.withAlpha(92),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.06,
                      vertical: h * 0.035,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          /// EMAIL
                          TextFormField(
                            controller: authController.emailController,
                            decoration: _inputDecoration(
                              'Email',
                              Icons.email_outlined,
                              w,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter your email' : null,
                          ),

                          SizedBox(height: h * 0.025),

                          /// PASSWORD
                          TextFormField(
                            controller: authController.passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: _inputDecoration(
                              'Password',
                              Icons.lock_outline,
                              w,
                              trailingIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                      () => _isPasswordVisible = !_isPasswordVisible,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter your password'
                                : null,
                          ),

                          SizedBox(height: h * 0.008),

                          /// SHOW ONLY ON WRONG PASSWORD
                          Obx(() => authController.wrongPassword.value
                              ? Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Get.to(() => ForgotPasswordEmailScreen()),
                              child: Text(
                                "Forgot Password?",
                                style: GoogleFonts.nunito(
                                  color: Colors.teal.shade600,
                                  fontWeight: FontWeight.w700,
                                  fontSize: w * 0.038,
                                ),
                              ),
                            ),
                          )
                              : const SizedBox()),

                          SizedBox(height: h * 0.04),

                          /// SIGN IN BUTTON
                          Obx(() => ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await authController.logIn();
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
                                : const Text("Sign In"),
                          )),

                          SizedBox(height: h * 0.03),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                                child: Text(
                                  "or continue with",
                                  style: GoogleFonts.nunito(
                                    color: Colors.grey,
                                    fontSize: w * 0.035,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: h * 0.02),

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don’t have an account? ",
                      style: GoogleFonts.nunito(
                          fontSize: w * 0.038, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => SignUpScreen()),
                      child: Text(
                        "Sign Up",
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

    InputDecoration _inputDecoration(String label, IconData icon, double w,
        {Widget? trailingIcon}) {
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
      );
    }
  }
