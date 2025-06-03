import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hopehub/LoginwithPhone_nbr.dart';
import 'package:hopehub/auth.dart';
import 'package:hopehub/message.dart';
import 'package:hopehub/ne_forget.dart';
import 'package:hopehub/otpf.dart';
import 'package:hopehub/otpregister.dart';
import 'package:hopehub/register.dart';
import 'package:hopehub/forgot_password.dart';
import 'package:intl/intl.dart';
import 'package:validators/validators.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEmailLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true; // For password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all the fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AudioRecorderPage()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid email or password.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithPhone() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all the fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (phoneAuthCredential) {},
      verificationFailed: (error) {
        setState(() {
          _errorMessage = 'Invalid phone number.';
        });
      },
      codeSent: (verificationId, forceResendingToken) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffC77398),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
            ],
            const Text(
              'Login',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _isEmailLogin = true),
                  child: const Text('Login with Email'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => _isEmailLogin = false),
                  child: const Text('Login with Phone'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isEmailLogin) ...[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter Email',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter Phone Number',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _isEmailLogin
                  ? _signInWithEmail
                  : _signInWithPhone,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                );
              },
              child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}














class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _showNotification = false;
  bool _isLoading = false;
  String _notificationMessage = "";

  FirebaseAuth _auth = FirebaseAuth.instance;

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

  bool isPhoneNumber(String input) {
    String pattern = r'^\+?[1-9]\d{7,14}$';
    return RegExp(pattern).hasMatch(input);
  }

  bool isValidEmail(String input) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(pattern).hasMatch(input);
  }

  Future<void> _sendOTP(String phoneNumber) async {
    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in if verification is instant
          await _auth.signInWithCredential(credential);
          _navigateToResetPassword();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showTopNotification("OTP Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
                isPasswordReset: true,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showTopNotification("Error sending OTP: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showTopNotification("Password reset link sent to your email", isError: false);
    } on FirebaseAuthException catch (e) {
      _showTopNotification("Error: ${e.message}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
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
                  'Forgot Password',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                            hintText: 'Enter Email or Phone number',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            counterText: "",
                          ),
                          style: TextStyle(color: Colors.white),
                          maxLength: 30,
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                            backgroundColor: Color(0xffC77398),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                            String userInput = _inputController.text.trim();

                            if (userInput.isEmpty) {
                              _showTopNotification("Please enter your email or phone number.");
                            } else if (isPhoneNumber(userInput)) {
                              await _sendOTP(userInput);
                            } else if (isValidEmail(userInput)) {
                              await _sendPasswordResetEmail(userInput);
                            } else {
                              _showTopNotification("Invalid input. Please enter a valid phone number or email.");
                            }
                          },
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Confirm', style: TextStyle(fontSize: 16, color: Colors.white)),
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
              child: Container(
                color: _notificationMessage.contains("Error") ? Colors.red : Colors.white,
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    _notificationMessage,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}











class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuthServices _auth = FirebaseAuthServices();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String? gender;
  String? maritalStatus;
  String? _errorMessage;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xffC77398), // Header background color
              onPrimary: Colors.white, // Header text color
            ),
            dialogBackgroundColor: Colors.white, // Background color
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _dateOfBirthController.text = formattedDate;
      });
    }
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  void _register() {
    if (_nameController.text.isEmpty ||
        gender == null ||
        maritalStatus == null ||
        _cnicController.text.isEmpty ||
        _occupationController.text.isEmpty ||
        _dateOfBirthController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all the fields.';
      });
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    CollectionReference collRef = FirebaseFirestore.instance.collection('client');
    collRef.add({
      'name': _nameController.text,
      'occupation': _occupationController.text,
      'CNIC': _cnicController.text,
      'password': _passwordController.text,
      're-enter-password': _confirmPasswordController.text,
      'date_of_birth': _dateOfBirthController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'gender': gender,
      'marital_status': maritalStatus,
    });

    _registerWithEmailAndVerifyPhone();
  }

  void _registerWithEmailAndVerifyPhone() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String phone = _phoneController.text.trim();

    try {
      User? user = await _auth.RegisterWithEmailAndPassword(email, password);
      if (user != null) {
        print("Email user created successfully");

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            print("Phone verification failed: ${e.message}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification failed: ${e.message}")),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpRegister(
                  verificationId: verificationId,
                  phone: phone,
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } else {
        print("Email user creation failed");
      }
    } catch (e) {
      print("Error during registration: $e");
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffC77398),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  color: Colors.red,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter Name',
                icon: Icons.person,
                controller: _nameController,
                maxLength: 20,
                inputType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              buildGenderField(),
              const SizedBox(height: 20),
              buildMaritalStatusField(),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter CNIC',
                icon: Icons.perm_identity,
                controller: _cnicController,
                maxLength: 14,
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter Occupation',
                icon: Icons.work,
                controller: _occupationController,
                maxLength: 30,
                inputType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              buildDateOfBirthField(context),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter Email',
                icon: Icons.email,
                controller: _emailController,
                maxLength: 30,
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter Phone Number',
                icon: Icons.phone,
                controller: _phoneController,
                maxLength: 13,
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Enter Password',
                icon: Icons.lock,
                isPassword: true,
                controller: _passwordController,
                maxLength: 20,
              ),
              const SizedBox(height: 20),
              buildRoundedTextField(
                hint: 'Re-Enter Password',
                icon: Icons.lock,
                isPassword: true,
                controller: _confirmPasswordController,
                maxLength: 20,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 18, color: Color(0xffC77398)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateOfBirthField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: TextField(
            controller: _dateOfBirthController,
            decoration: InputDecoration(
              hintText: 'Select Date of Birth',
              counterText: "",
              prefixIcon: Icon(Icons.calendar_today, color: const Color(0xffC77398)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRoundedTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    int? maxLength,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        maxLength: maxLength,
        keyboardType: inputType,
        decoration: InputDecoration(
          hintText: hint,
          counterText: "",
          prefixIcon: Icon(icon, color: const Color(0xffC77398)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        ),
      ),
    );
  }

  Widget buildGenderField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.radio_button_checked, color: Color(0xffC77398)),
              SizedBox(width: 10),
              Text('Select Gender', style: TextStyle(color: Colors.black54, fontSize: 16)),
            ],
          ),
          RadioListTile<String>(
            value: 'Male',
            groupValue: gender,
            onChanged: (value) {
              setState(() {
                gender = value;
              });
            },
            title: const Text('Male'),
          ),
          RadioListTile<String>(
            value: 'Female',
            groupValue: gender,
            onChanged: (value) {
              setState(() {
                gender = value;
              });
            },
            title: const Text('Female'),
          ),
        ],
      ),
    );
  }

  Widget buildMaritalStatusField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.folder_copy_outlined, color: Color(0xffC77398)),
        ),
        hint: const Text('Select Marital Status', style: TextStyle(color: Colors.black54)),
        items: const [
          DropdownMenuItem(value: 'Single', child: Text('Single')),
          DropdownMenuItem(value: 'Married', child: Text('Married')),
        ],
        onChanged: (value) {
          setState(() {
            maritalStatus = value;
          });
        },
      ),
    );
  }
}

