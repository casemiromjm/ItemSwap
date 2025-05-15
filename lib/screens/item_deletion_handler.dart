import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDeletionHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> deleteItemAndRelatedChats(String itemId) async {
    final itemRef = _firestore.collection('items').doc(itemId);

    final chatsQuery =
        await _firestore
            .collection('chats')
            .where('itemID', isEqualTo: itemId)
            .get();

    for (final chatDoc in chatsQuery.docs) {
      final chatRef = chatDoc.reference;
      final messagesSnapshot = await chatRef.collection('messages').get();
      for (final msg in messagesSnapshot.docs) {
        await msg.reference.delete();
      }
      await chatRef.delete();
    }
    await itemRef.delete();
  }
}
