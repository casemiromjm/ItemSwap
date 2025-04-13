import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'map_screen.dart';
import 'user_screen.dart';
import 'image_handler.dart';

class ItemScreen extends StatefulWidget {
  final QueryDocumentSnapshot itemDoc;

  const ItemScreen({super.key, required this.itemDoc});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _imageBase64;
  LatLng? _location;
  bool _isOwnItem = false;
  bool _isLoading = false;

  // New variable for item type.
  String? _selectedType;
  // A list of possible item types.
  final List<String> _itemTypes = [
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

  InputDecoration itemTypeDecoration = const InputDecoration(
    labelText: 'Item Type',
    labelStyle: TextStyle(color: Colors.white),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
  );

  late Map<String, dynamic> item;

  @override
  void initState() {
    super.initState();
    item = widget.itemDoc.data() as Map<String, dynamic>;
    _loadItemData();
  }

  void _loadItemData() {
    final currentUser = _auth.currentUser;
    _isOwnItem = currentUser != null && currentUser.uid == item['ownerId'];

    _nameController.text = item['name'] ?? '';
    _descriptionController.text = item['description'] ?? '';
    _selectedType = item['type']; // Load item type from the document.
    _imageBase64 = item['imageUrl'];
    _location = LatLng(
      item['location']['latitude'],
      item['location']['longitude'],
    );
  }

  Future<void> _pickImage() async {
    if (!_isOwnItem) return;
    await pickImage((base64) {
      setState(() {
        _imageBase64 = base64;
      });
    });
  }

  Future<void> _pickLocation() async {
    if (!_isOwnItem) return;
    final selected = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MapScreen(selectable: true, initialLocation: _location!),
      ),
    );
    if (selected != null) {
      setState(() {
        _location = selected;
      });
    }
  }

  Future<void> _saveItemChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('items').doc(widget.itemDoc.id).update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'type': _selectedType, // Save the item type.
        'imageUrl': _imageBase64,
        'location': {
          'latitude': _location!.latitude,
          'longitude': _location!.longitude,
        },
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item updated!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDate(Timestamp ts) {
    return DateFormat.yMMMd().format(ts.toDate());
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: _isOwnItem ? _pickLocation : null,
      child: SizedBox(
        height: 150,
        child: FlutterMap(
          options: MapOptions(initialCenter: _location!, initialZoom: 12.0),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _location!,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// New widget for the map action button.
  Widget _buildMapActionButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
      onPressed: () {
        if (_isOwnItem) {
          _pickLocation();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      MapScreen(selectable: false, initialLocation: _location),
            ),
          );
        }
      },
      icon: Icon(_isOwnItem ? Icons.edit : Icons.fullscreen),
      label: Text(_isOwnItem ? 'Edit Location' : 'View Fullscreen'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = item['timestamp'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: Text(
          _isOwnItem ? 'Edit Item' : 'Item Details',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage:
                      _imageBase64 != null
                          ? MemoryImage(base64Decode(_imageBase64!))
                          : null,
                  child:
                      _imageBase64 == null
                          ? const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 40,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              if (timestamp != null)
                Text(
                  'Submitted on: ${_formatDate(timestamp)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              const SizedBox(height: 20),
              // Item Name Field with text length restriction.
              TextField(
                controller: _nameController,
                enabled: _isOwnItem,
                style: const TextStyle(color: Colors.white),
                maxLength: 20, // Restrict name to 20 characters.
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  counterStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 5),
              // Item Type Field.
              _isOwnItem
                  ? DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: itemTypeDecoration,
                    dropdownColor: const Color.fromARGB(255, 21, 45, 80),
                    items:
                        _itemTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  )
                  : InputDecorator(
                    decoration: itemTypeDecoration,
                    child: Text(
                      _selectedType ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              const SizedBox(height: 30),
              // Description Field with text length restriction.
              TextField(
                controller: _descriptionController,
                enabled: _isOwnItem,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                maxLength: 500, // Restrict description to 500 characters.
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  counterStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              _buildMapPreview(),
              const SizedBox(height: 8),
              _buildMapActionButton(),
              const SizedBox(height: 16),
              const Divider(height: 30, color: Colors.white),
              FutureBuilder<DocumentSnapshot>(
                future:
                    _firestore.collection('users').doc(item['ownerId']).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final username = data['username'] ?? '';
                  final profileImage = data['image'];

                  return Row(
                    children: [
                      if (profileImage != null)
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: MemoryImage(
                            base64Decode(profileImage),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => UserScreen(userId: item['ownerId']),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_isOwnItem)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveItemChanges,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