class FirebaseAuthServices {
  Future<User?> RegisterWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Error in email registration: $e");
      return null;
    }
  }
}












class OtpRegister extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OtpRegister({Key? key, required this.verificationId, required this.phone}) : super(key: key);

  @override
  _OtpRegisterState createState() => _OtpRegisterState();
}

class _OtpRegisterState extends State<OtpRegister> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;

  @override
  void dispose() {
    _controllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  void _verifyOtpAndLinkPhone() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Link phone number with current user
        await user.linkWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number linked successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  Login()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Verification failed";
      if (e.code == 'invalid-verification-code') {
        message = "Invalid OTP code";
      } else if (e.code == 'credential-already-in-use') {
        message = "Phone number is already linked with another account.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Verification Code', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10.0),
                  Text(
                    'We have sent the verification code to ${widget.phone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                  const SizedBox(height: 30.0),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.5),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 20.0),

                  const Text('Didn’t receive OTP?', style: TextStyle(fontSize: 14.0)),
                  const SizedBox(height: 5.0),
                  GestureDetector(
                    onTap: () {
                      // Resend logic can be added here (optional)
                    },
                    child: const Text(
                      'Resend code',
                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xffC77398)),
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  SizedBox(
                    width: 200,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyOtpAndLinkPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD1A2B8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Continue', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
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





