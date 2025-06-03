import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewPhoneScreen extends StatefulWidget {
  @override
  _NewPhoneScreenState createState() => _NewPhoneScreenState();
}

class _NewPhoneScreenState extends State<NewPhoneScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailUser = false;

  @override
  void initState() {
    super.initState();
    _isEmailUser = FirebaseAuth.instance.currentUser?.email != null;
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final phoneNumber = _phoneController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.message}")),
          );
        },
        codeSent: (verificationId, _) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyNewPhoneScreen(
                newPhone: phoneNumber,
                verificationId: verificationId,
                isEmailUser: _isEmailUser,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffC77398),
        title: Text("Change Phone Number"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "New Phone Number",
                prefix: Text("+92 "),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}





class VerifyNewPhoneScreen extends StatefulWidget {
  final String newPhone;
  final String verificationId;
  final bool isEmailUser;

  const VerifyNewPhoneScreen({
    required this.newPhone,
    required this.verificationId,
    required this.isEmailUser,
  });

  @override
  _VerifyNewPhoneScreenState createState() => _VerifyNewPhoneScreenState();
}

class _VerifyNewPhoneScreenState extends State<VerifyNewPhoneScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0; // 0=OTP, 1=Password/Current OTP

  Future<void> _verifyNewPhone() async {
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );

      if (widget.isEmailUser) {
        setState(() => _currentStep = 1);
      } else {
        await _sendCurrentPhoneOtp();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCurrentPhoneOtp() async {
    // Implement current phone OTP sending
  }

  Future<void> _confirmChange() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final newPhoneCredential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );

      if (widget.isEmailUser) {
        final emailCredential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text,
        );
        await user.reauthenticateWithCredential(emailCredential);
      } else {
        // Verify current phone OTP
      }

      await user.updatePhoneNumber(newPhoneCredential);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone number updated!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffC77398),
        title: Text("Verify Phone Number"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: _currentStep == 0
            ? _buildOtpStep()
            : _buildConfirmationStep(),
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Text("Enter OTP sent to ${widget.newPhone}"),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: _verifyNewPhone,
          child: Text("Verify"),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      children: [
        Text(widget.isEmailUser
            ? "Enter your password"
            : "Enter OTP sent to current number"),
        TextField(
          controller: _passwordController,
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _confirmChange,
          child: Text("Confirm Change"),
        ),
      ],
    );
  }
}