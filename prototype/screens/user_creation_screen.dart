import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'image_handler.dart';

class UserCreationScreen extends StatefulWidget {
  const UserCreationScreen({super.key});

  @override
  _UserCreationScreenState createState() => _UserCreationScreenState();
}

class _UserCreationScreenState extends State<UserCreationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imageBase64;
  bool _isLoading = false;
  bool _isEditing = false;
  int _itemsGiven = 0;
  int _itemsReceived = 0;
  Timestamp? _createdAt;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isEditing = true;
          _usernameController.text = userDoc['username'] ?? '';
          _descriptionController.text = userDoc['description'] ?? '';
          _imageBase64 = userDoc['image'];
          _itemsGiven = userDoc['items_given'] ?? 0;
          _itemsReceived = userDoc['items_received'] ?? 0;
          _createdAt = userDoc['created_at'];
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    if (_isEditing) {
      await _firestore.collection('users').doc(user.uid).set({
        'username': _usernameController.text,
        'image': _imageBase64,
        'description': _descriptionController.text,
      }, SetOptions(merge: true));
    } else {
      await _firestore.collection('users').doc(user.uid).set({
        'username': _usernameController.text,
        'image': _imageBase64,
        'description': _descriptionController.text,
        'created_at': Timestamp.now(),
        'items_given': 0,
        'items_received': 0,
      }, SetOptions(merge: true));
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Profile updated!' : 'User created successfully!',
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    await pickImage((compressedImageBase64) {
      setState(() {
        _imageBase64 = compressedImageBase64;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: Text(
          _isEditing ? 'Change Profile' : 'Complete Your Profile',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(height: 10),
                      if (_isEditing)
                        Text(
                          'Joined on: ${DateTime.fromMillisecondsSinceEpoch(_createdAt!.millisecondsSinceEpoch).toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 10),
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
                        controller: _descriptionController,
                        maxLength: 100,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_isEditing) const SizedBox(height: 20),
                      if (_isEditing)
                        Text(
                          'Items Given: $_itemsGiven | Items Received: $_itemsReceived',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  if (_usernameController.text.trim().isEmpty ||
                                      _descriptionController.text
                                          .trim()
                                          .isEmpty ||
                                      _imageBase64 == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in all fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    await _saveUserData();
                                  } catch (e) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                  _isEditing
                                      ? 'Update Profile'
                                      : 'Create Profile',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
