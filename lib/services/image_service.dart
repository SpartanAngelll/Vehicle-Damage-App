import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import 'platform_image_service.dart';
import 'package:image/image.dart' as img;
import '../models/image_quality.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Generic pick image method - platform aware
  static Future<File?> pickImage({
    required ImageSource source,
    ImageQuality quality = ImageQuality.medium,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kIsWeb) {
        // On web, use PlatformImageService which returns Uint8List
        final bytes = await PlatformImageService.pickImage(
          source: source,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        
        if (bytes != null) {
          // On web, we can't return a File, but we need to handle this differently
          // The calling code should use PlatformImageService directly on web
          throw Exception('On web, use PlatformImageService.pickImage() which returns Uint8List');
        }
        return null;
      } else {
        // On mobile, use File-based approach
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: imageQuality ?? _getImageQuality(quality),
          maxWidth: maxWidth ?? _getMaxWidth(quality)?.toDouble(),
          maxHeight: maxHeight ?? _getMaxHeight(quality)?.toDouble(),
        );
        
        if (image != null) {
          final file = File(image.path);
          if (_validateImageFile(file)) {
            return file;
          } else {
            throw Exception('Invalid image file');
          }
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick single image from camera
  static Future<File?> pickImageFromCamera({
    ImageQuality quality = ImageQuality.medium,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _getImageQuality(quality),
        maxWidth: _getMaxWidth(quality)?.toDouble(),
        maxHeight: _getMaxHeight(quality)?.toDouble(),
      );
      
      if (image != null) {
        final file = File(image.path);
        if (_validateImageFile(file)) {
          return file;
        } else {
          throw Exception('Invalid image file');
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Pick single image from gallery
  static Future<File?> pickImageFromGallery({
    ImageQuality quality = ImageQuality.medium,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _getImageQuality(quality),
        maxWidth: _getMaxWidth(quality)?.toDouble(),
        maxHeight: _getMaxHeight(quality)?.toDouble(),
      );
      
      if (image != null) {
        final file = File(image.path);
        if (_validateImageFile(file)) {
          return file;
        } else {
          throw Exception('Invalid image file');
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Pick multiple images from gallery - platform aware
  static Future<List<File>> pickMultipleImagesFromGallery({
    ImageQuality quality = ImageQuality.medium,
    int maxImages = 5,
  }) async {
    try {
      if (kIsWeb) {
        // On web, we need to handle this differently
        // For now, we'll pick one image at a time on web
        // The calling code should be updated to use PlatformImageService
        throw Exception('On web, multiple image picking is not supported via ImageService. Use PlatformImageService or pick images one at a time.');
      }
      
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: _getImageQuality(quality),
        maxWidth: _getMaxWidth(quality)?.toDouble(),
        maxHeight: _getMaxHeight(quality)?.toDouble(),
      );
      
      final List<File> validFiles = [];
      
      for (final image in images.take(maxImages)) {
        final file = File(image.path);
        if (_validateImageFile(file)) {
          validFiles.add(file);
        }
      }
      
      return validFiles;
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  // Pick multiple images from camera (multiple shots) - platform aware
  static Future<List<File>> pickMultipleImagesFromCamera({
    ImageQuality quality = ImageQuality.medium,
    int maxImages = 5,
  }) async {
    try {
      if (kIsWeb) {
        // On web, camera access is limited - typically one image at a time
        throw Exception('On web, multiple camera images are not supported. Use PlatformImageService to pick one image at a time.');
      }
      
      final List<File> images = [];
      
      for (int i = 0; i < maxImages; i++) {
        final image = await pickImageFromCamera(quality: quality);
        if (image != null) {
          images.add(image);
        } else {
          break; // User cancelled
        }
      }
      
      return images;
    } catch (e) {
      throw Exception('Failed to pick multiple images from camera: $e');
    }
  }

  // Validate image file
  static bool _validateImageFile(File file) {
    if (!StorageService.isValidImageFile(file)) {
      return false;
    }
    
    if (!StorageService.isFileSizeValid(file)) {
      return false;
    }
    
    return true;
  }

  // Public method for validating image files
  static bool isValidImageFile(File file) {
    return _validateImageFile(file);
  }

  // Get image quality value for ImagePicker
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

  // Get max width for ImagePicker
  static int? _getMaxWidth(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 512;
      case ImageQuality.medium:
        return 1024;
      case ImageQuality.high:
        return 2048;
      case ImageQuality.original:
        return null;
    }
  }

  // Get max height for ImagePicker
  static int? _getMaxHeight(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 512;
      case ImageQuality.medium:
        return 1024;
      case ImageQuality.high:
        return 2048;
      case ImageQuality.original:
        return null;
    }
  }

  // Get file size in readable format
  static String getFileSizeString(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Check if image needs compression
  static bool needsCompression(File file) {
    return StorageService.getFileSizeInMB(file) > 2.0; // Compress if > 2MB
  }

  // Get image dimensions
  static Future<Map<String, int>?> getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

