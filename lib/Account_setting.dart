import 'package:flutter/material.dart';
import 'package:hopehub/Account_setting.dart';
import 'package:hopehub/Change_Password1.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/Change_Email.dart';

import 'package:hopehub/Changephonenumber.dart';
import 'package:hopehub/Main_Menu.dart';
import 'package:hopehub/New_Emial.dart';
import 'package:hopehub/Newphonenbr.dart';
import 'package:hopehub/message.dart';


class Accountsetting extends StatefulWidget {
  const Accountsetting({super.key});

  @override
  State<Accountsetting> createState() => _AccountsettingState();
}

class _AccountsettingState extends State<Accountsetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffC77398),
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: Color(0xffC77398),
        elevation: 0,
        title: Text('Account Setting', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Color(0xffC77398),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Icon(
              Icons.settings,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'Account Setting',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      icon: Icons.phone,
                      text: 'Change phone number',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChangePhoneNumber()));
                      },
                    ),
                    SizedBox(height: 40),
                    CustomButton(
                      icon: Icons.email,
                      text: 'Change Email address',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChangeEmail()));
                      },
                    ),
                    SizedBox(height: 40),
                    CustomButton(
                      icon: Icons.lock,
                      text: 'Change Password',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PasswordOne()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        backgroundColor: Color(0xffC77398),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Custom header with brain image and "MAIN MENU" text
          Container(
            height: 180, // Adjust height as needed
            decoration: const BoxDecoration(
              color: Color(0xffC77398),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brain image
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/videos/brain.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "MAIN MENU" text
                const Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Rest of your existing menu items
          ListTile(
            leading: const Icon(
              Icons.new_releases,
              color: Color(0xffC77398),
            ),
            title: const Text('New Chat'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioRecorderPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: Color(0xffC77398),
            ),
            title: const Text('Chat History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: Color(0xffC77398),
            ),
            title: const Text('Account Setting'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Accountsetting()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Color(0xffC77398),
            ),
            title: const Text('Logout'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}





