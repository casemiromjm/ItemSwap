import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
//import 'package:firebase_database/firebase_database.dart'; // Para usar Realtime Database
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore Import
import 'dart:io';
import 'dart:convert'; // Para usar base64
import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'package:image/image.dart' as img; // Para manipular imagens
// Web-specific imports (file_picker for web file picking)
import 'package:file_picker/file_picker.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  //File? _image;
  String? _imageBase64; // Para armazenar a imagem em base64 na Web
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
    if (kIsWeb) {
      // Web-specific image picking code using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        // Get the selected file
        final file = result.files.single;

        // Compress the image before displaying
        final compressedImageBase64 = await _compressImageFile(file.bytes!);

        setState(() {
          _imageBase64 = compressedImageBase64;
        });
      }
    } else {
      // Mobile/Desktop-specific image picking code using image_picker
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final compressedImageBase64 = await _compressImageFile(bytes);
        setState(() {
          _imageBase64 = compressedImageBase64;
        });
      }
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

  // Compress the picked image for both mobile and web
  Future<String> _compressImageFile(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int maxHeight = 200,
    int quality = 30,
  }) async {
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      img.Image resizedImage = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
      );

      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      return base64Encode(compressedBytes);
    } else {
      throw Exception('Failed to compress image');
    }
  }

  final RegExp validNameRegExp = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');

  Future<void> _submitItem() async {
    if (_selectedType != null &&
        validNameRegExp.hasMatch(
          _nameController.text,
        ) && // Pelo menos uma letra válida
        _descriptionController.text.isNotEmpty &&
        _selectedLocation != null) {
      try {
        // Se a imagem for selecionada, converter para base64
        String imageUrl = '';
        if (_imageBase64 != null) {
          imageUrl = _imageBase64!; // Para a Web, usa a imagem em base64
        }

        // Salvar item no Firestore
        await FirebaseFirestore.instance.collection('items').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'type': _selectedType,
          'imageUrl': imageUrl, // Imagem convertida em base64
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'timestamp': FieldValue.serverTimestamp(), // Firestore timestamp
        });

        // Navegar para a HomeScreen
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
                    _itemTypes.map((type) {
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
                        label: Text('Change Image'),
                      ),
                    ],
                  )
                  : ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text('Select Image'),
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
