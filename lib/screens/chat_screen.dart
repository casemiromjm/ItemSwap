import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.itemId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late DatabaseReference _messagesRef;
  List<Map<dynamic, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Reference the messages for the specific chatId
    _messagesRef =
        FirebaseDatabase.instance.ref('messages').child(widget.chatId);

    // Listen for changes in the messages node
    _messagesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<dynamic, dynamic>> tempMessages = [];
      if (data != null) {
        data.forEach((key, value) {
          Map<dynamic, dynamic> msg = Map<dynamic, dynamic>.from(value);
          msg['messageId'] = key;
          tempMessages.add(msg);
        });
      }
      // Sort messages by timestamp.
      tempMessages.sort((a, b) =>
          (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      setState(() {
        _messages = tempMessages;
      });
    });
  }

  /// Send a text message in the current chat.
  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty && currentUser != null) {
      // Create a new message reference under the current chat.
      var newMessageRef = _messagesRef.push();
      newMessageRef.set({
        'chatID': widget.chatId, // This could be redundant, but it also clarifies the context.
        'senderID': currentUser!.uid,
        'text': text,
        'isText': true, // For now this flag is true if this is a text message.
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat for Item: ${widget.itemId}'),
      ),
      body: Column(
        children: [
          // Display chat messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      bool isCurrentUser =
                          message['senderID'] == currentUser?.uid;
                      return Container(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.blue[200]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(message['text']),
                        ),
                      );
                    },
                  ),
          ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // TextField for composing messages.
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
