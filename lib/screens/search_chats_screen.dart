import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class SearchChatsScreen extends StatefulWidget {
  const SearchChatsScreen({super.key});

  @override
  State<SearchChatsScreen> createState() => _SearchChatsScreenState();
}

class _SearchChatsScreenState extends State<SearchChatsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _chatFilter = 'Receiver'; // Default filter

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      if (timestamp is Timestamp) {
        return DateFormat('MMM d, h:mm a').format(timestamp.toDate());
      }
      return 'Invalid time';
    } catch (e) {
      return 'Time error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Text(
          'Chat Search',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _chatFilter,
                    isExpanded: true,
                    dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All chats")),
                      DropdownMenuItem(value: "Receiver", child: Text("Chats started by you")),
                      DropdownMenuItem(value: "Sender", child: Text("Chats start with you")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _chatFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
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
                  final isReceiver = data['receiverID'] == currentUser.uid;
                  final isSender = data['senderID'] == currentUser.uid;

                  return _chatFilter == 'All'
                      ? (isReceiver || isSender)
                      : _chatFilter == 'Received'
                      ? isReceiver
                      : isSender;
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
                        if (!itemSnapshot.hasData ||
                            !itemSnapshot.data!.exists) {
                          return const SizedBox();
                        }
                        final itemData = itemSnapshot.data!.data()
                        as Map<String, dynamic>;
                        return Card(
                          color: const Color.fromARGB(255, 52, 83, 130),
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              itemData['name'] ?? 'Unnamed Item',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (itemData['description']?.isNotEmpty ?? false)
                                  Text(
                                    itemData['description']
                                        ?.split('\n')
                                        .first ??
                                        '',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                const SizedBox(height: 4,),
                                Text(
                                  'Last updated: ${_formatTimestamp(data['timestamp'])}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      chatId: chat.id, itemId: itemId),
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
          ),
        ],
      ),
    );
  }
}
