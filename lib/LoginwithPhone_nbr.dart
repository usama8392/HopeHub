import 'package:flutter/material.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/message.dart';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.verificationId});
  final String verificationId;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes =
  List.generate(6, (index) => FocusNode());

  bool isLoading = false;

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Container(
            color: Color(0xFFD1A2B8),
            width: double.infinity,
            padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Text(
                    'OTP Verification',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),

          SizedBox(height: 250.0),
          Text(
            'We have sent the verification code to your registered email/phone number',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 30.0),

          // OTP Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return Container(
                height: 60.0,
                width: 50.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextField(
                  controller: otpControllers[index],
                  focusNode: focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (value) => _onOtpChanged(value, index),
                ),
              );
            }),
          ),

          SizedBox(height: 20.0),
          Text(
            'Didn’t receive OTP?',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5.0),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          OTPScreen(verificationId: widget.verificationId)));
            },
            child: Text(
              'Resend code',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD1A2B8),
              ),
            ),
          ),

          SizedBox(height: 20),
          isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });

              try {
                String otp = otpControllers.map((c) => c.text).join();
                final cred = PhoneAuthProvider.credential(
                    verificationId: widget.verificationId, smsCode: otp);

                await FirebaseAuth.instance.signInWithCredential(cred);

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioRecorderPage(),
                    ));
              } catch (e) {
                log(e.toString());
              }
              setState(() {
                isLoading = false;
              });
            },
            child: Text(
              "Confirm",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

