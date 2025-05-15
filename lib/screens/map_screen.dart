import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final bool selectable;
  final LatLng? initialLocation;
  const MapScreen({super.key, this.selectable = true, this.initialLocation});

  @override
  _CustomMapScreenState createState() => _CustomMapScreenState();
}

class _CustomMapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;
  static const LatLng _defaultLocation = LatLng(41.1579, -8.6291);

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng latlng) {
    if (widget.selectable) {
      setState(() {
        _selectedLocation = latlng;
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center =
        widget.selectable
            ? (_selectedLocation ?? _defaultLocation)
            : (widget.initialLocation ?? _defaultLocation);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 133, 190),
        title: const Center(
          child: Text(
            'Map',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _currentZoom,
                    onTap: _onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_selectedLocation != null ||
                        widget.initialLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
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
                            _mapController.move(center, _currentZoom);
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
          if (widget.selectable)
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
