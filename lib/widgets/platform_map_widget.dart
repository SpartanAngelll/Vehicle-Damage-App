import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isReadOnly;
  final double height;
  final ArgumentCallback<LatLng>? onTap;

  const PlatformMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.address,
    this.isReadOnly = true,
    this.height = 200,
    this.onTap,
  });

  @override
  State<PlatformMapWidget> createState() => _PlatformMapWidgetState();
}

class _PlatformMapWidgetState extends State<PlatformMapWidget> {
  bool _mapLoadError = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebMap();
    } else {
      return _buildMobileMap();
    }
  }

  Widget _buildWebMap() {
    if (_mapLoadError) {
      return _buildErrorWidget();
    }

    final lat = widget.latitude ?? 40.7128;
    final lng = widget.longitude ?? -74.0060;
    final address = widget.address ?? 'Location';

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Google Maps embed for web
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
                  onTap: () {
                    if (widget.latitude != null && widget.longitude != null) {
                      widget.onTap!(LatLng(widget.latitude!, widget.longitude!));
                    }
                  },
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
    if (_mapLoadError) {
      return _buildErrorWidget();
    }

    final lat = widget.latitude ?? 40.7128;
    final lng = widget.longitude ?? -74.0060;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('location'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: widget.address ?? 'Location',
              ),
            ),
          },
          onMapCreated: (GoogleMapController controller) {
            // Map created successfully
          },
          onTap: widget.onTap,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Map unavailable',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.address ?? 'Location',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                final lat = widget.latitude ?? 40.7128;
                final lng = widget.longitude ?? -74.0060;
                final address = widget.address ?? 'Location';
                _openInGoogleMaps(lat, lng, address);
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in Maps'),
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
}
