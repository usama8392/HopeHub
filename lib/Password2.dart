import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/Main_Menu.dart';

class PasswordTwo extends StatefulWidget {
  @override // Removed phoneNumber parameter
  _PasswordTwoState createState() => _PasswordTwoState();
}

class _PasswordTwoState extends State<PasswordTwo> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showNotification = false;
  String _notificationMessage = "";
  bool _isLoading = false;
  bool _showNewPasswordError = false;
  bool _showConfirmPasswordError = false;
  bool _obscureNewPassword = true; // For new password visibility
  bool _obscureConfirmPassword = true; // For confirm password visibility

  void _showTopNotification(String message) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showNotification = false);
      }
    });
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    setState(() {
      _showNewPasswordError = newPassword.isEmpty || newPassword.length < 8;
      _showConfirmPasswordError = confirmPassword != newPassword;
    });

    if (_showNewPasswordError || _showConfirmPasswordError) {
      _showTopNotification('Please enter valid passwords');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update password in Firebase
      await user.updatePassword(newPassword);

      // Navigate to main menu on success
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
            (route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
    } on FirebaseAuthException catch (e) {
      _showTopNotification('Failed to update password: ${e.message}');
    } catch (e) {
      _showTopNotification('An error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  'Change Password',
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
                        // New Password Field with visibility toggle
                        TextField(
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _showNewPasswordError ? 'Minimum 8 characters' : null,
                            counterText: "",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureNewPassword,
                          maxLength: 20,
                          style: TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() => _showNewPasswordError = false),
                        ),
                        SizedBox(height: 20),

                        // Confirm Password Field with visibility toggle
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_reset, color: Colors.white),
                            hintText: 'Confirm new password',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _showConfirmPasswordError ? 'Passwords do not match' : null,
                            counterText: "",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          maxLength: 20,
                          style: TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() => _showConfirmPasswordError = false),
                        ),
                        SizedBox(height: 30),

                        // Update Button
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
              ],
            ),
          ),
          if (_showNotification)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}









class NewOtpPassword extends StatefulWidget {
  final String verificationId;
  final String newPassword;
  final String phoneNumber;

  NewOtpPassword({
    required this.verificationId,
    required this.newPassword,
    required this.phoneNumber,
  });

  @override
  _NewOtpPasswordState createState() => _NewOtpPasswordState();
}

class _NewOtpPasswordState extends State<NewOtpPassword> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  String get otpCode =>
      _otpControllers.map((controller) => controller.text).join();

  void _verifyOtpAndChangePassword() async {
    if (otpCode.length != 6) {
      _showSnackBar("Please enter the full 6-digit OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpCode,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(widget.newPassword);
        _showSnackBar("Password updated successfully!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatHistoryScreen()),
        );
      } else {
        _showSnackBar("No user is currently signed in.");
      }
    } catch (e) {
      _showSnackBar("OTP verification failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Color(0xffC77398),
            width: double.infinity,
            padding: EdgeInsets.only(top: 40.0, bottom: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Verification Code',
                      style:
                      TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    'We have sent the verification code to your phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 45,
                        height: 60,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          style: TextStyle(fontSize: 24),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 30),
                  Text('Didn’t receive OTP?'),
                  SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      // Implement resend OTP logic if needed
                    },
                    child: Text(
                      'Resend code',
                      style: TextStyle(
                        color: Color(0xffC77398),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtpAndChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffC77398),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
