import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  // Initial location set to Porto, Portugal.
  static const LatLng _initialLocation = LatLng(41.1579, -8.6291);
  
  // Current zoom level, initially set to 12.0.
  double _currentZoom = 12.0;

  // Called when the map is tapped.
  void _onMapTapped(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }

  // Confirm and return the selected location.
  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Location')),
      body: Stack(
        children: [
          // Expanded widget to fill available space with the map.
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialLocation,
                    initialZoom: _currentZoom,
                    onTap: _onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
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
              // Slider for controlling zoom, with zoom out and zoom in icons.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out),
                    Expanded(
                      child: Slider(
                        min: 5.0,
                        max: 20.0,
                        divisions: 100,
                        value: _currentZoom,
                        label: _currentZoom.toStringAsFixed(1),
                        onChanged: (newZoom) {
                          setState(() {
                            _currentZoom = newZoom;
                            // Move the map using the current center rather than resetting the view.
                            _mapController.move(_mapController.camera.center, _currentZoom);
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.zoom_in),
                  ],
                ),
              ),
            ],
          ),
          
          // FloatingActionButton at the top of the screen.
          Positioned(
            top: 16.0,
            right: 16.0,
            child: FloatingActionButton.extended(
              onPressed: _confirmLocation,
              label: const Text('Confirm Location'),
              icon: const Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }
}
