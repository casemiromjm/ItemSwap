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

  void _sendMessage() {
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

  Future<void> _completeSwap(Map<String, dynamic> chatData) async {
    final itemName = await _fetchItemName();
    final senderId = chatData['senderID'] as String;
    final receiverId = chatData['receiverID'] as String;
    final chatRef = _firestore.collection('chats').doc(widget.chatId);

    await _firestore.collection('items').doc(widget.itemId).delete();
    await _firestore.collection('users').doc(senderId).update({
      'items_given': FieldValue.increment(1),
    });
    await _firestore.collection('users').doc(receiverId).update({
      'items_received': FieldValue.increment(1),
    });

    await chatRef.update({
      'pendingDelete': true,
      'left_sender': false,
      'left_receiver': false,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$itemName successfully swapped!')));
  }

  Future<bool> _onWillPop() async {
    final chatRef = _firestore.collection('chats').doc(widget.chatId);
    final snap = await chatRef.get();
    if (!snap.exists) return true;

    final data = snap.data()! as Map<String, dynamic>;
    final isSender = data['senderID'] == currentUser?.uid;
    final leftField = isSender ? 'left_sender' : 'left_receiver';

    await chatRef.update({leftField: true});

    final after = (await chatRef.get()).data()! as Map<String, dynamic>;
    final bothLeft =
        (after['left_sender'] ?? false) && (after['left_receiver'] ?? false);
    if (after['pendingDelete'] == true && bothLeft) {
      final msgsSnap = await chatRef.collection('messages').get();
      for (var m in msgsSnap.docs) {
        await m.reference.delete();
      }
      await chatRef.delete();
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 21, 45, 80),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 63, 133, 190),
          title: StreamBuilder<DocumentSnapshot>(
            stream:
                _firestore.collection('chats').doc(widget.chatId).snapshots(),
            builder: (ctx, snap) {
              // If chat is pending delete, override title
              if (snap.hasData &&
                  (snap.data!.data()
                          as Map<String, dynamic>)['pendingDelete'] ==
                      true) {
                return const Center(
                  child: Text(
                    'Deleted Chat',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                );
              }
              // Otherwise, show the item name
              return FutureBuilder<String>(
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
              );
            },
          ),
        ),
        body: Column(
          children: [
            // Request‐swap / Finish negotiation button
            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, snap2) {
                if (!snap2.hasData) return const SizedBox.shrink();
                final d = snap2.data!.data()! as Map<String, dynamic>;
                final String senderId = d['senderID'] as String;
                final String receiverId = d['receiverID'] as String;
                final bool requestSwap = d['request_swap'] ?? false;
                final bool isReceiver = receiverId == currentUser?.uid;
                final bool isSender = senderId == currentUser?.uid;

                if (isReceiver) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _firestore
                            .collection('chats')
                            .doc(widget.chatId)
                            .update({'request_swap': !requestSwap});
                      },
                      child: Text(
                        requestSwap ? 'Undo request' : 'Request swap',
                      ),
                    ),
                  );
                }

                if (isSender && requestSwap) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => _completeSwap(d),
                      child: const Text('Finish swap negotiation'),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // Chat messages display
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesStream(),
                builder: (context, msgSnap) {
                  if (msgSnap.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${msgSnap.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (msgSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }
                  final messages = msgSnap.data!.docs;
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

            // Image preview (if any)
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

            // Message input row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image, color: Colors.white),
                  ),
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
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
