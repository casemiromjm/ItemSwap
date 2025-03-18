import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _imageBase64;
  bool _isPasswordVisible = false; // Track password visibility

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        final file = result.files.single;
        final compressedImageBase64 = await _compressImageFile(file.bytes!);

        setState(() {
          _imageBase64 = compressedImageBase64;
        });
      }
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final compressedImageBase64 = await _compressImageFile(bytes);

        setState(() {
          _imageBase64 = compressedImageBase64;
        });
      }
    }
  }

  Future<String> _compressImageFile(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int maxHeight = 200,
    int quality = 30,
  }) async {
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      img.Image resizedImage = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
      );
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      return base64Encode(compressedBytes);
    } else {
      throw Exception('Failed to compress image');
    }
  }

  // Function to create a new user
  Future<void> _signUp() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Create user using FirebaseAuth
      UserCredential
      userCredential = await _auth.createUserWithEmailAndPassword(
        email:
            '${_usernameController.text}@example.com', // Use username as email (you can adjust this)
        password: _passwordController.text,
      );

      // Get user ID from Firebase Auth
      String userId = userCredential.user!.uid;

      // Save user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        'username': _usernameController.text,
        'password':
            _passwordController
                .text, // You might want to hash this before storing
        'image': _imageBase64,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
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
                  onPressed: _signUp, // Call signUp function
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
