import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCacheService {
  static const String _cachePrefix = 'firestore_cache_';
  static const int _defaultCacheExpiry = 5 * 60 * 1000; // 5 minutes in milliseconds
  static const int _userProfileCacheExpiry = 30 * 60 * 1000; // 30 minutes for user profiles
  static const int _serviceRequestsCacheExpiry = 2 * 60 * 1000; // 2 minutes for service requests
  
  // Helper function to convert Firestore data to JSON-serializable format
  static Map<String, dynamic> _makeSerializable(Map<String, dynamic> data) {
    final serializableData = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Timestamp) {
        // Convert Timestamp to milliseconds since epoch
        serializableData[key] = {
          '_timestamp': true,
          'milliseconds': value.millisecondsSinceEpoch,
        };
      } else if (value is Map<String, dynamic>) {
        // Recursively process nested maps
        serializableData[key] = _makeSerializable(value);
      } else if (value is List) {
        // Process lists that might contain Timestamps or Maps
        serializableData[key] = value.map((item) {
          if (item is Timestamp) {
            return {
              '_timestamp': true,
              'milliseconds': item.millisecondsSinceEpoch,
            };
          } else if (item is Map<String, dynamic>) {
            return _makeSerializable(item);
          }
          return item;
        }).toList();
      } else {
        // Keep other types as-is
        serializableData[key] = value;
      }
    }
    
    return serializableData;
  }
  
  // Helper function to convert serialized data back to Firestore format
  static Map<String, dynamic> _restoreFromSerializable(Map<String, dynamic> data) {
    final restoredData = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Map<String, dynamic> && value.containsKey('_timestamp')) {
        // Convert back to Timestamp
        restoredData[key] = Timestamp.fromMillisecondsSinceEpoch(value['milliseconds']);
      } else if (value is Map<String, dynamic>) {
        // Recursively process nested maps
        restoredData[key] = _restoreFromSerializable(value);
      } else if (value is List) {
        // Process lists that might contain serialized Timestamps or Maps
        restoredData[key] = value.map((item) {
          if (item is Map<String, dynamic> && item.containsKey('_timestamp')) {
            return Timestamp.fromMillisecondsSinceEpoch(item['milliseconds']);
          } else if (item is Map<String, dynamic>) {
            return _restoreFromSerializable(item);
          }
          return item;
        }).toList();
      } else {
        // Keep other types as-is
        restoredData[key] = value;
      }
    }
    
    return restoredData;
  }
  
  // Cache user profile data
  static Future<void> cacheUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}user_profile_$userId';
      final serializableData = _makeSerializable(profileData);
      final cacheData = {
        'data': serializableData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': _userProfileCacheExpiry,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('💾 [FirestoreCache] Cached user profile: $userId');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error caching user profile: $e');
    }
  }
  
  // Get cached user profile
  static Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}user_profile_$userId';
      final cacheDataString = prefs.getString(cacheKey);
      
      if (cacheDataString != null) {
        final cacheData = json.decode(cacheDataString) as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int;
        final expiry = cacheData['expiry'] as int;
        
        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          debugPrint('📱 [FirestoreCache] Found cached user profile: $userId');
          final serializedData = Map<String, dynamic>.from(cacheData['data']);
          return _restoreFromSerializable(serializedData);
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
          debugPrint('🗑️ [FirestoreCache] Removed expired user profile cache: $userId');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error getting cached user profile: $e');
      return null;
    }
  }
  
  // Cache service requests
  static Future<void> cacheServiceRequests(String userId, List<Map<String, dynamic>> requests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}service_requests_$userId';
      final cacheData = {
        'data': requests,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': _serviceRequestsCacheExpiry,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('💾 [FirestoreCache] Cached service requests: ${requests.length} requests');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error caching service requests: $e');
    }
  }
  
  // Get cached service requests
  static Future<List<Map<String, dynamic>>?> getCachedServiceRequests(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}service_requests_$userId';
      final cacheDataString = prefs.getString(cacheKey);
      
      if (cacheDataString != null) {
        final cacheData = json.decode(cacheDataString) as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int;
        final expiry = cacheData['expiry'] as int;
        
        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          debugPrint('📱 [FirestoreCache] Found cached service requests: $userId');
          final requests = cacheData['data'] as List;
          return requests.cast<Map<String, dynamic>>();
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
          debugPrint('🗑️ [FirestoreCache] Removed expired service requests cache: $userId');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error getting cached service requests: $e');
      return null;
    }
  }
  
  // Cache estimates
  static Future<void> cacheEstimates(String userId, List<Map<String, dynamic>> estimates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}estimates_$userId';
      final cacheData = {
        'data': estimates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': _defaultCacheExpiry,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('💾 [FirestoreCache] Cached estimates: ${estimates.length} estimates');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error caching estimates: $e');
    }
  }
  
  // Get cached estimates
  static Future<List<Map<String, dynamic>>?> getCachedEstimates(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}estimates_$userId';
      final cacheDataString = prefs.getString(cacheKey);
      
      if (cacheDataString != null) {
        final cacheData = json.decode(cacheDataString) as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int;
        final expiry = cacheData['expiry'] as int;
        
        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          debugPrint('📱 [FirestoreCache] Found cached estimates: $userId');
          final estimates = cacheData['data'] as List;
          return estimates.cast<Map<String, dynamic>>();
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
          debugPrint('🗑️ [FirestoreCache] Removed expired estimates cache: $userId');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error getting cached estimates: $e');
      return null;
    }
  }
  
  // Cache service professional profile
  static Future<void> cacheServiceProfessionalProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}service_professional_$userId';
      final serializableData = _makeSerializable(profileData);
      final cacheData = {
        'data': serializableData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': _userProfileCacheExpiry,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('💾 [FirestoreCache] Cached service professional profile: $userId');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error caching service professional profile: $e');
    }
  }
  
  // Get cached service professional profile
  static Future<Map<String, dynamic>?> getCachedServiceProfessionalProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}service_professional_$userId';
      final cacheDataString = prefs.getString(cacheKey);
      
      if (cacheDataString != null) {
        final cacheData = json.decode(cacheDataString) as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int;
        final expiry = cacheData['expiry'] as int;
        
        if (DateTime.now().millisecondsSinceEpoch - timestamp < expiry) {
          debugPrint('📱 [FirestoreCache] Found cached service professional profile: $userId');
          final serializedData = Map<String, dynamic>.from(cacheData['data']);
          return _restoreFromSerializable(serializedData);
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
          debugPrint('🗑️ [FirestoreCache] Removed expired service professional profile cache: $userId');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error getting cached service professional profile: $e');
      return null;
    }
  }
  
  // Invalidate cache for a specific user
  static Future<void> invalidateUserCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        '${_cachePrefix}user_profile_$userId',
        '${_cachePrefix}service_requests_$userId',
        '${_cachePrefix}estimates_$userId',
        '${_cachePrefix}service_professional_$userId',
      ];
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('🗑️ [FirestoreCache] Invalidated all cache for user: $userId');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error invalidating user cache: $e');
    }
  }
  
  // Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('🗑️ [FirestoreCache] Cleared all Firestore cache');
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error clearing all cache: $e');
    }
  }
  
  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cacheCount = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          cacheCount++;
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }
      
      return {
        'cacheCount': cacheCount,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('❌ [FirestoreCache] Error getting cache info: $e');
      return {
        'cacheCount': 0,
        'totalSize': 0,
        'totalSizeKB': '0.00',
      };
    }
  }
}
