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
  static Reference get _serviceRequestsRef => _storage.ref('service_requests');

  // Image compression and processing
  static Future<Uint8List> compressImage(File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Read image file
      final bytes = await imageFile.readAsBytes();
      return await compressImageBytes(bytes, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  // Compress image from bytes (works on both web and mobile)
  static Future<Uint8List> compressImageBytes(Uint8List imageBytes, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      
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

  // Upload image bytes directly (for web)
  static Future<String> uploadImageBytes({
    required Uint8List imageBytes,
    required String path,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      // Compress image bytes
      final compressedBytes = await compressImageBytes(
        imageBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      
      // Upload to Firebase Storage
      final imageRef = _storage.ref(path);
      final uploadTask = imageRef.putData(
        compressedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
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
      throw Exception('Failed to upload image: $e');
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

  // Upload service request images
  static Future<List<String>> uploadServiceRequestImages({
    required String requestId,
    required List<File> images,
    required String customerId,
  }) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final fileName = '${requestId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageRef = _serviceRequestsRef.child(customerId).child(requestId).child(fileName);
        
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
      throw Exception('Failed to upload service request images: $e');
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

  // Upload user profile image (mobile - File)
  static Future<String?> uploadUserProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Compress image before upload
      final compressedImage = await compressImage(imageFile, maxWidth: 512, maxHeight: 512);
      
      return await _uploadUserProfileImageBytes(
        userId: userId,
        imageBytes: compressedImage,
        originalName: path.basename(imageFile.path),
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload user profile image from bytes (web-compatible)
  static Future<String?> uploadUserProfileImageFromBytes({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    try {
      // Compress image before upload
      final compressedImage = await compressImageBytes(
        imageBytes,
        maxWidth: 512,
        maxHeight: 512,
        quality: 85,
      );
      
      return await _uploadUserProfileImageBytes(
        userId: userId,
        imageBytes: compressedImage,
        originalName: 'profile_image.jpg',
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Internal method to upload profile image bytes
  static Future<String?> _uploadUserProfileImageBytes({
    required String userId,
    required Uint8List imageBytes,
    required String originalName,
  }) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageRef = _userProfilesRef.child(userId).child(fileName);
      
      // Upload compressed image
      final uploadTask = imageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalName': originalName,
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
      throw Exception('Failed to upload profile image bytes: $e');
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

  // Upload cover photo for service professional (mobile - File)
  static Future<String?> uploadCoverPhoto({
    required String professionalId,
    required File imageFile,
  }) async {
    try {
      // Validate file size
      if (!isFileSizeValid(imageFile, maxSizeMB: 5.0)) {
        throw Exception('Cover photo file size must be less than 5MB');
      }

      // Compress image for cover photo (wider aspect ratio)
      final compressedBytes = await compressImage(
        imageFile,
        maxWidth: 1200,
        maxHeight: 400,
        quality: 85,
      );

      return await _uploadCoverPhotoBytes(
        professionalId: professionalId,
        imageBytes: compressedBytes,
      );
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      return null;
    }
  }

  // Upload cover photo from bytes (web-compatible)
  static Future<String?> uploadCoverPhotoFromBytes({
    required String professionalId,
    required Uint8List imageBytes,
  }) async {
    try {
      // Validate file size (approximate - 5MB limit)
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Cover photo file size must be less than 5MB');
      }

      // Compress image for cover photo (wider aspect ratio)
      final compressedBytes = await compressImageBytes(
        imageBytes,
        maxWidth: 1200,
        maxHeight: 400,
        quality: 85,
      );

      return await _uploadCoverPhotoBytes(
        professionalId: professionalId,
        imageBytes: compressedBytes,
      );
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      return null;
    }
  }

  // Internal method to upload cover photo bytes
  static Future<String?> _uploadCoverPhotoBytes({
    required String professionalId,
    required Uint8List imageBytes,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cover_photo_${professionalId}_$timestamp.jpg';
      final ref = _userProfilesRef.child('cover_photos').child(fileName);

      // Upload compressed image
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'professionalId': professionalId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'cover_photo',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Cover photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading cover photo bytes: $e');
      return null;
    }
  }

  // Upload work showcase image (mobile - File)
  static Future<String?> uploadWorkShowcaseImage({
    required String professionalId,
    required File imageFile,
  }) async {
    try {
      // Validate file size
      if (!isFileSizeValid(imageFile, maxSizeMB: 5.0)) {
        throw Exception('Work showcase image file size must be less than 5MB');
      }

      // Compress image for work showcase
      final compressedBytes = await compressImage(
        imageFile,
        maxWidth: 800,
        maxHeight: 600,
        quality: 80,
      );

      return await _uploadWorkShowcaseBytes(
        professionalId: professionalId,
        imageBytes: compressedBytes,
      );
    } catch (e) {
      debugPrint('Error uploading work showcase image: $e');
      return null;
    }
  }

  // Upload work showcase image from bytes (web-compatible)
  static Future<String?> uploadWorkShowcaseImageFromBytes({
    required String professionalId,
    required Uint8List imageBytes,
  }) async {
    try {
      // Validate file size (approximate - 5MB limit)
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Work showcase image file size must be less than 5MB');
      }

      // Compress image for work showcase
      final compressedBytes = await compressImageBytes(
        imageBytes,
        maxWidth: 800,
        maxHeight: 600,
        quality: 80,
      );

      return await _uploadWorkShowcaseBytes(
        professionalId: professionalId,
        imageBytes: compressedBytes,
      );
    } catch (e) {
      debugPrint('Error uploading work showcase image: $e');
      return null;
    }
  }

  // Internal method to upload work showcase bytes
  static Future<String?> _uploadWorkShowcaseBytes({
    required String professionalId,
    required Uint8List imageBytes,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'work_showcase_${professionalId}_$timestamp.jpg';
      final ref = _userProfilesRef.child('work_showcase').child(fileName);

      // Upload compressed image
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'professionalId': professionalId,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'work_showcase',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Work showcase image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading work showcase bytes: $e');
      return null;
    }
  }

  // Delete cover photo
  static Future<void> deleteCoverPhoto(String coverPhotoUrl) async {
    try {
      final ref = _storage.refFromURL(coverPhotoUrl);
      await ref.delete();
      debugPrint('Cover photo deleted successfully');
    } catch (e) {
      debugPrint('Error deleting cover photo: $e');
    }
  }

  // Delete work showcase image
  static Future<void> deleteWorkShowcaseImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('Work showcase image deleted successfully');
    } catch (e) {
      debugPrint('Error deleting work showcase image: $e');
    }
  }
}
