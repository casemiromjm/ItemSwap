import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import your image handler package that provides the pickImage function.
import 'image_handler.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;

  const ChatScreen({Key? key, required this.chatId, required this.itemId})
    : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // This variable will store the base64 image selected by the user.
  String? _imageBase64;

  /// Helper function that decodes a base64 image and returns an Image widget.
  /// This version displays the image in totality.
  Widget _getImageFromBase64(String base64String) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(decodedBytes, fit: BoxFit.contain);
  }

  /// Returns a stream of messages (ordered by timestamp) from the chat.
  Stream<QuerySnapshot> _messagesStream() {
    return _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Sends a message. If _imageBase64 is set, sends an image message;
  /// otherwise sends a text message.
  void _sendMessage() {
    if (currentUser == null) return;

    if (_imageBase64 != null) {
      // Send an image message.
      _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'chatId': widget.chatId,
            'senderID': currentUser!.uid,
            'text': _imageBase64,
            'isText': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
      setState(() {
        _imageBase64 = null; // Reset the selected image.
      });
    } else {
      // Send a text message.
      String text = _messageController.text.trim();
      if (text.isNotEmpty) {
        _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
              'chatId': widget.chatId,
              'senderID': currentUser!.uid,
              'text': text,
              'isText': true,
              'timestamp': FieldValue.serverTimestamp(),
            });
        _messageController.clear();
      }
    }
  }

  /// Uses the image_handler pickImage function.
  Future<void> _pickImage() async {
    // This calls your function from the image_handler package.
    await pickImage((compressedImageBase64) {
      setState(() {
        _imageBase64 = compressedImageBase64;
      });
    });
  }

  /// Fetch the item's name from Firestore so it can be displayed in the AppBar.
  Future<String> _fetchItemName() async {
    final doc = await _firestore.collection('items').doc(widget.itemId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] ?? widget.itemId;
    }
    return widget.itemId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: FutureBuilder<String>(
          future: _fetchItemName(),
          builder: (context, snapshot) {
            String title = 'Chat';
            if (snapshot.connectionState == ConnectionState.waiting) {
              title = 'Chat...';
            } else if (snapshot.hasData) {
              title = 'Chat for ${snapshot.data}';
            }
            return Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Chat messages display.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    bool isCurrentUser =
                        messageData['senderID'] == currentUser?.uid;
                    return Container(
                      alignment:
                          isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isCurrentUser
                                  ? Colors.blue[200]
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // If the message is text, display text;
                        // if not, display the decoded image.
                        child:
                            messageData['isText'] == true
                                ? Text(
                                  messageData['text'] ?? '',
                                  style: const TextStyle(color: Colors.black),
                                )
                                : _getImageFromBase64(
                                  messageData['text'] ?? '',
                                ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // If an image was selected, show its preview above the input.
          if (_imageBase64 != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _getImageFromBase64(_imageBase64!),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageBase64 = null;
                        });
                      },
                      child: const Icon(Icons.cancel, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          // Message input row.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Button to pick an image.
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.white),
                ),
                // Text input field.
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Button to send the message.
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
