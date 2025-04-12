import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'map_screen.dart';
import 'user_screen.dart';

class ItemDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot itemDoc;
  const ItemDetailsScreen({super.key, required this.itemDoc});

  /// Helper to decode a base64 image string into an Image widget.
  Image _getImageFromBase64(String base64String, {double size = 200}) {
    final decodedBytes = base64Decode(base64String);
    return Image.memory(
      decodedBytes,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  /// Formats a Firestore Timestamp as a human-readable date.
  String _formatDate(Timestamp timestamp) {
    DateTime dt = timestamp.toDate();
    return DateFormat.yMMMd().format(dt);
  }

  /// Builds a map preview widget using FlutterMap in non-selectable mode.
  Widget _buildMapPreview(BuildContext context, LatLng itemLocation) {
    return GestureDetector(
      onTap: () {
        // Navigate to full-screen map preview.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MapScreen(selectable: false, initialLocation: itemLocation),
          ),
        );
      },
      child: SizedBox(
        height: 150,
        child: FlutterMap(
          options: MapOptions(initialCenter: itemLocation, initialZoom: 12.0),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: itemLocation,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = itemDoc.data() as Map<String, dynamic>;
    final ownerId = item['ownerId'];
    // The item's location is assumed stored as a map with latitude and longitude.
    final itemLocation = LatLng(
      item['location']['latitude'],
      item['location']['longitude'],
    );
    return Scaffold(
      appBar: AppBar(title: Text(item['name'] ?? "Item Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child:
                  item['imageUrl'] != null
                      ? _getImageFromBase64(item['imageUrl'])
                      : const Icon(Icons.image_not_supported, size: 200),
            ),
            const SizedBox(height: 16),
            Text(
              item['name'] ?? 'Unknown Item',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Displaying item type information.
            Text(
              "Type: ${item['type'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Text(item['description'] ?? 'No description provided.'),
            const SizedBox(height: 16),
            // Map preview with gesture detection.
            _buildMapPreview(context, itemLocation),
            // Fullscreen icon below the map preview.
            Center(
              child: IconButton(
                icon: const Icon(Icons.fullscreen, size: 30),
                tooltip: "View map in fullscreen",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MapScreen(
                            selectable: false,
                            initialLocation: itemLocation,
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Submitted on: ${item['timestamp'] != null ? _formatDate(item['timestamp']) : 'Unknown'}",
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(height: 30),
            // Owner info with an icon to view the owner's details.
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(ownerId)
                      .get(),
              builder: (context, snapshot) {
                String username = '';
                Widget? profilePic;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  username = userData['username'] ?? '';
                  if (userData['profilePicture'] != null) {
                    profilePic = _getImageFromBase64(
                      userData['profilePicture'],
                      size: 50,
                    );
                  }
                }
                return Row(
                  children: [
                    if (profilePic != null) profilePic,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Icon button for read-only details of the owner.
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "View owner details",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => UserScreen(userId: ownerId),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
