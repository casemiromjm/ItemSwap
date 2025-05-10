import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'item_screen.dart';
import 'app_shell.dart';

class SearchChatsScreen extends StatefulWidget {
  const SearchChatsScreen({super.key});

  @override
  State<SearchChatsScreen> createState() => _SearchChatsScreenState();
}

class _SearchChatsScreenState extends State<SearchChatsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _chatFilter = 'Sender';
  int _chatsToLoad = 20;

  String _descriptionPreview(String description) {
    if (description.isEmpty) return 'No description';
    final firstLine = description.split('\n').first;
    return firstLine.length > 25
        ? '${firstLine.substring(0, 25)} (...)'
        : '$firstLine (...)';
  }

  Image _getImageFromBase64(String base64String, {double size = 50}) {
    final decoded = base64Decode(base64String);
    return Image.memory(decoded, width: size, height: size, fit: BoxFit.cover);
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      final msgs =
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();
      final batch = _firestore.batch();
      for (var msg in msgs.docs) batch.delete(msg.reference);
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Chat deleted.")));
    } catch (error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete chat.")));
    }
  }

  Widget _buildChatList(List<QueryDocumentSnapshot> chats) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final data = chat.data() as Map<String, dynamic>;
        final itemId = data['itemID'];
        final isSenderView = _chatFilter == 'Sender';

        final itemFuture = _firestore.collection('items').doc(itemId).get();
        final userFuture =
            _firestore
                .collection('users')
                .doc(isSenderView ? data['senderID'] : data['receiverID'])
                .get();

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait([itemFuture, userFuture]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final itemSnap = snapshot.data![0];
            final userSnap = snapshot.data![1];
            if (!itemSnap.exists || !userSnap.exists) return const SizedBox();

            final item = itemSnap.data() as Map<String, dynamic>;
            final user = userSnap.data() as Map<String, dynamic>;

            Widget itemImg =
                item['imageUrl'] != null
                    ? _getImageFromBase64(item['imageUrl'], size: 50)
                    : const Icon(Icons.image_not_supported, size: 50);
            Widget profilePic =
                user['image'] != null
                    ? ClipOval(
                      child: _getImageFromBase64(user['image'], size: 30),
                    )
                    : const CircleAvatar(
                      radius: 15,
                      child: Icon(Icons.person, size: 15),
                    );

            return Card(
              color: const Color.fromARGB(255, 52, 83, 130),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: itemImg,
                title: Text(
                  item['name'] ?? 'Unnamed Item',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _descriptionPreview(item['description'] ?? ''),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        profilePic,
                        const SizedBox(width: 5),
                        Text(
                          user['username'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSenderView) ...[
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    52,
                                    83,
                                    130,
                                  ),
                                  title: const Text(
                                    'Delete chat?\nAttention:\nThis action will delete the chat irreversibly!',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  actionsAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text(
                                        '✗',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        '✓',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmed == true) await _deleteChat(chat.id);
                        },
                      ),
                      const SizedBox(width: 5),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      tooltip: 'Open Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    ChatScreen(chatId: chat.id, itemId: itemId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      tooltip: 'More Details',
                      onPressed: () async {
                        // Fetch as QueryDocumentSnapshot for ItemScreen
                        final query =
                            await _firestore
                                .collection('items')
                                .where(FieldPath.documentId, isEqualTo: itemId)
                                .get();
                        if (query.docs.isNotEmpty) {
                          final qdoc = query.docs.first;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemScreen(itemDoc: qdoc),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    return AppShell(
      currentIndex: 3,
      child: Container(
        color: const Color.fromARGB(255, 21, 45, 80),
        child: Column(
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
                        DropdownMenuItem(
                          value: 'Sender',
                          child: Text('Items to receive'),
                        ),
                        DropdownMenuItem(
                          value: 'Receiver',
                          child: Text('Items to give'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _chatFilter = val!),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('chats')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || currentUser == null) {
                    return const Center(
                      child: Text(
                        'No chats available.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final allChats = snapshot.data!.docs;
                  final filtered =
                      allChats.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _chatFilter == 'Sender'
                            ? d['receiverID'] == currentUser.uid
                            : d['senderID'] == currentUser.uid;
                      }).toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No chats found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return _buildChatList(filtered.take(_chatsToLoad).toList());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
