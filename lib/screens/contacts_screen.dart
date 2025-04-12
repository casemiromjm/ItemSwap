import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late DatabaseReference _chatsRef;
  List<Map<dynamic, dynamic>> _userChats = [];
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Reference the "chats" node in the Realtime Database
    _chatsRef = FirebaseDatabase.instance.ref('chats');

    // Listen for changes in the chats node.
    _chatsRef.onValue.listen((event) {
      final chatsData = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<dynamic, dynamic>> tempChats = [];
      if (chatsData != null) {
        chatsData.forEach((key, value) {
          // Each chat document should have an itemID, senderID, and receiverID.
          // Filter chats that involve the current user.
          if (currentUser != null &&
              (value['senderID'] == currentUser!.uid || value['receiverID'] == currentUser!.uid)) {
            // Include the chatId for navigation purposes.
            Map<dynamic, dynamic> chat = Map<dynamic, dynamic>.from(value);
            chat['chatId'] = key;
            tempChats.add(chat);
          }
        });
      }
      setState(() {
        _userChats = tempChats;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: _userChats.isEmpty
          ? const Center(child: Text('No chats available.'))
          : ListView.builder(
              itemCount: _userChats.length,
              itemBuilder: (context, index) {
                final chat = _userChats[index];
                return ListTile(
                  title: Text('Item: ${chat['itemID']}'),
                  subtitle: Text(
                      'Between: ${chat['senderID']} & ${chat['receiverID']}'),
                  onTap: () {
                    // Navigate to the chat screen for this chat, passing chatId and itemID.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat['chatId'],
                          itemId: chat['itemID'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
