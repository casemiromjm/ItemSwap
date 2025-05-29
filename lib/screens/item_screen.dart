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
  final QueryDocumentSnapshot? itemDoc;
  const ItemScreen({super.key, this.itemDoc});

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
  bool _isNewItem = false;
  String? _selectedType;
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

  InputDecoration buildTextFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      disabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      counterStyle: const TextStyle(color: Colors.grey),
    );
  }

  late Map<String, dynamic> item;

  @override
  void initState() {
    super.initState();
    _isNewItem = widget.itemDoc == null;
    final currentUser = _auth.currentUser;
    _isOwnItem = currentUser != null;
    if (_isNewItem) {
      _nameController.text = '';
      _descriptionController.text = '';
      _selectedType = null;
      _imageBase64 = null;
      _location = LatLng(41.1579, -8.6291);
    } else {
      item = widget.itemDoc!.data() as Map<String, dynamic>;
      _loadItemData();
    }
  }

  void _loadItemData() {
    final currentUser = _auth.currentUser;
    _isOwnItem = currentUser != null && currentUser.uid == item['ownerId'];

    _nameController.text = item['name'] ?? '';
    _descriptionController.text = item['description'] ?? '';
    _selectedType = item['type'];
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
            (context) => MapScreen(
              selectable: true,
              initialLocation: _location ?? LatLng(0, 0),
            ),
      ),
    );
    if (selected != null) {
      setState(() {
        _location = selected;
      });
    }
  }

  Future<void> _saveItemChanges() async {
    final RegExp validNameRegExp = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');
    if (_nameController.text.trim().isEmpty ||
        !validNameRegExp.hasMatch(_nameController.text) ||
        _descriptionController.text.trim().isEmpty ||
        _selectedType == null ||
        _selectedType!.trim().isEmpty ||
        _imageBase64 == null ||
        _imageBase64!.trim().isEmpty ||
        _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields correctly.")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = _auth.currentUser;
      if (_isNewItem) {
        await _firestore.collection('items').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'type': _selectedType,
          'imageUrl': _imageBase64,
          'location': {
            'latitude': _location!.latitude,
            'longitude': _location!.longitude,
          },
          'ownerId': currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context, 'submitted');
      } else {
        await _firestore.collection('items').doc(widget.itemDoc!.id).update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'type': _selectedType,
          'imageUrl': _imageBase64,
          'location': {
            'latitude': _location!.latitude,
            'longitude': _location!.longitude,
          },
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Item updated!")));
      }
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
    final timestamp =
        !_isNewItem && item['timestamp'] is Timestamp
            ? item['timestamp'] as Timestamp
            : null;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: Center(
          child: Text(
            _isOwnItem
                ? (_isNewItem ? 'New Item' : 'Edit Item')
                : 'Item Details',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
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
              TextField(
                controller: _nameController,
                readOnly: !_isOwnItem,
                style: const TextStyle(color: Colors.white),
                maxLength: 20,
                decoration: buildTextFieldDecoration('Item Name'),
              ),
              const SizedBox(height: 5),
              _isOwnItem
                  ? DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: buildTextFieldDecoration('Item Type'),
                    dropdownColor: const Color.fromARGB(255, 52, 83, 130),
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
                    decoration: buildTextFieldDecoration('Item Type'),
                    child: Text(
                      _selectedType ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              const SizedBox(height: 30),
              TextField(
                controller: _descriptionController,
                readOnly: !_isOwnItem,
                minLines: 3,
                maxLines: 10,
                style: const TextStyle(color: Colors.white),
                maxLength: 500,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                decoration: buildTextFieldDecoration('Description'),
              ),
              const SizedBox(height: 16),
              _buildMapPreview(),
              const SizedBox(height: 8),
              _buildMapActionButton(),
              const SizedBox(height: 16),
              const Divider(height: 30, color: Colors.white),
              FutureBuilder<DocumentSnapshot>(
                future:
                    _firestore
                        .collection('users')
                        .doc(
                          _isNewItem ? _auth.currentUser!.uid : item['ownerId'],
                        )
                        .get(),
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
                  key: const Key('submit_button'),
                  onPressed: _isLoading ? null : _saveItemChanges,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isNewItem ? 'Create Item' : 'Save Changes'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
