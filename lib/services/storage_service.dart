import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Storage references
  static Reference get _damageReportsRef => _storage.ref('damage_reports');
  static Reference get _estimatesRef => _storage.ref('estimates');
  static Reference get _userProfilesRef => _storage.ref('user_profiles');

  // Image compression and processing
  static Future<Uint8List> compressImage(File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Read image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > maxWidth || image.height > maxHeight) {
        if (image.width > image.height) {
          newWidth = maxWidth;
          newHeight = (image.height * maxWidth / image.width).round();
        } else {
          newHeight = maxHeight;
          newWidth = (image.width * maxHeight / image.height).round();
        }
      }

      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Convert to JPEG with specified quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  // Upload damage report images
  static Future<List<String>> uploadDamageReportImages({
    required String reportId,
    required List<File> images,
    required String ownerId,
  }) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final fileName = '${reportId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageRef = _damageReportsRef.child(ownerId).child(reportId).child(fileName);
        
        // Compress image before upload
        final compressedImage = await compressImage(imageFile);
        
        // Upload compressed image
        final uploadTask = imageRef.putData(
          compressedImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'originalName': path.basename(imageFile.path),
              'uploadedAt': DateTime.now().toIso8601String(),
              'compressed': 'true',
            },
          ),
        );
        
        // Wait for upload to complete
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload damage report images: $e');
    }
  }

  // Upload estimate images
  static Future<List<String>> uploadEstimateImages({
    required String estimateId,
    required List<File> images,
    required String repairmanId,
    required String reportId,
  }) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final fileName = '${estimateId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageRef = _estimatesRef.child(reportId).child(estimateId).child(fileName);
        
        // Compress image before upload
        final compressedImage = await compressImage(imageFile);
        
        // Upload compressed image
        final uploadTask = imageRef.putData(
          compressedImage,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'originalName': path.basename(imageFile.path),
              'uploadedAt': DateTime.now().toIso8601String(),
              'compressed': 'true',
            },
          ),
        );
        
        // Wait for upload to complete
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload estimate images: $e');
    }
  }

  // Upload user profile image
  static Future<String?> uploadUserProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageRef = _userProfilesRef.child(userId).child(fileName);
      
      // Compress image before upload
      final compressedImage = await compressImage(imageFile, maxWidth: 512, maxHeight: 512);
      
      // Upload compressed image
      final uploadTask = imageRef.putData(
        compressedImage,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalName': path.basename(imageFile.path),
            'uploadedAt': DateTime.now().toIso8601String(),
            'compressed': 'true',
          },
        ),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Delete images
  static Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final imageUrl in imageUrls) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  // Delete damage report images
  static Future<void> deleteDamageReportImages({
    required String reportId,
    required String ownerId,
  }) async {
    try {
      final reportRef = _damageReportsRef.child(ownerId).child(reportId);
      final result = await reportRef.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete damage report images: $e');
    }
  }

  // Delete estimate images
  static Future<void> deleteEstimateImages({
    required String estimateId,
    required String reportId,
  }) async {
    try {
      final estimateRef = _estimatesRef.child(reportId).child(estimateId);
      final result = await estimateRef.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete estimate images: $e');
    }
  }

  // Get image metadata
  static Future<Map<String, dynamic>?> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('Failed to get image metadata: $e');
      return null;
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    
    return validExtensions.contains(extension);
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is within limits
  static bool isFileSizeValid(File file, {double maxSizeMB = 10.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }
}
