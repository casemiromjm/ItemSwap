import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_deletion_handler.dart';
// Import your image handler package that provides the pickImage function.
import 'image_handler.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;

  const ChatScreen({super.key, required this.chatId, required this.itemId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String? _imageBase64;

  Widget _getImageFromBase64(String base64String) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(decodedBytes, fit: BoxFit.contain);
  }

  Stream<QuerySnapshot> _messagesStream() {
    return _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _sendMessage() async {
    if (currentUser == null) return;

    if (_imageBase64 != null) {
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
        _imageBase64 = null;
      });
    } else {
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

  Future<void> _pickImage() async {
    await pickImage((compressedImageBase64) {
      setState(() {
        _imageBase64 = compressedImageBase64;
      });
    });
  }

  Future<String> _fetchItemName() async {
    final doc = await _firestore.collection('items').doc(widget.itemId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] ?? widget.itemId;
    }
    return widget.itemId;
  }

  Future<String> _fetchReceiverName(String receiverId) async {
    final doc = await _firestore.collection('users').doc(receiverId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['username'] ?? 'User';
    }
    return 'User';
  }

  Future<void> _completeSwap(Map<String, dynamic> chatData) async {
    final itemName = await _fetchItemName();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 52, 83, 130),
          title: Text(
            "Finish swap negotiation for '$itemName'?",
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
                Navigator.of(context).pop();
                await ItemDeletionHandler.deleteItemAndRelatedChats(
                  widget.itemId,
                );
                final senderId = chatData['senderID'] as String;
                final receiverId = chatData['receiverID'] as String;
                await _firestore.collection('users').doc(senderId).update({
                  'items_given': FieldValue.increment(1),
                });
                await _firestore.collection('users').doc(receiverId).update({
                  'items_received': FieldValue.increment(1),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$itemName successfully swapped!')),
                );
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
    final chatRef = _firestore.collection('chats').doc(widget.chatId);

    return StreamBuilder<DocumentSnapshot>(
      stream: chatRef.snapshots(),
      builder: (context, chatSnap) {
        if (chatSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF152D50),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (chatSnap.hasData && !chatSnap.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF152D50),
            appBar: AppBar(
              backgroundColor: const Color(0xFF3F85BE),
              title: const Center(child: Text('Deleted Chat')),
            ),
            body: const Center(
              child: Text(
                'This chat has been deleted.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final chatData = chatSnap.data!.data() as Map<String, dynamic>;

        final String senderId = chatData['senderID'] as String;
        final String receiverId = chatData['receiverID'] as String;
        final bool requestSwap = chatData['request_swap'] ?? false;
        final bool isReceiver = receiverId == currentUser?.uid;
        final bool isSender = senderId == currentUser?.uid;

        return Scaffold(
          backgroundColor: const Color(0xFF152D50),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3F85BE),
            title: FutureBuilder<String>(
              future: Future.wait([
                _fetchItemName(),
                _fetchReceiverName(isReceiver ? senderId : receiverId),
              ]).then((values) => 'Chat for ${values[0]} with ${values[1]}'),
              builder: (context, titleSnap) {
                final title =
                    titleSnap.connectionState == ConnectionState.waiting
                        ? 'Loading...'
                        : titleSnap.data!;
                return Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                );
              },
            ),
          ),
          body: Column(
            children: [
              if (isReceiver)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed:
                        () => chatRef.update({'request_swap': !requestSwap}),
                    child: Text(requestSwap ? 'Undo request' : 'Request swap'),
                  ),
                ),
              if (isSender && requestSwap)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _completeSwap(chatData),
                    child: const Text('Finish swap negotiation'),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesStream(),
                  builder: (context, msgSnap) {
                    if (msgSnap.hasError) {
                      return Center(child: Text('Error: ${msgSnap.error}'));
                    }
                    if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    final messages = msgSnap.data!.docs;
                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg =
                            messages[index].data() as Map<String, dynamic>;
                        final bool isCurrentUser =
                            msg['senderID'] == currentUser?.uid;

                        return Align(
                          alignment:
                              isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                msg['isText'] == true
                                    ? Text(
                                      msg['text'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF152D50),
                                      ),
                                    )
                                    : _getImageFromBase64(msg['text'] ?? ''),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
                          onTap: () => setState(() => _imageBase64 = null),
                          child: const Icon(Icons.cancel, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF152D50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Tap to write',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
