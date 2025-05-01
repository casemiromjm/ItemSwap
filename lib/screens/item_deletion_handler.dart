import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDeletionHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes the item document with the given [itemId],
  /// then finds and deletes all chat documents where 'itemID' == [itemId]
  /// and all messages in each chat's 'messages' subcollection.
  static Future<void> deleteItemAndRelatedChats(String itemId) async {
    final itemRef = _firestore.collection('items').doc(itemId);

    // 1. Delete the item itself.
    await itemRef.delete();

    // 2. Query all chats referencing this item.
    final chatsQuery =
        await _firestore
            .collection('chats')
            .where('itemID', isEqualTo: itemId)
            .get();

    for (final chatDoc in chatsQuery.docs) {
      final chatRef = chatDoc.reference;

      // 3. Delete all messages in the chat's subcollection.
      final messagesSnapshot = await chatRef.collection('messages').get();
      for (final msg in messagesSnapshot.docs) {
        await msg.reference.delete();
      }

      // 4. Delete the chat document itself.
      await chatRef.delete();
    }
  }
}
