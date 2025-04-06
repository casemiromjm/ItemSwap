import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController textController = TextEditingController();
  String userMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(title: const Text('Chat')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Right-aligned Display Box
            Expanded(
              child: Align(
                alignment: Alignment.centerRight, // Align the entire box to the right
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5, // Half the screen width
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      userMessage,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.end, // Align text to the right inside the box
                    ),
                  ),
                ),
              ),
            ),

            // TextField with Send Icon inside
            TextField(
              controller: textController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: 'Tap to write',
                hintStyle: TextStyle(fontSize: 20.0, color: Colors.white),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      userMessage = textController.text;
                    });
                    textController.clear();
                  },
                  icon: Icon(
                    Icons.send, // Use the send icon
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}