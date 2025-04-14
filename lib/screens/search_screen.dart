import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'item_screen.dart'; // New screen for item details

class SearchScreen extends StatefulWidget {
  final bool isMyItems;
  const SearchScreen({super.key, this.isMyItems = false});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedType = "All";
  String _sortOption = "time";
  LatLng? _selectedLocation;
  int _itemsToLoad = 10;
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

  /// Returns an Image widget decoded from a base64 string.
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

  void _showDeleteConfirmation(DocumentSnapshot doc) {
    final String itemName = doc['name'] ?? 'this item';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 52, 83, 130),
          title: Text(
            "Delete '$itemName'?",
            style: const TextStyle(color: Colors.white),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // Cancel button (✗ in red) positioned to the left.
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog.
              },
              child: const Text(
                '✗',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            // Confirm delete button (✓ in green) positioned to the right.
            TextButton(
              onPressed: () async {
                try {
                  await _firestore.collection('items').doc(doc.id).delete();
                  Navigator.of(context).pop(); // Dismiss the dialog.
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: Center(
          child: Text(
            widget.isMyItems ? 'My Items' : 'Search Items',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter and sort options
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color.fromARGB(255, 52, 83, 130),
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
                      DropdownMenuItem(value: "time", child: Text("Time")),
                      DropdownMenuItem(
                        value: "location",
                        child: Text("Location"),
                      ),
                      DropdownMenuItem(value: "name", child: Text("Name")),
                    ],
                    onChanged: (value) async {
                      if (value == "location" && _selectedLocation == null) {
                        await _pickLocation();
                      }
                      setState(() {
                        _sortOption = value!;
                      });
                    },
                  ),
                ),
                if (_sortOption == "location" && _selectedLocation != null)
                  TextButton(
                    onPressed: _pickLocation,
                    child: const Text(
                      "Change Location",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // "New Item" button above the items list when in My Items mode.
            if (widget.isMyItems)
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ItemScreen()),
                  );
                  if (result == 'submitted') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item submitted successfully!'),
                      ),
                    );
                  }
                },
                child: const Text("New Item"),
              ),
            const SizedBox(height: 10),
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

                  // Filter by type if needed.
                  if (_selectedType != "All") {
                    items =
                        items
                            .where((doc) => doc['type'] == _selectedType)
                            .toList();
                  }
                  // Filter items by ownership.
                  items =
                      items.where((doc) {
                        final ownerId = doc['ownerId'];
                        return widget.isMyItems
                            ? ownerId == currentUser!.uid
                            : ownerId != currentUser!.uid;
                      }).toList();

                  // Sort items.
                  if (_sortOption == "location" && _selectedLocation != null) {
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
                      ).compareTo(_calculateDistance(bLoc, _selectedLocation!));
                    });
                  } else if (_sortOption == "time") {
                    items.sort(
                      (a, b) =>
                          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
                    );
                  } else if (_sortOption == "name") {
                    items.sort((a, b) {
                      final nameA = _normalizeName(a['name'] ?? '');
                      final nameB = _normalizeName(b['name'] ?? '');
                      return nameA.compareTo(nameB);
                    });
                  }

                  final visibleItems = items.take(_itemsToLoad).toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: visibleItems.length,
                          itemBuilder: (context, index) {
                            final doc = visibleItems[index];
                            final item = doc.data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 7.0),
                              child: ListTile(
                                leading:
                                    item['imageUrl'] != null
                                        ? _getImageFromBase64(item['imageUrl'])
                                        : const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                        ),
                                title: Text(item['name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_descriptionPreview(item)),
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                // Trailing buttons: Chat button if in Search mode, and a plus icon for item details.
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!widget.isMyItems)
                                      ElevatedButton(
                                        onPressed: () {
                                          // Insert your chat logic here.
                                        },
                                        child: const Text("Chat"),
                                      ),
                                    if (widget.isMyItems)
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: "Delete",
                                        onPressed: () {
                                          _showDeleteConfirmation(doc);
                                        },
                                      ),
                                    const SizedBox(width: 5),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      tooltip: "More details",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ItemScreen(itemDoc: doc),
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
                      if (items.length > _itemsToLoad)
                        ElevatedButton(
                          onPressed: _loadMoreItems,
                          child: const Text("More"),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
