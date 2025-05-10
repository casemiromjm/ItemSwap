import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'item_screen.dart';
import 'settings_screen.dart';
import 'user_screen.dart';
import 'item_deletion_handler.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<DocumentSnapshot> _fetchUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  void _showDeleteConfirmation(BuildContext context, DocumentSnapshot doc) {
    final String itemName = doc['name'] ?? 'this item';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 52, 83, 130),
          title: Text(
            "Delete '$itemName'?\nAttention:\nThis action will delete the item and all related chats!",
            style: const TextStyle(color: Colors.white),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '✗',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ItemDeletionHandler.deleteItemAndRelatedChats(doc.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("$itemName deleted.")));
                } catch (error) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete $itemName.")),
                  );
                }
              },
              child: const Text(
                '✓',
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color.fromARGB(255, 21, 45, 80);
    final secondary = const Color.fromARGB(255, 63, 133, 190);
    final cardColor = const Color.fromARGB(255, 52, 83, 130);

    return AppShell(
      currentIndex: 1,
      child: Container(
        color: primary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ListView(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: _fetchUserDoc(),
                  builder: (context, snap) {
                    String username = 'username';
                    ImageProvider? image;
                    if (snap.hasData && snap.data!.exists) {
                      final data = snap.data!.data() as Map<String, dynamic>;
                      username = data['username'] ?? username;
                      if (data['image'] != null) {
                        image = MemoryImage(base64Decode(data['image']));
                      }
                    }
                    return Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[700],
                                  backgroundImage: image,
                                  child:
                                      image == null
                                          ? const Icon(Icons.person, size: 60)
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserScreen(userId: uid),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ItemScreen()),
                          ),
                      child: const Text(
                        'New item',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('items')
                          .where(
                            'ownerId',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                          )
                          .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading items',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No items yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return Column(
                      children:
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            ImageProvider? img;
                            if (data['imageUrl'] != null) {
                              img = MemoryImage(base64Decode(data['imageUrl']));
                            }
                            return Card(
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[700],
                                  backgroundImage: img,
                                  child:
                                      img == null
                                          ? const Icon(
                                            Icons.image_not_supported,
                                          )
                                          : null,
                                ),
                                title: Text(
                                  data['name'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ItemScreen(itemDoc: doc),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            context,
                                            doc,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
