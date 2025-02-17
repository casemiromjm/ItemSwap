import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';  // Para usar base64
import 'dart:typed_data'; // Para converter base64 para bytes

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

  final DatabaseReference _itemsRef = FirebaseDatabase.instance.ref('items'); // Referência ao nó "items" no Realtime Database

  // Função para converter base64 para imagem
  Image _getImageFromBase64(String base64String) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(
      decodedBytes,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );
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
            Text('Select Item Type:', style: TextStyle(color: Colors.white, fontSize: 18)),
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              hint: Text('Choose type', style: TextStyle(color: Colors.white)),
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
            const SizedBox(height: 20),

            Expanded(
              child: _selectedType == null
                  ? Center(child: Text('Please select an item type', style: TextStyle(color: Colors.white)))
                  : StreamBuilder<DatabaseEvent>(
                      stream: _itemsRef
                          .orderByChild('type') // Filtro para o tipo do item
                          .equalTo(_selectedType)
                          .onValue, // Assina para as mudanças em tempo real
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                          return Center(
                            child: Text(
                              'No items found for this type.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        // Mapeamento dos itens
                        Map<dynamic, dynamic> items = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                        List<Widget> itemWidgets = [];
                        items.forEach((key, value) {
                          var item = value as Map<dynamic, dynamic>;
                          itemWidgets.add(
                            Card(
                              color: Colors.white,
                              child: ListTile(
                                leading: item['imageUrl'] != null
                                    ? _getImageFromBase64(item['imageUrl']) // Usar base64 para a imagem
                                    : Icon(Icons.image_not_supported),
                                title: Text(item['name'] ?? 'Unknown'),
                                subtitle: Text(item['description'] ?? 'No description'),
                              ),
                            ),
                          );
                        });

                        return ListView(
                          children: itemWidgets,
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
