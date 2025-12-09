// Web-specific implementation for Google Maps iframe
// This file is only imported on web platform

import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Creates a Google Maps iframe widget for web
Widget buildGoogleMapsIframe({
  required double lat,
  required double lng,
  required String apiKey,
  required double height,
}) {
  // Create a unique ID for the iframe based on location
  // Using a stable ID based on coordinates to avoid re-registering on rebuilds
  final iframeId = 'google_maps_iframe_${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}';
  
  // Build the Google Maps Embed API URL
  final embedUrl = 'https://www.google.com/maps/embed/v1/place?key=$apiKey&q=$lat,$lng&zoom=15';
  
  // Register the iframe with Flutter's platform view registry
  // Note: We register directly - if already registered, it will be overwritten
  ui.platformViewRegistry.registerViewFactory(
    iframeId,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    },
  );
  
  return SizedBox(
    width: double.infinity,
    height: height,
    child: HtmlElementView(viewType: iframeId),
  );
}

