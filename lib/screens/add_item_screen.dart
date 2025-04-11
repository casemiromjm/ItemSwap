import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_database/firebase_database.dart'; // For Realtime Database
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore Import
import 'dart:convert'; // For base64
import 'package:latlong2/latlong.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'image_handler.dart';

class AddItemScreen extends StatefulWidget {
  final WidgetBuilder? mapScreenBuilder;
  final FirebaseAuth? auth; // <-- Optional injected auth instance
  final FirebaseFirestore firestore;

  const AddItemScreen({
    Key? key,
    this.mapScreenBuilder,
    this.auth,
    required this.firestore, // <-- Added required keyword for firestore
  }): super(key: key);

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  //File? _image;
  String? _imageBase64; // To store the base64 image for the Web
  LatLng? _selectedLocation;

  TextStyle color_white = const TextStyle(color: Colors.white);

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

  // Function to pick image
  Future<void> _pickImage() async {
    await pickImage((compressedImageBase64) {
      setState(() {
        _imageBase64 = compressedImageBase64;
      });
    });
  }

  Future<void> _pickLocation() async {
    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: widget.mapScreenBuilder ?? (context) => MapScreen(),
      ),
    );

    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  final RegExp validNameRegExp = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

  Future<void> _submitItem() async {
    // Use the injected auth instance (if provided) or fallback to FirebaseAuth.instance.
    final FirebaseAuth auth = widget.auth ?? FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (_selectedType != null &&
        validNameRegExp.hasMatch(
          _nameController.text,
        ) && // At least one valid letter
        _descriptionController.text.isNotEmpty &&
        _selectedLocation != null &&
        currentUser != null) {
      try {
        // If an image is selected, convert to base64
        String imageUrl = '';
        if (_imageBase64 != null) {
          imageUrl = _imageBase64!; // For the web, use base64 image
        }

        // Save item to Firestore with the owner's ID (currentUser.uid)
        await widget.firestore.collection('items').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'type': _selectedType,
          'imageUrl': imageUrl, // Base64 encoded image
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'timestamp': FieldValue.serverTimestamp(), // Firestore timestamp
          'ownerId': currentUser.uid, // Link to the current user's UID
        });

        // Navigate to the HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 45, 80),
      appBar: AppBar(title: const Text('Add New Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Type Dropdown
              Text(
                'Select Item Type:',
                style: color_white.copyWith(fontSize: 20),
              ),
              DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                hint: Text('Choose type', style: color_white),
                style: color_white,
                dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                items:
                    _itemTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Item Name Field
              Text(
                '\nType the name of the item:',
                style: color_white.copyWith(fontSize: 20),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter item name',
                  hintStyle: color_white,
                ),
                maxLength: 20,
                style: color_white,
              ),
              const SizedBox(height: 10),

              // Image Upload
              Text(
                '\nUpload an image of the item:',
                style: color_white.copyWith(fontSize: 20),
              ),
              _imageBase64 != null
                  ? Column(
                    children: [
                      Image.memory(
                        base64Decode(_imageBase64!),
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Change Image'),
                      ),
                    ],
                  )
                  : ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  ),

              // Description Field
              Text(
                '\nType a description of the item:',
                style: color_white.copyWith(fontSize: 20),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 10,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                  hintStyle: color_white,
                ),
                maxLength: 500,
                style: color_white,
              ),
              const SizedBox(height: 10),

              // Location Button
              Text(
                '\nChoose the location of the item:',
                style: color_white.copyWith(fontSize: 20),
              ),
              ElevatedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map),
                label: Text(
                  _selectedLocation == null
                      ? 'Pick a location'
                      : 'Selected: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _submitItem,
                  child: const Text('Submit Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
