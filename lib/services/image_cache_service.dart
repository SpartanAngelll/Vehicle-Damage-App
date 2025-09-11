import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  static const String _cachePrefix = 'image_cache_';
  static const String _cacheMetadataKey = 'image_cache_metadata';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB (reduced from 100MB)
  static const int _maxCacheAge = 3 * 24 * 60 * 60 * 1000; // 3 days in milliseconds (reduced from 7 days)
  static const int _maxConcurrentDownloads = 3; // Limit concurrent downloads
  
  static final Map<String, Future<File?>> _downloadTasks = {};

  // Get cache directory
  static Future<Directory> get _cacheDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Generate cache key from URL
  static String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${_cachePrefix}${digest.toString()}';
  }

  // Get cached image file
  static Future<File?> getCachedImage(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final cacheDir = await _cacheDirectory;
      final cachedFile = File('${cacheDir.path}/$cacheKey.jpg');
      
      if (await cachedFile.exists()) {
        // Check if file is not too old
        final stat = await cachedFile.stat();
        final age = DateTime.now().millisecondsSinceEpoch - stat.modified.millisecondsSinceEpoch;
        
        if (age < _maxCacheAge) {
          debugPrint('📱 [ImageCache] Found cached image: $url');
          return cachedFile;
        } else {
          // Remove old cached file
          await cachedFile.delete();
          await _removeFromMetadata(cacheKey);
          debugPrint('🗑️ [ImageCache] Removed expired cached image: $url');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [ImageCache] Error getting cached image: $e');
      return null;
    }
  }

  // Cache image from URL with deduplication
  static Future<File?> cacheImageFromUrl(String url, Uint8List imageData) async {
    try {
      final cacheKey = _generateCacheKey(url);
      
      // Check if already downloading
      if (_downloadTasks.containsKey(cacheKey)) {
        return await _downloadTasks[cacheKey];
      }
      
      // Create download task
      final downloadTask = _performCacheImageFromUrl(url, imageData, cacheKey);
      _downloadTasks[cacheKey] = downloadTask;
      
      try {
        final result = await downloadTask;
        return result;
      } finally {
        _downloadTasks.remove(cacheKey);
      }
    } catch (e) {
      debugPrint('❌ [ImageCache] Error caching image: $e');
      return null;
    }
  }
  
  // Internal method to perform the actual caching
  static Future<File?> _performCacheImageFromUrl(String url, Uint8List imageData, String cacheKey) async {
    try {
      final cacheDir = await _cacheDirectory;
      final cachedFile = File('${cacheDir.path}/$cacheKey.jpg');
      
      // Write image data to file
      await cachedFile.writeAsBytes(imageData);
      
      // Update metadata
      await _updateMetadata(cacheKey, url, imageData.length);
      
      // Clean up old cache if needed (async, don't wait)
      _cleanupCache();
      
      debugPrint('💾 [ImageCache] Cached image: $url');
      return cachedFile;
    } catch (e) {
      debugPrint('❌ [ImageCache] Error caching image: $e');
      return null;
    }
  }

  // Cache image from file
  static Future<File?> cacheImageFromFile(String url, File imageFile) async {
    try {
      final imageData = await imageFile.readAsBytes();
      return await cacheImageFromUrl(url, imageData);
    } catch (e) {
      debugPrint('❌ [ImageCache] Error caching image from file: $e');
      return null;
    }
  }

  // Remove cached image
  static Future<void> removeCachedImage(String url) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final cacheDir = await _cacheDirectory;
      final cachedFile = File('${cacheDir.path}/$cacheKey.jpg');
      
      if (await cachedFile.exists()) {
        await cachedFile.delete();
        await _removeFromMetadata(cacheKey);
        debugPrint('🗑️ [ImageCache] Removed cached image: $url');
      }
    } catch (e) {
      debugPrint('❌ [ImageCache] Error removing cached image: $e');
    }
  }

  // Clear all cached images
  static Future<void> clearAllCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheMetadataKey);
      
      debugPrint('🗑️ [ImageCache] Cleared all cached images');
    } catch (e) {
      debugPrint('❌ [ImageCache] Error clearing cache: $e');
    }
  }

  // Get cache size
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDirectory;
      int totalSize = 0;
      
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ [ImageCache] Error getting cache size: $e');
      return 0;
    }
  }

  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey);
      
      if (metadataJson != null) {
        final metadata = json.decode(metadataJson) as Map<String, dynamic>;
        final cacheSize = await getCacheSize();
        
        return {
          'totalSize': cacheSize,
          'totalSizeMB': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
          'imageCount': metadata.length,
          'maxSizeMB': (_maxCacheSize / (1024 * 1024)).toStringAsFixed(0),
        };
      }
      
      return {
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'imageCount': 0,
        'maxSizeMB': (_maxCacheSize / (1024 * 1024)).toStringAsFixed(0),
      };
    } catch (e) {
      debugPrint('❌ [ImageCache] Error getting cache info: $e');
      return {
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'imageCount': 0,
        'maxSizeMB': (_maxCacheSize / (1024 * 1024)).toStringAsFixed(0),
      };
    }
  }

  // Update metadata
  static Future<void> _updateMetadata(String cacheKey, String url, int size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey);
      
      Map<String, dynamic> metadata = {};
      if (metadataJson != null) {
        metadata = json.decode(metadataJson) as Map<String, dynamic>;
      }
      
      metadata[cacheKey] = {
        'url': url,
        'size': size,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_cacheMetadataKey, json.encode(metadata));
    } catch (e) {
      debugPrint('❌ [ImageCache] Error updating metadata: $e');
    }
  }

  // Remove from metadata
  static Future<void> _removeFromMetadata(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey);
      
      if (metadataJson != null) {
        final metadata = json.decode(metadataJson) as Map<String, dynamic>;
        metadata.remove(cacheKey);
        await prefs.setString(_cacheMetadataKey, json.encode(metadata));
      }
    } catch (e) {
      debugPrint('❌ [ImageCache] Error removing from metadata: $e');
    }
  }

  // Clean up old cache
  static Future<void> _cleanupCache() async {
    try {
      final cacheSize = await getCacheSize();
      if (cacheSize > _maxCacheSize) {
        debugPrint('🧹 [ImageCache] Cache size exceeded, cleaning up...');
        
        final prefs = await SharedPreferences.getInstance();
        final metadataJson = prefs.getString(_cacheMetadataKey);
        
        if (metadataJson != null) {
          final metadata = json.decode(metadataJson) as Map<String, dynamic>;
          final cacheDir = await _cacheDirectory;
          
          // Sort by cache time (oldest first)
          final sortedEntries = metadata.entries.toList()
            ..sort((a, b) => (a.value['cachedAt'] as int).compareTo(b.value['cachedAt'] as int));
          
          // Remove oldest entries until cache size is acceptable
          int currentSize = cacheSize;
          for (final entry in sortedEntries) {
            if (currentSize <= _maxCacheSize * 0.8) break; // Keep 80% of max size
            
            final cacheKey = entry.key;
            final cachedFile = File('${cacheDir.path}/$cacheKey.jpg');
            
            if (await cachedFile.exists()) {
              final fileSize = await cachedFile.length();
              await cachedFile.delete();
              currentSize -= fileSize;
              metadata.remove(cacheKey);
              debugPrint('🗑️ [ImageCache] Removed old cached image: ${entry.value['url']}');
            }
          }
          
          await prefs.setString(_cacheMetadataKey, json.encode(metadata));
        }
      }
    } catch (e) {
      debugPrint('❌ [ImageCache] Error cleaning up cache: $e');
    }
  }

  // Preload images for better performance
  static Future<void> preloadImages(List<String> urls) async {
    try {
      for (final url in urls) {
        final cachedFile = await getCachedImage(url);
        if (cachedFile == null) {
          // Image not cached, could trigger download here
          debugPrint('📥 [ImageCache] Image not cached, could preload: $url');
        }
      }
    } catch (e) {
      debugPrint('❌ [ImageCache] Error preloading images: $e');
    }
  }
}
