import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'permission_service.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromCamera(BuildContext context) async {
    try {
      // Check camera permission first
      final hasPermission = await PermissionService.requestCameraPermission(context);
      if (!hasPermission) {
        throw Exception('Camera permission is required to take photos');
      }

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (e) {
      if (e.toString().contains('permission')) {
        throw Exception('Camera permission denied. Please enable camera access in settings.');
      } else if (e.toString().contains('camera')) {
        throw Exception('Camera not available. Please check if camera is working.');
      } else {
        throw Exception('Failed to capture image: ${e.toString()}');
      }
    }
  }

  static Future<File?> pickImageFromGallery(BuildContext context) async {
    try {
      // Check storage permission for Android
      final hasPermission = await PermissionService.requestStoragePermission(context);
      if (!hasPermission) {
        throw Exception('Storage permission is required to access photos');
      }

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (e) {
      if (e.toString().contains('permission')) {
        throw Exception('Gallery permission denied. Please enable photo access in settings.');
      } else if (e.toString().contains('gallery')) {
        throw Exception('Gallery not available. Please check if gallery is accessible.');
      } else {
        throw Exception('Failed to select image: ${e.toString()}');
      }
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    try {
      if (!file.existsSync()) {
        return false;
      }
      
      final fileSize = file.lengthSync();
      final maxSize = 10 * 1024 * 1024; // 10MB limit
      
      if (fileSize > maxSize) {
        return false;
      }
      
      // Check if it's a valid image by trying to read it
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4) {
        return false;
      }
      
      // Basic image format validation
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return true; // JPEG
      } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return true; // PNG
      } else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return true; // GIF
      } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return true; // BMP
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get image file size in human-readable format
  static String getFileSizeString(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }

  // Compress image if needed
  static Future<File?> compressImageIfNeeded(File file, {int maxSizeBytes = 5 * 1024 * 1024}) async {
    try {
      final fileSize = file.lengthSync();
      
      if (fileSize <= maxSizeBytes) {
        return file; // No compression needed
      }
      
      // For now, return the original file
      // In a production app, you might want to implement actual image compression
      // using packages like flutter_image_compress
      return file;
    } catch (e) {
      return file; // Return original file if compression fails
    }
  }
}
