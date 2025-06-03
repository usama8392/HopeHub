import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/message.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to the NextPage after 6 seconds
    Timer(Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffC77398), // Set background color
      body: Center(
        child: Image.asset("assets/videos/page.gif",
        ),
        // GIF animation
      ),
    );
  }
}


