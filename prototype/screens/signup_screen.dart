import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'image_handler.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController =
      TextEditingController(); // Email controller
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _imageBase64;
  bool _isPasswordVisible = false; // Track password visibility
  bool _isLoading = false; // Track the loading state
  String _errorMessage = '';

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to pick image
  Future<void> _pickImage() async {
    await pickImage((compressedImageBase64) {
      setState(() {
        _imageBase64 = compressedImageBase64;
      });
    });
  }

  // Function to send verification email and create user if verified
  Future<void> _signUp() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _imageBase64 == null ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Reset error message
    });

    try {
      // Create user using FirebaseAuth with email
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text, // Use the email entered by the user
            password: _passwordController.text,
          );

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please verify your email.'),
        ),
      );

      // After sending email, allow user to check verification status manually
      setState(() {
        _isLoading = false;
      });

      // You can guide the user here to check their email and manually refresh
      _showVerificationDialog(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'An error occurred.';
      });
    }
  }

  // Show a dialog asking the user to check their email and refresh the status
  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please check your email to verify your account.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Reload the user and check email verification status
                  await user.reload();
                  User? updatedUser = _auth.currentUser;

                  // Make sure the user is reloaded correctly
                  if (updatedUser != null && updatedUser.emailVerified) {
                    Navigator.of(context).pop();
                    _createUserInFirestore(updatedUser);
                  } else {
                    setState(() {
                      _errorMessage =
                          'Email not verified yet. Please check your inbox.';
                    });
                  }
                },
                child: const Text('Refresh Verification Status'),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        );
      },
    );
  }

  // Function to save user to Firestore
  Future<void> _createUserInFirestore(User user) async {
    String userId = user.uid;

    // Save user data to Firestore, including userCreatedCount
    await _firestore.collection('users').doc(userId).set({
      'username': _usernameController.text,
      'image': _imageBase64,
      'created_at': Timestamp.now(),
      'items_given': 0,
      'items_received': 0,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User created successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        _imageBase64 != null
                            ? MemoryImage(base64Decode(_imageBase64!))
                            : null,
                    child:
                        _imageBase64 == null
                            ? const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 40,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController, // Email input field
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLength: 15,
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLength: 15,
                  controller: _passwordController,
                  obscureText:
                      !_isPasswordVisible, // Toggle password visibility
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _signUp, // Disable button while loading
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
