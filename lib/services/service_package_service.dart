import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_package.dart';

/// Service for managing service packages (pre-priced services)
/// Handles both PostgreSQL (via API) and Firestore synchronization
class ServicePackageService {
  static ServicePackageService? _instance;
  final String _baseUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ServicePackageService._()
      : _baseUrl = _getBaseUrl();

  static ServicePackageService get instance {
    _instance ??= ServicePackageService._();
    return _instance!;
  }

  static String _getBaseUrl() {
    // In production, this would be your actual backend URL
    if (!kDebugMode) {
      return 'https://your-backend-api.com/api'; // Production server
    }
    
    // For development, handle different platforms
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // Web development
    } else if (Platform.isAndroid) {
      // For Android: use 10.0.2.2 for emulator, actual IP for physical device
      final host = _isEmulator() ? '10.0.2.2' : '192.168.0.53';
      return 'http://$host:3000/api';
    } else if (Platform.isIOS) {
      // For iOS: use localhost for simulator, actual IP for physical device
      final host = _isSimulator() ? 'localhost' : '192.168.0.53';
      return 'http://$host:3000/api';
    } else {
      return 'http://localhost:3000/api'; // Desktop development
    }
  }

  static bool _isEmulator() {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = Platform.environment;
      return androidInfo.containsKey('ANDROID_EMULATOR') || 
             androidInfo['ANDROID_EMULATOR'] == '1';
    } catch (e) {
      // Fallback: check if running on common emulator host
      return false;
    }
  }

  static bool _isSimulator() {
    if (!Platform.isIOS) return false;
    try {
      // iOS simulators typically have specific environment variables
      return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
             Platform.environment.containsKey('SIMULATOR_ROOT');
    } catch (e) {
      return false;
    }
  }

  /// Get all service packages for a professional
  /// Fetches from PostgreSQL via API and syncs to Firestore
  Future<List<ServicePackage>> getServicePackages({
    required String professionalId,
    bool activeOnly = false,
  }) async {
    try {
      print('🔍 [ServicePackageService] Fetching service packages for: $professionalId');
      
      final queryParam = activeOnly ? '?active_only=true' : '';
      final response = await http.get(
        Uri.parse('$_baseUrl/professionals/$professionalId/service-packages$queryParam'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final packagesList = responseData['packages'] as List<dynamic>;
        
        final packages = packagesList
            .map((p) => ServicePackage.fromApiResponse(p as Map<String, dynamic>))
            .toList();
        
        // Sync to Firestore for real-time updates
        await _syncToFirestore(professionalId, packages);
        
        print('✅ [ServicePackageService] Fetched ${packages.length} service packages');
        return packages;
      } else {
        print('❌ [ServicePackageService] Failed to fetch service packages: ${response.statusCode}');
        // Try to get from Firestore as fallback
        return await _getFromFirestore(professionalId, activeOnly);
      }
    } catch (e) {
      print('❌ [ServicePackageService] Error fetching service packages: $e');
      // Try to get from Firestore as fallback
      return await _getFromFirestore(professionalId, activeOnly);
    }
  }

  /// Get a single service package by ID
  Future<ServicePackage?> getServicePackage(String packageId) async {
    try {
      print('🔍 [ServicePackageService] Fetching service package: $packageId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/service-packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ServicePackage.fromApiResponse(responseData);
      } else if (response.statusCode == 404) {
        print('⚠️ [ServicePackageService] Service package not found: $packageId');
        return null;
      } else {
        print('❌ [ServicePackageService] Failed to fetch service package: ${response.statusCode}');
        // Try Firestore as fallback
        return await _getFromFirestoreById(packageId);
      }
    } catch (e) {
      print('❌ [ServicePackageService] Error fetching service package: $e');
      // Try Firestore as fallback
      return await _getFromFirestoreById(packageId);
    }
  }

  /// Create a new service package
  Future<ServicePackage> createServicePackage({
    required String professionalId,
    required String name,
    String? description,
    required double price,
    String currency = 'JMD',
    required int durationMinutes,
    bool isStartingFrom = false,
    int sortOrder = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [ServicePackageService] Creating service package: $name');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/professionals/$professionalId/service-packages'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'currency': currency,
          'duration_minutes': durationMinutes,
          'is_starting_from': isStartingFrom,
          'sort_order': sortOrder,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final package = ServicePackage.fromApiResponse(responseData);
        
        // Sync to Firestore
        await _saveToFirestore(package);
        
        print('✅ [ServicePackageService] Created service package: ${package.id}');
        return package;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Failed to create service package');
      }
    } catch (e) {
      print('❌ [ServicePackageService] Error creating service package: $e');
      rethrow;
    }
  }

  /// Update an existing service package
  Future<ServicePackage> updateServicePackage(ServicePackage package) async {
    try {
      print('🔍 [ServicePackageService] Updating service package: ${package.id}');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/service-packages/${package.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(package.toApiRequest()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedPackage = ServicePackage.fromApiResponse(responseData);
        
        // Sync to Firestore
        await _saveToFirestore(updatedPackage);
        
        print('✅ [ServicePackageService] Updated service package: ${updatedPackage.id}');
        return updatedPackage;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Failed to update service package');
      }
    } catch (e) {
      print('❌ [ServicePackageService] Error updating service package: $e');
      rethrow;
    }
  }

  /// Delete a service package
  Future<void> deleteServicePackage(String packageId) async {
    try {
      print('🔍 [ServicePackageService] Deleting service package: $packageId');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/service-packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Remove from Firestore
        await _firestore.collection('service_packages').doc(packageId).delete();
        
        print('✅ [ServicePackageService] Deleted service package: $packageId');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Failed to delete service package');
      }
    } catch (e) {
      print('❌ [ServicePackageService] Error deleting service package: $e');
      rethrow;
    }
  }

  /// Sync packages to Firestore for real-time updates
  Future<void> _syncToFirestore(String professionalId, List<ServicePackage> packages) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection('service_packages');
      
      for (final package in packages) {
        final docRef = collection.doc(package.id);
        batch.set(docRef, package.toMap(), SetOptions(merge: true));
      }
      
      await batch.commit();
      print('✅ [ServicePackageService] Synced ${packages.length} packages to Firestore');
    } catch (e) {
      print('⚠️ [ServicePackageService] Failed to sync to Firestore: $e');
      // Don't throw - this is a background sync
    }
  }

  /// Save a single package to Firestore
  Future<void> _saveToFirestore(ServicePackage package) async {
    try {
      await _firestore
          .collection('service_packages')
          .doc(package.id)
          .set(package.toMap(), SetOptions(merge: true));
      print('✅ [ServicePackageService] Saved package to Firestore: ${package.id}');
    } catch (e) {
      print('⚠️ [ServicePackageService] Failed to save to Firestore: $e');
      // Don't throw - this is a background sync
    }
  }

  /// Get packages from Firestore (fallback)
  Future<List<ServicePackage>> _getFromFirestore(String professionalId, bool activeOnly) async {
    try {
      Query query = _firestore
          .collection('service_packages')
          .where('professionalId', isEqualTo: professionalId);
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      final snapshot = await query.orderBy('sortOrder').orderBy('createdAt', descending: true).get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            return ServicePackage.fromMap(data, doc.id);
          })
          .toList();
    } catch (e) {
      print('❌ [ServicePackageService] Error getting from Firestore: $e');
      return [];
    }
  }

  /// Get a single package from Firestore by ID (fallback)
  Future<ServicePackage?> _getFromFirestoreById(String packageId) async {
    try {
      final doc = await _firestore.collection('service_packages').doc(packageId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return ServicePackage.fromMap(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      print('❌ [ServicePackageService] Error getting from Firestore: $e');
      return null;
    }
  }

  /// Stream service packages from Firestore for real-time updates
  Stream<List<ServicePackage>> streamServicePackages({
    required String professionalId,
    bool activeOnly = false,
  }) {
    Query query = _firestore
        .collection('service_packages')
        .where('professionalId', isEqualTo: professionalId);
    
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    return query
        .orderBy('sortOrder')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) {
                throw Exception('Document data is null');
              }
              return ServicePackage.fromMap(data, doc.id);
            })
            .toList());
  }
}

