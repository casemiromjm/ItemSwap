import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'item_screen.dart';
import 'chat_screen.dart';
import 'app_shell.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedType = "All";
  String _sortOption = "time";
  LatLng? _selectedLocation;
  int _itemsToLoad = 10;
  String _searchQuery = '';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final List<String> _itemTypes = [
    "All",
    'Art & Decor',
    'Baby Products',
    'Books',
    'Clothing',
    'Collectibles',
    'Electronics',
    'Food & Beverages',
    'Furniture',
    'Garden & Outdoor',
    'Health & Beauty',
    'Home Appliances',
    'Industrial Equipment',
    'Jewelry & Accessories',
    'Musical Instruments',
    'Office Supplies',
    'Pet Supplies',
    'Sports Equipment',
    'Tools & Hardware',
    'Toys & Games',
    'Transports',
    'Other',
  ];

  Image _getImageFromBase64(String base64String, {double size = 50}) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(
      decodedBytes,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  double _calculateDistance(LatLng location1, LatLng location2) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, location1, location2);
  }

  Future<void> _pickLocation() async {
    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );
    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  void _loadMoreItems() {
    setState(() {
      _itemsToLoad += 10;
    });
  }

  String _normalizeName(String name) {
    return removeDiacritics(name)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _descriptionPreview(item) {
    final description = item['description'];
    if (description == null) return 'No description';
    final firstLine = description.split('\n').first;
    return firstLine.length > 25
        ? '${firstLine.substring(0, 25)} (...)'
        : '$firstLine (...)';
  }

  Future<void> _createChat(DocumentSnapshot doc) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerId = doc['ownerId'];

    if (currentUser == null || currentUser.uid == ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot chat with yourself.")),
      );
      return;
    }

    QuerySnapshot chatQuery =
        await _firestore
            .collection('chats')
            .where('itemID', isEqualTo: doc.id)
            .get();

    String chatId = '';
    for (var chatDoc in chatQuery.docs) {
      final data = chatDoc.data() as Map<String, dynamic>;
      if (data['senderID'] == currentUser.uid ||
          data['receiverID'] == currentUser.uid) {
        chatId = chatDoc.id;
        break;
      }
    }

    if (chatId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: chatId, itemId: doc.id),
        ),
      );
    } else {
      DocumentReference newChatRef = await _firestore.collection('chats').add({
        'itemID': doc.id,
        'senderID': ownerId,
        'receiverID': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(chatId: newChatRef.id, itemId: doc.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      child: Container(
        color: const Color.fromARGB(255, 21, 45, 80),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          key: const Key('typeDropdown'),
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                          style: const TextStyle(color: Colors.white),
                          items:
                              _itemTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                              _itemsToLoad = 10;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _sortOption,
                          isExpanded: true,
                          dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: "time",
                              child: Text("Time"),
                            ),
                            DropdownMenuItem(
                              value: "location",
                              child: Text("Location"),
                            ),
                            DropdownMenuItem(
                              value: "name",
                              child: Text("Name"),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == "location" &&
                                _selectedLocation == null) {
                              await _pickLocation();
                            }
                            setState(() {
                              _sortOption = value!;
                            });
                          },
                        ),
                      ),
                      if (_sortOption == "location" &&
                          _selectedLocation != null)
                        TextButton(
                          onPressed: _pickLocation,
                          child: const Text(
                            "Change Location",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Color.fromARGB(255, 52, 83, 130),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _itemsToLoad = 10;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('items').snapshots(),
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
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'No items found.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final currentUser = _auth.currentUser;
                    List<QueryDocumentSnapshot> items = snapshot.data!.docs;

                    if (_selectedType != "All") {
                      items =
                          items
                              .where((doc) => doc['type'] == _selectedType)
                              .toList();
                    }

                    items =
                        items.where((doc) {
                          final ownerId = doc['ownerId'];
                          return ownerId != currentUser!.uid;
                        }).toList();

                    if (_searchQuery.isNotEmpty) {
                      items =
                          items.where((doc) {
                            final name = _normalizeName(doc['name'] ?? '');
                            final query = _normalizeName(_searchQuery);
                            return name.contains(query);
                          }).toList();
                    }

                    if (_sortOption == "location" &&
                        _selectedLocation != null) {
                      items.sort((a, b) {
                        final aLoc = LatLng(
                          a['location']['latitude'],
                          a['location']['longitude'],
                        );
                        final bLoc = LatLng(
                          b['location']['latitude'],
                          b['location']['longitude'],
                        );
                        return _calculateDistance(
                          aLoc,
                          _selectedLocation!,
                        ).compareTo(
                          _calculateDistance(bLoc, _selectedLocation!),
                        );
                      });
                    } else if (_sortOption == "time") {
                      items.sort(
                        (a, b) => (b['timestamp'] ?? 0).compareTo(
                          a['timestamp'] ?? 0,
                        ),
                      );
                    } else if (_sortOption == "name") {
                      items.sort((a, b) {
                        final nameA = _normalizeName(a['name'] ?? '');
                        final nameB = _normalizeName(b['name'] ?? '');
                        return nameA.compareTo(nameB);
                      });
                    }

                    final visibleItems = items.take(_itemsToLoad).toList();
                    return _buildItemList(visibleItems);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemList(List<QueryDocumentSnapshot> visibleItems) {
    if (visibleItems.isEmpty) {
      return const Center(
        child: Text('No items found.', style: TextStyle(color: Colors.white)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final doc = visibleItems[index];
              final item = doc.data() as Map<String, dynamic>;
              return Card(
                color: const Color.fromARGB(255, 52, 83, 130),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      item['imageUrl'] != null
                          ? _getImageFromBase64(item['imageUrl'])
                          : const Icon(Icons.image_not_supported, size: 50),
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
                        _descriptionPreview(item),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore
                                .collection('users')
                                .doc(item['ownerId'])
                                .get(),
                        builder: (context, userSnapshot) {
                          String username = '';
                          Widget? profilePic;
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            username = userData['username'] ?? '';
                            if (userData['image'] != null) {
                              profilePic = ClipOval(
                                child: _getImageFromBase64(
                                  userData['image'],
                                  size: 30,
                                ),
                              );
                            }
                          }
                          return Row(
                            children: [
                              if (profilePic != null) profilePic,
                              const SizedBox(width: 5),
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                        ),
                        tooltip: 'Open Chat',
                        onPressed: () {
                          _createChat(doc);
                        },
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: "More details",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemScreen(itemDoc: doc),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (visibleItems.length >= _itemsToLoad)
          ElevatedButton(onPressed: _loadMoreItems, child: const Text("More")),
      ],
    );
  }
}
