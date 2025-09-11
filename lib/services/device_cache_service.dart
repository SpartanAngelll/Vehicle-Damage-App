import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_request.dart';
import '../models/damage_report.dart';

class DeviceCacheService {
  static final DeviceCacheService _instance = DeviceCacheService._internal();
  factory DeviceCacheService() => _instance;
  DeviceCacheService._internal();

  static const String _serviceRequestsKey = 'cached_service_requests';
  static const String _estimatesKey = 'cached_estimates';
  static const String _cacheTimestampKey = 'cache_timestamps';
  static const Duration _cacheExpiry = Duration(hours: 24); // Cache for 24 hours

  // Service Request Cache Methods
  Future<void> cacheServiceRequest(JobRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRequests = await getCachedServiceRequests();
      
      // Convert request to map and handle DateTime serialization
      final requestMap = request.toMap();
      // Convert DateTime objects to ISO strings for JSON serialization
      final serializedMap = _serializeDateTimeFields(requestMap);
      
      // Add or update the request
      cachedRequests[request.id] = serializedMap;
      
      // Save to device
      final jsonString = json.encode(cachedRequests);
      await prefs.setString(_serviceRequestsKey, jsonString);
      
      // Update timestamp
      await _updateCacheTimestamp('service_request_${request.id}');
      
      print('🔍 [Cache] Cached service request: ${request.id}');
    } catch (e) {
      print('❌ [Cache] Error caching service request: $e');
    }
  }

  Future<JobRequest?> getCachedServiceRequest(String requestId) async {
    try {
      final cachedRequests = await getCachedServiceRequests();
      final requestData = cachedRequests[requestId];
      
      if (requestData != null) {
        // Check if cache is still valid
        if (await _isCacheValid('service_request_$requestId')) {
          print('🔍 [Cache] Retrieved service request from cache: $requestId');
          return JobRequest.fromMap(requestData, requestId);
        } else {
          // Cache expired, remove it
          await _removeCachedServiceRequest(requestId);
          print('⚠️ [Cache] Service request cache expired: $requestId');
        }
      }
      
      return null;
    } catch (e) {
      print('❌ [Cache] Error retrieving cached service request: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCachedServiceRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_serviceRequestsKey);
      
      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        return decoded;
      }
      
      return {};
    } catch (e) {
      print('❌ [Cache] Error getting cached service requests: $e');
      return {};
    }
  }

  Future<void> _removeCachedServiceRequest(String requestId) async {
    try {
      final cachedRequests = await getCachedServiceRequests();
      cachedRequests.remove(requestId);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(cachedRequests);
      await prefs.setString(_serviceRequestsKey, jsonString);
      
      // Remove timestamp
      await _removeCacheTimestamp('service_request_$requestId');
    } catch (e) {
      print('❌ [Cache] Error removing cached service request: $e');
    }
  }

  // Estimate Cache Methods
  Future<void> cacheEstimate(Estimate estimate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEstimates = await getCachedEstimates();
      
      // Convert estimate to map and handle DateTime serialization
      final estimateMap = estimate.toMap();
      // Convert DateTime objects to ISO strings for JSON serialization
      final serializedMap = _serializeDateTimeFields(estimateMap);
      
      // Add or update the estimate
      cachedEstimates[estimate.id] = serializedMap;
      
      // Save to device
      final jsonString = json.encode(cachedEstimates);
      await prefs.setString(_estimatesKey, jsonString);
      
      // Update timestamp
      await _updateCacheTimestamp('estimate_${estimate.id}');
      
      print('🔍 [Cache] Cached estimate: ${estimate.id}');
    } catch (e) {
      print('❌ [Cache] Error caching estimate: $e');
    }
  }

  Future<Estimate?> getCachedEstimate(String estimateId) async {
    try {
      final cachedEstimates = await getCachedEstimates();
      final estimateData = cachedEstimates[estimateId];
      
      if (estimateData != null) {
        // Check if cache is still valid
        if (await _isCacheValid('estimate_$estimateId')) {
          print('🔍 [Cache] Retrieved estimate from cache: $estimateId');
          return Estimate.fromMap(estimateData, estimateId);
        } else {
          // Cache expired, remove it
          await _removeCachedEstimate(estimateId);
          print('⚠️ [Cache] Estimate cache expired: $estimateId');
        }
      }
      
      return null;
    } catch (e) {
      print('❌ [Cache] Error retrieving cached estimate: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCachedEstimates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_estimatesKey);
      
      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        return decoded;
      }
      
      return {};
    } catch (e) {
      print('❌ [Cache] Error getting cached estimates: $e');
      return {};
    }
  }

  Future<void> _removeCachedEstimate(String estimateId) async {
    try {
      final cachedEstimates = await getCachedEstimates();
      cachedEstimates.remove(estimateId);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(cachedEstimates);
      await prefs.setString(_estimatesKey, jsonString);
      
      // Remove timestamp
      await _removeCacheTimestamp('estimate_$estimateId');
    } catch (e) {
      print('❌ [Cache] Error removing cached estimate: $e');
    }
  }

  // Cache Management Methods
  Future<void> _updateCacheTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamps = await _getCacheTimestamps();
      timestamps[key] = DateTime.now().millisecondsSinceEpoch;
      
      final jsonString = json.encode(timestamps);
      await prefs.setString(_cacheTimestampKey, jsonString);
    } catch (e) {
      print('❌ [Cache] Error updating cache timestamp: $e');
    }
  }

  Future<Map<String, int>> _getCacheTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheTimestampKey);
      
      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
      
      return {};
    } catch (e) {
      print('❌ [Cache] Error getting cache timestamps: $e');
      return {};
    }
  }

  Future<bool> _isCacheValid(String key) async {
    try {
      final timestamps = await _getCacheTimestamps();
      final timestamp = timestamps[key];
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      return now.difference(cacheTime) < _cacheExpiry;
    } catch (e) {
      print('❌ [Cache] Error checking cache validity: $e');
      return false;
    }
  }

  Future<void> _removeCacheTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamps = await _getCacheTimestamps();
      timestamps.remove(key);
      
      final jsonString = json.encode(timestamps);
      await prefs.setString(_cacheTimestampKey, jsonString);
    } catch (e) {
      print('❌ [Cache] Error removing cache timestamp: $e');
    }
  }

  // Utility Methods
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_serviceRequestsKey);
      await prefs.remove(_estimatesKey);
      await prefs.remove(_cacheTimestampKey);
      
      print('🔍 [Cache] Cleared all cache');
    } catch (e) {
      print('❌ [Cache] Error clearing cache: $e');
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      final timestamps = await _getCacheTimestamps();
      final now = DateTime.now();
      
      for (final entry in timestamps.entries) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(entry.value);
        if (now.difference(cacheTime) >= _cacheExpiry) {
          final key = entry.key;
          
          if (key.startsWith('service_request_')) {
            final requestId = key.replaceFirst('service_request_', '');
            await _removeCachedServiceRequest(requestId);
          } else if (key.startsWith('estimate_')) {
            final estimateId = key.replaceFirst('estimate_', '');
            await _removeCachedEstimate(estimateId);
          }
        }
      }
      
      print('🔍 [Cache] Cleared expired cache entries');
    } catch (e) {
      print('❌ [Cache] Error clearing expired cache: $e');
    }
  }

  Future<Map<String, int>> getCacheStats() async {
    try {
      final serviceRequests = await getCachedServiceRequests();
      final estimates = await getCachedEstimates();
      final timestamps = await _getCacheTimestamps();
      
      return {
        'service_requests': serviceRequests.length,
        'estimates': estimates.length,
        'total_entries': timestamps.length,
      };
    } catch (e) {
      print('❌ [Cache] Error getting cache stats: $e');
      return {};
    }
  }

  // Helper method to serialize DateTime fields for JSON encoding
  Map<String, dynamic> _serializeDateTimeFields(Map<String, dynamic> data) {
    final serialized = Map<String, dynamic>.from(data);
    
    // Convert DateTime objects to ISO strings
    for (final key in serialized.keys) {
      final value = serialized[key];
      if (value is DateTime) {
        serialized[key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        serialized[key] = _serializeDateTimeFields(value);
      }
    }
    
    return serialized;
  }
}
