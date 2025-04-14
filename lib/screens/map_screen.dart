import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  /// If true, the map is interactive—tapping lets the user choose a location
  /// and the confirm button is visible.
  final bool selectable;

  /// In non-selectable mode, show the map centered on this location.
  /// In selectable mode, if provided, shows the currently selected location.
  final LatLng? initialLocation;

  const MapScreen({Key? key, this.selectable = true, this.initialLocation})
    : super(key: key);

  @override
  _CustomMapScreenState createState() => _CustomMapScreenState();
}

class _CustomMapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

  // Default location if none is selected (Porto, Portugal)
  static const LatLng _defaultLocation = LatLng(41.1579, -8.6291);

  @override
  void initState() {
    super.initState();
    // In non-selectable mode, show the passed location if available.
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
    }
  }

  /// When in selectable mode, update the selection on map tap.
  void _onMapTapped(TapPosition tapPosition, LatLng latlng) {
    if (widget.selectable) {
      setState(() {
        _selectedLocation = latlng;
      });
    }
  }

  /// In selectable mode, confirm the chosen location and return it.
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
    // Center the map:
    // • In selectable mode, use the current selection (or default location if none).
    // • In non-selectable mode, force the center to the provided initialLocation.
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
                    // Allow tap only if selectable.
                    onTap: _onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    // Show a marker if a location is selected (or provided).
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
              // Zoom controls
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
          // Only show the confirm button if the map is selectable.
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
