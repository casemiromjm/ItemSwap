import 'package:flutter/material.dart';

import 'chat_screen.dart';

class Contacts extends StatelessWidget {
  const Contacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.centerLeft, // Left-center the rectangle
          child: GestureDetector(
            onTap: () {
              // Navigate to ChatScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
            child: Container(
              width: 300, // Width of the rectangle
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Circular Photo
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('to insert'), // Add your image to the assets folder
                  ),
                  SizedBox(width: 20), // Spacing between photo and name
                  // Name of the Person
                  Text(
                    'Chat prototype',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}