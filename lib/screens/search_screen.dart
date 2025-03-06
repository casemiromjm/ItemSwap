import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_database/firebase_database.dart';
import 'dart:convert'; // Para usar base64
import 'map_screen.dart';
import 'package:latlong2/latlong.dart'; // Para calcular distâncias
import 'package:diacritic/diacritic.dart'; // Para remover acentos

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedType = "All";
  String _sortOption = "time"; // Padrão: ordenação por tempo
  LatLng? _selectedLocation;
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

  //final DatabaseReference _itemsRef = FirebaseDatabase.instance.ref('items');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _itemsToLoad = 10;

  Image _getImageFromBase64(String base64String) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(decodedBytes, width: 50, height: 50, fit: BoxFit.cover);
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
        .replaceAll(RegExp(r'\s+'), '') // Remove espaços
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Remove caracteres especiais
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(title: const Text('Search Items')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Item Type:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              style: TextStyle(color: Colors.white),
              dropdownColor: const Color.fromARGB(255, 52, 83, 130),
              items:
                  _itemTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _itemsToLoad = 10;
                });
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _sortOption,
                  dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                  style: TextStyle(color: Colors.white),
                  items: [
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
                if (_sortOption == "location" && _selectedLocation != null)
                  TextButton(
                    onPressed: _pickLocation,
                    child: Text(
                      "Change Location",
                      style: TextStyle(color: Colors.white),
                    ),
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
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No items found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  //Map<dynamic, dynamic> allItems = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  //List<MapEntry<dynamic, dynamic>> filteredItems = allItems.entries.toList();
                  List<QueryDocumentSnapshot> filteredItems =
                      snapshot.data!.docs;

                  if (_selectedType != "All") {
                    filteredItems =
                        filteredItems
                            .where((doc) => doc['type'] == _selectedType)
                            .toList();
                  }

                  if (_sortOption == "location" && _selectedLocation != null) {
                    filteredItems.sort((a, b) {
                      LatLng itemLocationA = LatLng(
                        a['location']['latitude'],
                        a['location']['longitude'],
                      );
                      LatLng itemLocationB = LatLng(
                        b['location']['latitude'],
                        b['location']['longitude'],
                      );
                      double distanceA = _calculateDistance(
                        itemLocationA,
                        _selectedLocation!,
                      );
                      double distanceB = _calculateDistance(
                        itemLocationB,
                        _selectedLocation!,
                      );
                      return distanceA.compareTo(distanceB);
                    });
                  } else if (_sortOption == "time") {
                    filteredItems.sort((a, b) {
                      return (b['timestamp'] ?? 0).compareTo(
                        a['timestamp'] ?? 0,
                      );
                    });
                  } else if (_sortOption == "name") {
                    filteredItems.sort((a, b) {
                      String nameA = _normalizeName(a['name'] ?? '');
                      String nameB = _normalizeName(b['name'] ?? '');
                      return nameA.compareTo(nameB);
                    });
                  }

                  //List<MapEntry<dynamic, dynamic>> itemsToShow = filteredItems.take(_itemsToLoad).toList();
                  List<QueryDocumentSnapshot> itemsToShow =
                      filteredItems.take(_itemsToLoad).toList();

                  List<Widget> itemWidgets =
                      itemsToShow.map((doc) {
                        var item = doc.data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading:
                                item['imageUrl'] != null
                                    ? _getImageFromBase64(item['imageUrl'])
                                    : Icon(Icons.image_not_supported),
                            title: Text(item['name'] ?? 'Unknown'),
                            subtitle: Text(
                              item['description'] ?? 'No description',
                            ),
                          ),
                        );
                      }).toList();

                  return Column(
                    children: [
                      Expanded(child: ListView(children: itemWidgets)),
                      if (filteredItems.length > _itemsToLoad)
                        ElevatedButton(
                          onPressed: _loadMoreItems,
                          child: Text("More"),
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
