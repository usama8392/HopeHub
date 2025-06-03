import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hopehub/Login.dart';
import 'package:hopehub/otpp.dart';
import 'package:flutter/services.dart';

class ChangePhoneNumber extends StatefulWidget {
  @override
  _ChangePhoneNumberScreenState createState() => _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState extends State<ChangePhoneNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showNotification = false;
  String _notificationMessage = "";
  bool _isLoading = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true; // Added for password visibility toggle

  void _showTopNotification(String message) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showNotification = false);
    });
  }

  String? _formatPhoneNumber(String rawNumber) {
    // Remove all non-digit characters except +
    final cleanedNumber = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle numbers with +92 country code
    if (cleanedNumber.startsWith('+92') && cleanedNumber.length == 13) {
      return cleanedNumber; // Already in correct format
    }

    // Handle numbers starting with 92 (without +)
    if (cleanedNumber.startsWith('92') && cleanedNumber.length == 12) {
      return '+$cleanedNumber';
    }

    // Handle local format numbers starting with 0
    if (cleanedNumber.startsWith('0') && cleanedNumber.length == 11) {
      return '+92${cleanedNumber.substring(1)}';
    }

    return null;
  }

  Future<void> _verifyAndUpdatePhone() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showTopNotification('Please enter a phone number');
      return;
    }

    // Validate and format phone number
    final formattedNumber = _formatPhoneNumber(phoneNumber);
    if (formattedNumber == null) {
      _showTopNotification('Please enter a valid phone number (e.g., +923001234567 or 03001234567)');
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user == null) {
        _showTopNotification('User not logged in');
        return;
      }

      if (user.email != null) {
        if (!_showPasswordField) {
          setState(() {
            _showPasswordField = true;
            _isLoading = false;
          });
          return;
        }

        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          _showTopNotification('Please enter your password');
          setState(() => _isLoading = false);
          return;
        }

        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          ),
        );
      }

      await _verifyPhoneNumber(formattedNumber);

    } on FirebaseAuthException catch (e) {
      _showTopNotification(e.message ?? "Verification failed");
    } catch (e) {
      _showTopNotification('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPhoneNumber(String formattedNumber) async {
    final completer = Completer<PhoneAuthCredential>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      verificationCompleted: completer.complete,
      verificationFailed: (e) => completer.completeError(e),
      codeSent: (verificationId, _) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPhone(
              verificationId: verificationId,
              phoneNumber: formattedNumber,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {},
      timeout: const Duration(seconds: 60),
    );

    if (!completer.isCompleted) return;
    try {
      final credential = await completer.future;
      await FirebaseAuth.instance.currentUser?.updatePhoneNumber(credential);
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login()),
              (route) => false,
        );
      }
    } catch (e) {
      _showTopNotification('Error verifying phone number');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffC77398),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xffC77398),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Change Phone Number',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextField(
                          controller: _phoneController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                            LengthLimitingTextInputFormatter(14),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone, color: Colors.white),
                            hintText: 'Enter phone number (e.g., +923001234567 or 03001234567)',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            counterText: "",
                          ),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (_showPasswordField) ...[
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Colors.white),
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color(0xffC77398),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                        const SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                            backgroundColor: const Color(0xffC77398),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyAndUpdatePhone,
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _showPasswordField ? 'Verify and Update' : 'Continue',
                            style: const TextStyle(
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
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _notificationMessage,
                      style: const TextStyle(
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
}














class OtpPhone extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpPhone({
    required this.phoneNumber,
    required this.verificationId,
    Key? key,
  }) : super(key: key);

  @override
  _OtpPhoneState createState() => _OtpPhoneState();
}

class _OtpPhoneState extends State<OtpPhone> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 60; // Changed from 30 to 60 seconds
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  void _startResendTimer() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.currentUser?.updatePhoneNumber(credential);

      // Success - navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Login()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'OTP verification failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _resendCooldown = 60; // Changed from 30 to 60 seconds
      _startResendTimer();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) => _showError('Resend failed: ${e.message}'),
        codeSent: (verificationId, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New OTP sent!')),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 60), // Ensure timeout matches cooldown
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleOtpInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isNotEmpty && index == 5) {
      _verifyOtp();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD1A2B8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'OTP Verification',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'We sent a verification code to',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.phoneNumber,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) => _handleOtpInput(value, index),
                  ),
                );
              }),
            ),

            // Resend Button
            const SizedBox(height: 30),
            TextButton(
              onPressed: _resendCooldown > 0 ? null : _resendOtp,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend code in $_resendCooldown s'
                    : 'Resend verification code',
                style: TextStyle(
                  color: _resendCooldown > 0
                      ? Colors.grey
                      : const Color(0xFFD1A2B8),
                ),
              ),
            ),

            // Verify Button
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1A2B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'VERIFY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}