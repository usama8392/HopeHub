import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hopehub/New_Emial.dart';
import 'package:hopehub/otpp.dart'; // OTP for Phone Verification

class ChangeEmail extends StatefulWidget {
  @override
  _ChangeEmailState createState() => _ChangeEmailState();
}

class _ChangeEmailState extends State<ChangeEmail> {
  final TextEditingController _emailController = TextEditingController();
  bool _showNotification = false;
  String _notificationMessage = "";
  bool _isLoading = false;

  void _showTopNotification(String message, {bool isError = true}) {
    setState(() {
      _notificationMessage = message;
      _showNotification = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  Future<void> _verifyAndSendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showTopNotification('User not authenticated');
        return;
      }

      // Check if phone is linked (required for OTP flow)
      if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
        _showTopNotification('No phone number linked to this account');
        return;
      }

      // Verify the entered email matches current email
      final enteredEmail = _emailController.text.trim();
      if (enteredEmail.isEmpty || !enteredEmail.contains('@')) {
        _showTopNotification('Please enter a valid email address');
        return;
      }

      if (user.email != null && user.email != enteredEmail) {
        _showTopNotification('Entered email does not match your account');
        return;
      }

      // Proceed to OTP verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpEMAIL(phoneNumber: user.phoneNumber!),
        ),
      );

    } catch (e) {
      _showTopNotification('Error: ${e.toString()}');
      print('Error in email verification: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  'Change Email Address',
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
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                            hintText: 'Enter Current Email address (e.g., abc@gmail.com)',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            counterText: "",
                          ),
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 40,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 50),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                            backgroundColor: Color(0xffC77398),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _verifyAndSendOtp,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Confirm',
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
    _emailController.dispose();
    super.dispose();
  }
}







class OtpEMAIL extends StatefulWidget {
  final String phoneNumber;

  const OtpEMAIL({required this.phoneNumber, Key? key}) : super(key: key);

  @override
  _OtpEMAILState createState() => _OtpEMAILState();
}

class _OtpEMAILState extends State<OtpEMAIL> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  String? _verificationId;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendAttempts = 0;
  final int _maxResendAttempts = 3;
  DateTime? _lastResendTime;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    if (_isResending && _resendAttempts >= _maxResendAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum resend attempts reached')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      if (_isResending) _resendAttempts++;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some Android devices
          await _verifyAndProceed(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _isResending = false;
            _lastResendTime = DateTime.now();
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP')),
      );
    }
  }

  Future<void> _verifyAndProceed(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Critical security step - reauthentication
      await user.reauthenticateWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NewEmail()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6 || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _verifyAndProceed(credential);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canResend {
    if (_lastResendTime == null) return true;
    return DateTime.now().difference(_lastResendTime!).inSeconds > 60;
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (unchanged)
          Container(
            color: const Color(0xffC77398),
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40.0, bottom: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'OTP Verification',
                    style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    'Verification Code',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'We have sent a verification code to ${widget.phoneNumber}',
                    style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 30.0),

                  // OTP Input Fields (unchanged)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        height: 60.0,
                        width: 50.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              FocusScope.of(context).nextFocus();
                            } else if (value.isEmpty && index > 0) {
                              FocusScope.of(context).previousFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20.0),

                  // Resend OTP Section
                  const Text(
                      'Didn\'t receive OTP?',
                      style: TextStyle(fontSize: 14.0, color: Colors.black)),
                  const SizedBox(height: 5.0),
                  GestureDetector(
                    onTap: _canResend
                        ? () {
                      setState(() => _isResending = true);
                      _sendOtp();
                    }
                        : null,
                    child: Text(
                      _canResend
                          ? 'Resend code'
                          : 'Resend available in ${60 - DateTime.now().difference(_lastResendTime!).inSeconds}s',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: _canResend
                            ? const Color(0xffC77398)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Continue Button
                  SizedBox(
                    width: 200,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffC77398),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0)),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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

