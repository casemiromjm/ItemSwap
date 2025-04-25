import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class SearchChatsScreen extends StatefulWidget {
  final bool isOwnerMode; // true if viewing chats as owner (sender), false if as receiver
  const SearchChatsScreen({super.key, required this.isOwnerMode});

  @override
  State<SearchChatsScreen> createState() => _SearchChatsScreenState();
}

class _SearchChatsScreenState extends State<SearchChatsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: Text(
          widget.isOwnerMode ? 'Chats as Owner' : 'Chats as Receiver',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('chats').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || currentUser == null) {
            return const Center(
              child: Text('No chats available.', style: TextStyle(color: Colors.white)),
            );
          }

          final chatDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return widget.isOwnerMode
              ? data['senderID'] == currentUser.uid
              : data['receiverID'] == currentUser.uid;
          }).toList();

          if (chatDocs.isEmpty) {
            return const Center(
              child: Text('No chats found.', style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final data = chat.data() as Map<String, dynamic>;
              final itemId = data['itemID'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('items').doc(itemId).get(),
                builder: (context, itemSnapshot) {
                  if (!itemSnapshot.hasData || !itemSnapshot.data!.exists) {
                    return const SizedBox();
                  }
                  final itemData = itemSnapshot.data!.data() as Map<String, dynamic>;
                  return Card(
                    color: const Color.fromARGB(255, 52, 83, 130),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        itemData['name'] ?? 'Unnamed Item',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        itemData['description']?.split('\n').first ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chat.id, itemId: itemId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
