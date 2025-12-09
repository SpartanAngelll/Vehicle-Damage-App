// Stub implementation for non-web platforms
// This file is imported on non-web platforms

import 'package:flutter/widgets.dart';

/// Stub function that should never be called on non-web platforms
Widget buildGoogleMapsIframe({
  required double lat,
  required double lng,
  required String apiKey,
  required double height,
}) {
  throw UnsupportedError('buildGoogleMapsIframe is only supported on web');
}

