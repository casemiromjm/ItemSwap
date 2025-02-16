import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test1/screens/home_screen.dart';
import 'dart:io';
import 'map_screen.dart';
import 'package:latlong2/latlong.dart';

class AddItemScreen extends StatefulWidget {
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  File? _image;
  LatLng? _selectedLocation;

  TextStyle color_white = TextStyle(color: Colors.white);

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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

  void _submitItem() {
    if (_selectedType != null &&
        _nameController.text.isNotEmpty &&
        _image != null &&
        _descriptionController.text.isNotEmpty &&
        _selectedLocation != null) {
      Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item submitted successfully!')),
      );
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
              Text('Select Item Type:', style: color_white.copyWith(fontSize: 20),),
              DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                hint: Text('Choose type', style: color_white,),
                style: color_white,
                dropdownColor: const Color.fromARGB(255, 52, 83, 130),
                items: _itemTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Item Name Field
              Text('\nType the name of the item:', style: color_white.copyWith(fontSize: 20),),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Enter item name', hintStyle: color_white,),
                maxLength: 20,
                style: color_white,
              ),
              const SizedBox(height: 10),

              // Image Upload
                Text('\nUpload an image of the item:', style: color_white.copyWith(fontSize: 20),),
                _image != null
                  ? Column(
                    children: [
                      Image.file(
                        _image!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text('Change Image'),  // Change button label
                    ),
                  ],
                )
              : ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text('Select Image'),
              ),
              
              // Description Field
              Text('\nType a description of the item:', style: color_white.copyWith(fontSize: 20),),
              TextField(
                controller: _descriptionController,
                maxLines: 10,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Enter description', hintStyle: color_white,),
                maxLength: 500,
                style: color_white,
              ),
              const SizedBox(height: 10),

              // Location Dropdown
              Text('\nChoose the location of the item:', style: color_white.copyWith(fontSize: 20),),
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
