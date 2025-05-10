import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({Key? key}) : super(key: key);

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _updateEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await user!.verifyBeforeUpdateEmail(newEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A verification link has been sent to your new email. '
            'Please click it to confirm the change.',
          ),
        ),
      );

      _showUpdateEmailVerificationDialog(user, newEmail);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Error sending verification email';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUpdateEmailVerificationDialog(User user, String pendingEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            String dialogError = '';

            return AlertDialog(
              title: const Text('Confirm New Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'We’ve sent a verification link to your new address. '
                    'Please click it in the email to complete the update.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await user.reload();
                      await FirebaseAuth.instance.currentUser?.reload();
                      final updatedUser = FirebaseAuth.instance.currentUser;

                      if (updatedUser != null &&
                          updatedUser.email == pendingEmail) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email successfully updated!'),
                          ),
                        );
                      } else {
                        dialogSetState(() {
                          dialogError =
                              'Still waiting on confirmation. Please check your mail.';
                        });
                      }
                    },
                    child: const Text('Refresh & Confirm'),
                  ),
                  if (dialogError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Center(
          child: Text(
            'Change Email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current email:',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _emailController,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  labelStyle: TextStyle(color: Colors.white),
                  counterStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateEmail,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Email'),
            ),
          ],
        ),
      ),
    );
  }
}
