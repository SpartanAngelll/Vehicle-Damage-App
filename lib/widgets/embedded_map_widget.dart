import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EmbeddedMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isReadOnly;
  final double height;
  final VoidCallback? onTap;

  const EmbeddedMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.address,
    this.isReadOnly = true,
    this.height = 200,
    this.onTap,
  });

  @override
  State<EmbeddedMapWidget> createState() => _EmbeddedMapWidgetState();
}

class _EmbeddedMapWidgetState extends State<EmbeddedMapWidget> {
  GoogleMapController? _mapController;
  bool _mapLoadError = false;
  LatLng? _currentLocation;
  Timer? _debounceTimer;

  // Default location (New York City) if no location is provided
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  @override
  void didUpdateWidget(EmbeddedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || oldWidget.longitude != widget.longitude) {
      // Debounce location updates to prevent excessive map redraws
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updateLocation();
        }
      });
    }
  }

  void _updateLocation() {
    final hasLocation = widget.latitude != null && widget.longitude != null;
    
    // For debugging: if we have Kingston coordinates, use them
    if (hasLocation && widget.latitude == 18.009864 && widget.longitude == -76.796754) {
      print('🗺️ [EmbeddedMapWidget] Detected Kingston, Jamaica coordinates');
      _currentLocation = const LatLng(18.009864, -76.796754);
    } else {
      _currentLocation = hasLocation 
          ? LatLng(widget.latitude!, widget.longitude!)
          : _defaultLocation;
    }
    
    print('🗺️ [EmbeddedMapWidget] Location update:');
    print('   - Has location: $hasLocation');
    print('   - Latitude: ${widget.latitude}');
    print('   - Longitude: ${widget.longitude}');
    print('   - Address: ${widget.address}');
    print('   - Current location: $_currentLocation');
    
    // Update map camera if controller is available
    if (_mapController != null && hasLocation) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebMap();
    } else {
      return _buildMobileMap();
    }
  }

  Widget _buildWebMap() {
    final hasLocation = widget.latitude != null && widget.longitude != null;
    final lat = widget.latitude ?? 40.7128;
    final lng = widget.longitude ?? -74.0060;
    final address = widget.address ?? 'Location';

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Web map placeholder
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openInGoogleMaps(lat, lng, address),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tap overlay
            if (widget.onTap != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMap() {
    final hasLocation = widget.latitude != null && widget.longitude != null;
    final location = _currentLocation ?? _defaultLocation;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
                         // Map
             _mapLoadError
                 ? _buildMapErrorWidget()
                 : GoogleMap(
                     key: ValueKey('map_${widget.latitude}_${widget.longitude}'),
                     onMapCreated: _onMapCreated,
                     initialCameraPosition: CameraPosition(
                       target: location,
                       zoom: hasLocation ? 15.0 : 10.0,
                     ),
                    onTap: widget.isReadOnly ? null : (LatLng position) {
                      widget.onTap?.call();
                    },
                    markers: hasLocation
                        ? {
                            Marker(
                              markerId: const MarkerId('business_location'),
                              position: location,
                              infoWindow: InfoWindow(
                                title: 'Business Location',
                                snippet: widget.address ?? 'Selected location',
                              ),
                            ),
                          }
                        : {},
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    scrollGesturesEnabled: !widget.isReadOnly,
                    zoomGesturesEnabled: !widget.isReadOnly,
                    tiltGesturesEnabled: false,
                  ),
            
            // Overlay for read-only mode
            if (widget.isReadOnly)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            

            
            // Tap to update overlay (for current user)
            if (!widget.isReadOnly)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_location,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Tap to update',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _mapLoadError = false;
    });
    
    // Ensure map centers on the correct location
    if (_currentLocation != null) {
      print('🗺️ [EmbeddedMapWidget] Animating camera to: $_currentLocation');
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Map unavailable',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${widget.address ?? 'Not set'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng, String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
