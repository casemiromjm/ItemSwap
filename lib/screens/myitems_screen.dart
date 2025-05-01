import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'item_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _hasLoaded = false;    // used for debug and better controlling

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your items')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Text(
          'My Items',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('items')
            .where('ownerId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _hasLoaded = true;
          }

          if (!_hasLoaded && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData ||
              (snapshot.connectionState == ConnectionState.active &&
                  snapshot.data!.docs.isEmpty)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You have no items posted yet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ItemScreen(),
                      ),
                    ),
                    child: const Text('Add Your First Item'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              return Card(
                color: const Color.fromARGB(255, 52, 83, 130),
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: item['imageUrl'] != null
                      ? CircleAvatar(
                    backgroundImage: MemoryImage(base64Decode(item['imageUrl'])),
                  )
                      : const CircleAvatar(child: Icon(Icons.image)),
                  title: Text(
                    item['name'] ?? 'No name',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    item['type'] ?? 'No type specified',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemScreen(itemDoc: items[index]),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ItemScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}