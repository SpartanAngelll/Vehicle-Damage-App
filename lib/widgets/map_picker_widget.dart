import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double latitude, double longitude, String address) onLocationSelected;
  final bool isReadOnly;

  const MapPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
    this.isReadOnly = false,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = true;
  bool _isGettingAddress = false;
  bool _mapLoadError = false;

  // Default location (New York City) if no initial location is provided
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        // Use provided initial location
        _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _selectedAddress = widget.initialAddress;
      } else {
        // Try to get current location
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      // Fall back to default location
      _selectedLocation = _defaultLocation;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);
      await _getAddressFromCoordinates(_selectedLocation!);
    } catch (e) {
      print('Error getting current location: $e');
      // Fall back to default location
      _selectedLocation = _defaultLocation;
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      setState(() => _isGettingAddress = true);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _selectedAddress = _formatAddress(place);
      } else {
        _selectedAddress = 'Unknown location';
      }
    } catch (e) {
      print('Error getting address: $e');
      _selectedAddress = 'Address not available';
    } finally {
      setState(() => _isGettingAddress = false);
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  void _onMapTap(LatLng location) {
    if (widget.isReadOnly) return;
    
    setState(() {
      _selectedLocation = location;
    });
    
    _getAddressFromCoordinates(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _mapLoadError = false;
    });
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;

    widget.onLocationSelected(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
      _selectedAddress ?? 'Selected location',
    );

    Navigator.pop(context);
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      await _getCurrentLocation();
      if (_selectedLocation != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(_selectedLocation!),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _centerOnCurrentLocation,
              tooltip: 'Current Location',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                                 // Map
                 Expanded(
                   child: _mapLoadError
                       ? _buildMapErrorWidget()
                       : GoogleMap(
                           onMapCreated: _onMapCreated,
                           initialCameraPosition: CameraPosition(
                             target: _selectedLocation ?? _defaultLocation,
                             zoom: 15.0,
                           ),
                           onTap: _onMapTap,
                           markers: _selectedLocation != null
                               ? {
                                   Marker(
                                     markerId: const MarkerId('selected_location'),
                                     position: _selectedLocation!,
                                     draggable: !widget.isReadOnly,
                                     onDragEnd: (LatLng newPosition) {
                                       setState(() {
                                         _selectedLocation = newPosition;
                                       });
                                       _getAddressFromCoordinates(newPosition);
                                     },
                                   ),
                                 }
                               : {},
                           myLocationEnabled: !widget.isReadOnly,
                           myLocationButtonEnabled: false, // We have our own button
                           zoomControlsEnabled: false,
                         ),
                 ),
                
                // Location info and controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected location info
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_isGettingAddress)
                                  const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Getting address...'),
                                    ],
                                  )
                                else
                                  Text(
                                    _selectedAddress ?? 'No address available',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (_selectedLocation != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instructions
                      if (!widget.isReadOnly) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap on the map or drag the pin to select your business location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                      
                      // Action buttons
                      if (!widget.isReadOnly)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectedLocation != null ? _confirmLocation : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Confirm Location'),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Map Failed to Load',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your Google Maps API key configuration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _mapLoadError = false;
                    _isLoading = true;
                  });
                  _initializeLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
