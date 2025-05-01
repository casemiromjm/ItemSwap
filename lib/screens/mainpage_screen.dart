import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:itemswap/screens/myitems_screen.dart';

// actually "home" page / main page

class MainPage extends StatelessWidget {
  final WidgetBuilder? searchScreenBuilder;

  const MainPage({
    super.key,
    this.searchScreenBuilder,
  });

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      body: Column (
        children: [
          Container (
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(left: 30,right: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                color: const Color.fromARGB(255, 52, 83, 130),
                height: 200,
                width: 300,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _getUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userData = snapshot.data ?? {};
                    final username = userData['username'] ?? 'User';
                    final profilePicture = userData['image'] ?? '';
                    final itemsGiven = userData['items_given'] ?? 0;
                    final itemsReceived = userData['items_received'] ?? 0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: profilePicture != null ? MemoryImage(base64Decode(profilePicture)) : null,
                          child: profilePicture == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Items Given: $itemsGiven | Items Received: $itemsReceived',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyItemsScreen()),
              );
            },
            child: const Text('My Items'),
            ),
        ],
      ),
    );
  }
}
