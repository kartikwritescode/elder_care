import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/care_link_controller.dart';

class CareLinkScreen extends StatelessWidget {
  CareLinkScreen({super.key});

  final CareLinkController controller = Get.isRegistered<CareLinkController>()
      ? Get.find<CareLinkController>()
      : Get.put(CareLinkController());

  @override
  Widget build(BuildContext context) {
    final h = Get.height;
    final w = Get.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: h,
        width: w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage("assets/images/role2.png"),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text(
                  "Build Your Care Connection",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.08,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: h * 0.01),

                Text(
                  "Enter the 6-digit Care ID shared with you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.04,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: h * 0.06),


                _otpInputRow(w, h),

                SizedBox(height: h * 0.06),


                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.linkToReceiver(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AB7A7),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, h * 0.065),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.04),
                    ),
                    elevation: 6,
                  ),
                  child: controller.isLoading.value
                      ? SizedBox(
                    height: w * 0.06,
                    width: w * 0.06,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    "Link Now",
                    style: TextStyle(
                      fontSize: w * 0.048,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _otpInputRow(double w, double h) {
    final List<TextEditingController> boxes =
    List.generate(6, (_) => TextEditingController());
    final List<FocusNode> nodes =
    List.generate(6, (_) => FocusNode());

    void updateValue() {
      controller.careIdController.text = boxes.map((e) => e.text).join();
    }

    return StatefulBuilder(builder: (context, setState) {

      for (int i = 0; i < 6; i++) {
        boxes[i].addListener(() {
          final text = boxes[i].text;


          if (text.length > 1) {
            final chars = text.split("");

            for (int j = 0; j < 6; j++) {
              boxes[j].text = j < chars.length ? chars[j] : "";
            }

            FocusScope.of(context).unfocus();
            updateValue();
          }
        });
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return SizedBox(
            width: w * 0.12,
            height: w * 0.14,
            child: TextField(
              controller: boxes[index],
              focusNode: nodes[index],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                height: 1.1,
                fontSize: w * 0.065,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.teal.shade300, width: 2),
                ),
              ),


              onChanged: (value) {

                if (value.length > 1) {
                  boxes[index].text = value.substring(0, 1);
                }

                if (value.isNotEmpty) {
                  if (index < 5) {
                    FocusScope.of(context).requestFocus(nodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                } else {
                  if (index > 0) {
                    FocusScope.of(context).requestFocus(nodes[index - 1]);
                  }
                }

                updateValue();
              },
            ),
          );
        }),
      );
    });
  }

}
