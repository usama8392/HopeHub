import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hopehub/Account_setting.dart';
import 'package:hopehub/Login.dart';

class NewEmail extends StatefulWidget {
  @override
  _NewEmailState createState() => _NewEmailState();
}

class _NewEmailState extends State<NewEmail> {
  final TextEditingController _newEmailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _showNewEmailError = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateEmail() async {
    final user = _auth.currentUser;
    final newEmail = _newEmailController.text.trim();

    // Validation
    setState(() {
      _showNewEmailError = newEmail.isEmpty || !newEmail.contains('@');
    });

    if (_showNewEmailError) {
      _showError('Please enter a valid email address');
      return;
    }

    if (user?.email == newEmail) {
      _showError('New email cannot be same as current email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send verification email to new address
      await user!.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore if needed (optional)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'pendingEmail': newEmail,
        'emailChangeTimestamp': FieldValue.serverTimestamp(),
      });

      // Show success and return to login
      _showError('Verification email sent to $newEmail');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );

    } on FirebaseAuthException catch (e) {
      _showError('Failed to update email: ${e.message}');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffC77398),
        elevation: 0,
        title: const Text('Change Email', style: TextStyle(color: Colors.white)),
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // New Email Field Only
                        TextField(
                          controller: _newEmailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                            hintText: 'Enter new email',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xffC77398),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _showNewEmailError ? 'Invalid email address' : null,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() => _showNewEmailError = false),
                        ),
                        const SizedBox(height: 40),

                        // Update Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffC77398),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _updateEmail,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Update Email',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

