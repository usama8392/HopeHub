import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/LoginwithPhone_nbr.dart';
import 'package:hopehub/Main_Menu.dart';
import 'package:hopehub/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hopehub/landing_page.dart';
import 'package:hopehub/message.dart';
import 'screens/audio controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintSizeEnabled = false;
  await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MaterialApp(


    debugShowCheckedModeBanner: false,
    initialRoute: 'login',
    routes: {'login': (context)=> LandingPage()},
  ));
}
class MyApp extends StatelessWidget {
   MyApp({super.key});
  final nameController= TextEditingController();
  final occupationController= TextEditingController();
   final cnicController= TextEditingController();
   final dateOfBirthController= TextEditingController();
   final additionalFieldController= TextEditingController();
   final confirmPasswordController= TextEditingController();
   final passwordController= TextEditingController();
   String? gender; // For gender radio buttons
   String? maritalStatus;



  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

