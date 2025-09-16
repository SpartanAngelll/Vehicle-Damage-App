import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import '../models/image_quality.dart';

class PlatformImageService {
  static final ImagePicker _picker = ImagePicker();

  // Platform-aware image picking
  static Future<Uint8List?> pickImage({
    required ImageSource source,
    ImageQuality quality = ImageQuality.medium,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kIsWeb) {
        return await _pickImageWeb(source, quality, maxWidth, maxHeight, imageQuality);
      } else {
        return await _pickImageMobile(source, quality, maxWidth, maxHeight, imageQuality);
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Web image picking
  static Future<Uint8List?> _pickImageWeb(
    ImageSource source,
    ImageQuality quality,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  ) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality ?? _getImageQuality(quality),
      maxWidth: maxWidth ?? _getMaxWidth(quality)?.toDouble(),
      maxHeight: maxHeight ?? _getMaxHeight(quality)?.toDouble(),
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      return bytes;
    }
    return null;
  }

  // Mobile image picking
  static Future<Uint8List?> _pickImageMobile(
    ImageSource source,
    ImageQuality quality,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  ) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality ?? _getImageQuality(quality),
      maxWidth: maxWidth ?? _getMaxWidth(quality)?.toDouble(),
      maxHeight: maxHeight ?? _getMaxHeight(quality)?.toDouble(),
    );
    
    if (image != null) {
      final file = File(image.path);
      if (_validateImageFile(file)) {
        return await file.readAsBytes();
      } else {
        throw Exception('Invalid image file');
      }
    }
    return null;
  }

  // Platform-aware image display
  static Widget buildImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (kIsWeb) {
      return _buildWebImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    } else {
      return _buildMobileImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
  }

  // Web image widget
  static Widget _buildWebImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Container(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      ),
    );
  }

  // Mobile image widget
  static Widget _buildMobileImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Container(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      ),
    );
  }

  // Helper methods
  static int _getImageQuality(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 50;
      case ImageQuality.medium:
        return 75;
      case ImageQuality.high:
        return 90;
      case ImageQuality.original:
        return 100;
    }
  }

  static int? _getMaxWidth(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 800;
      case ImageQuality.medium:
        return 1200;
      case ImageQuality.high:
        return 1920;
      case ImageQuality.original:
        return null;
    }
  }

  static int? _getMaxHeight(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 600;
      case ImageQuality.medium:
        return 900;
      case ImageQuality.high:
        return 1080;
      case ImageQuality.original:
        return null;
    }
  }

  static bool _validateImageFile(File file) {
    if (!file.existsSync()) return false;
    final size = file.lengthSync();
    return size > 0 && size < 10 * 1024 * 1024; // Max 10MB
  }
}

