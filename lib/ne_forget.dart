import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hopehub/Login.dart';

class NewPasswordScreen extends StatefulWidget {
  final String verificationId; // For phone auth
  final String? email;        // For email auth
  final String? phoneNumber;  // For phone auth

  const NewPasswordScreen({
    Key? key,
    this.verificationId = '',
    this.email,
    this.phoneNumber,
  }) : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showNotification = false;
  String _notificationMessage = '';
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showTopNotification(String message, {bool isError = true}) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotification = false);
    });
  }

  Future<void> _updatePassword() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      // For phone auth users (if applicable)
      if (widget.verificationId.isNotEmpty) {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId,
          smsCode: _passwordController.text, // Note: In a real app, OTP should be separate
        );
        await _auth.signInWithCredential(credential);
      }

      // Update password in Firebase Auth
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(_passwordController.text);

        // ✅ Update Firestore (in 'clients' collection)
        await _firestore
            .collection('client')
            .doc(user.uid) // Assuming user UID is the document ID
            .update({
          'password': _passwordController.text, // ⚠️ Avoid in production (just for demo)
          'lastPasswordUpdate': FieldValue.serverTimestamp(), // Best practice
        });

        _showTopNotification('Password updated successfully!', isError: false);
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Login()),
                (route) => false,
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      _showTopNotification('Error: ${e.message}');
    } catch (e) {
      _showTopNotification('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      _showTopNotification('Please fill all fields');
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showTopNotification('Password must be 6+ characters');
      return false;
    }

    if (_passwordController.text != _confirmController.text) {
      _showTopNotification('Passwords do not match');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffC77398),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xffC77398),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'Set New Password',
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 40),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock, color: Color(0xffC77398)),
                              hintText: 'New Password',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xffC77398),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline, color: Color(0xffC77398)),
                              hintText: 'Confirm Password',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xffC77398),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                              backgroundColor: Color(0xffC77398),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _updatePassword,
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showNotification)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: _notificationMessage.contains('success') ? Colors.green : Colors.red,
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    _notificationMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}