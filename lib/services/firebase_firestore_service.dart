import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _damageReportsCollection = FirebaseFirestore.instance.collection('damage_reports');
  final CollectionReference _estimatesCollection = FirebaseFirestore.instance.collection('estimates');

  // Test Firestore connection
  Future<bool> testFirestoreConnection() async {
    try {
      debugPrint('Testing Firestore connection...');
      
      // Simple connectivity test - just check if we can access Firestore
      await _firestore.runTransaction((transaction) async {
        // This just tests basic connectivity without requiring specific permissions
        return true;
      });
      
      debugPrint('Firestore basic connectivity test passed');
      
      // Try to read from existing collections to test permissions
      try {
        final testDoc = await _usersCollection.limit(1).get();
        debugPrint('Firestore read test successful - can access users collection');
      } catch (e) {
        debugPrint('Users collection access failed: $e');
      }
      
      try {
        final reportsTest = await _damageReportsCollection.limit(1).get();
        debugPrint('Firestore read test successful - can access damage_reports collection');
      } catch (e) {
        debugPrint('Damage reports collection access failed: $e');
      }
      
      try {
        final estimatesTest = await _estimatesCollection.limit(1).get();
        debugPrint('Firestore read test successful - can access estimates collection');
      } catch (e) {
        debugPrint('Estimates collection access failed: $e');
      }
      
      debugPrint('Firestore connection test completed');
      return true;
    } catch (e) {
      debugPrint('Firestore connection test failed: $e');
      return false;
    }
  }

  // Test Firestore write permissions (optional)
  Future<bool> testFirestoreWritePermissions() async {
    try {
      debugPrint('Testing Firestore write permissions...');
      
      // Try to create a test user profile (this should work if user is authenticated)
      final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      await _usersCollection.doc(testUserId).set({
        'email': 'test@example.com',
        'role': 'test',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Firestore write test successful - created test user profile');
      
      // Clean up the test document
      await _usersCollection.doc(testUserId).delete();
      debugPrint('Firestore cleanup successful - deleted test user profile');
      
      return true;
    } catch (e) {
      debugPrint('Firestore write permissions test failed: $e');
      return false;
    }
  }

  // User operations
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String role,
    String? phone,
    String? bio,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        'email': email,
        'role': role,
        'phone': phone,
        'bio': bio,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Damage report operations
  Future<String> createDamageReport({
    required String ownerId,
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String damageDescription,
    required double estimatedCost,
    String? additionalNotes,
    List<String> imageUrls = const [],
  }) async {
    try {
      debugPrint('Creating damage report in Firestore: ownerId=$ownerId, vehicle=$vehicleYear $vehicleMake $vehicleModel');
      
      final docRef = await _damageReportsCollection.add({
        'ownerId': ownerId,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleYear': vehicleYear,
        'damageDescription': damageDescription,
        'imageUrls': imageUrls,
        'estimatedCost': estimatedCost,
        'additionalNotes': additionalNotes,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Damage report created successfully in Firestore with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Failed to create damage report in Firestore: $e');
      throw Exception('Failed to create damage report: ${e.toString()}');
    }
  }

  Future<void> updateDamageReport(String reportId, Map<String, dynamic> updates) async {
    try {
      debugPrint('Updating damage report in Firestore: reportId=$reportId');
      
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _damageReportsCollection.doc(reportId).update(updates);
      
      debugPrint('Damage report updated successfully: $reportId');
    } catch (e) {
      debugPrint('Failed to update damage report in Firestore: $e');
      throw Exception('Failed to update damage report: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getDamageReportsForOwner(String ownerId) async {
    try {
      final querySnapshot = await _damageReportsCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get damage reports: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableJobsForProfessional() async {
    try {
      final querySnapshot = await _damageReportsCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get available jobs: ${e.toString()}');
    }
  }

  // Estimate operations
  Future<String> createEstimate({
    required String reportId,
    required String ownerId,
    required String professionalId,
    required String professionalEmail,
    String? professionalBio,
    required double cost,
    required int leadTimeDays,
    required String description,
    List<String> imageUrls = const [],
  }) async {
    try {
      debugPrint('Creating estimate in Firestore: reportId=$reportId, professionalId=$professionalId');
      
      final docRef = await _estimatesCollection.add({
        'reportId': reportId,
        'ownerId': ownerId,
        'professionalId': professionalId,
        'professionalEmail': professionalEmail,
        'professionalBio': professionalBio,
        'cost': cost,
        'leadTimeDays': leadTimeDays,
        'description': description,
        'imageUrls': imageUrls,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'declinedAt': null,
      });
      
      debugPrint('Estimate created successfully in Firestore with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Failed to create estimate in Firestore: $e');
      throw Exception('Failed to create estimate: ${e.toString()}');
    }
  }

  Future<void> updateEstimateStatus({
    required String estimateId,
    required String status,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    double? cost,
  }) async {
    try {
      debugPrint('Attempting to update estimate status...');
      debugPrint('Estimate ID: $estimateId');
      debugPrint('New Status: $status');
      debugPrint('Cost: $cost');
      
      // First, let's read the current estimate to verify permissions
      final estimateDoc = await _estimatesCollection.doc(estimateId).get();
      if (!estimateDoc.exists) {
        throw Exception('Estimate not found: $estimateId');
      }
      
      final estimateData = estimateDoc.data() as Map<String, dynamic>;
      debugPrint('Current estimate data: $estimateData');
      debugPrint('Owner ID: ${estimateData['ownerId']}');
      debugPrint('Professional ID: ${estimateData['professionalId']}');
      
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (status == 'accepted') {
        updates['acceptedAt'] = acceptedAt != null 
            ? Timestamp.fromDate(acceptedAt)
            : FieldValue.serverTimestamp();
        // Include the cost at which the estimate was accepted
        if (cost != null) {
          updates['acceptedCost'] = cost;
        }
      } else if (status == 'declined') {
        updates['declinedAt'] = declinedAt != null 
            ? Timestamp.fromDate(declinedAt)
            : FieldValue.serverTimestamp();
        // Include the cost at which the estimate was declined
        if (cost != null) {
          updates['declinedCost'] = cost;
        }
      }
      
      debugPrint('Updates to apply: $updates');
      await _estimatesCollection.doc(estimateId).update(updates);
      debugPrint('Estimate status updated successfully: $status for estimate $estimateId');
    } catch (e) {
      debugPrint('Failed to update estimate status: $e');
      throw Exception('Failed to update estimate status: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getEstimatesForReport(String reportId) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('reportId', isEqualTo: reportId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get estimates for report: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getEstimatesForUser(String userId) async {
    try {
      final ownerEstimates = await _estimatesCollection
          .where('ownerId', isEqualTo: userId)
          .get();
      
      final professionalEstimates = await _estimatesCollection
          .where('professionalId', isEqualTo: userId)
          .get();
      
      final allEstimates = <Map<String, dynamic>>[];
      
      // Add owner estimates
      for (var doc in ownerEstimates.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allEstimates.add({
          'id': doc.id,
          ...data,
        });
      }
      
      // Add professional estimates
      for (var doc in professionalEstimates.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allEstimates.add({
          'id': doc.id,
          ...data,
        });
      }
      
      // Sort by submittedAt descending
      allEstimates.sort((a, b) {
        final aTime = a['submittedAt'] as Timestamp;
        final bTime = b['submittedAt'] as Timestamp;
        return bTime.compareTo(aTime);
      });
      
      return allEstimates;
    } catch (e) {
      throw Exception('Failed to get estimates for user: ${e.toString()}');
    }
  }

  // Real-time listeners
  Stream<QuerySnapshot> getDamageReportsStream(String ownerId) {
    return _damageReportsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAvailableJobsStream() {
    return _damageReportsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getEstimatesStream(String professionalId) {
    return _estimatesCollection
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Additional methods for the new functionality
  Future<Map<String, dynamic>?> getDamageReport(String reportId) async {
    try {
      debugPrint('Fetching damage report from Firestore: reportId=$reportId');
      
      final doc = await _damageReportsCollection.doc(reportId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        debugPrint('Damage report fetched successfully: ${doc.id}');
        return data;
      } else {
        debugPrint('Damage report not found: $reportId');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to fetch damage report from Firestore: $e');
      throw Exception('Failed to fetch damage report: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getDamageReportsForUser(String userId) async {
    try {
      debugPrint('Fetching damage reports for user: userId=$userId');
      
      final querySnapshot = await _damageReportsCollection
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final reports = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      debugPrint('Fetched ${reports.length} damage reports for user: $userId');
      return reports;
    } catch (e) {
      debugPrint('Failed to fetch damage reports for user: $e');
      throw Exception('Failed to fetch damage reports: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllPendingDamageReports() async {
    try {
      debugPrint('Fetching all pending damage reports from Firestore');
      
      final querySnapshot = await _damageReportsCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      
      final reports = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      debugPrint('Fetched ${reports.length} pending damage reports');
      return reports;
    } catch (e) {
      debugPrint('Failed to fetch pending damage reports: $e');
      throw Exception('Failed to fetch pending damage reports: ${e.toString()}');
    }
  }

  Future<void> updateDamageReportStatus(String reportId, String status) async {
    try {
      debugPrint('Updating damage report status in Firestore: reportId=$reportId, status=$status');
      
      await _damageReportsCollection.doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Damage report status updated successfully: $reportId -> $status');
    } catch (e) {
      debugPrint('Failed to update damage report status in Firestore: $e');
      throw Exception('Failed to update damage report status: ${e.toString()}');
    }
  }

  Future<void> deleteDamageReport(String reportId) async {
    try {
      debugPrint('Deleting damage report from Firestore: reportId=$reportId');
      
      await _damageReportsCollection.doc(reportId).delete();
      
      debugPrint('Damage report deleted successfully: $reportId');
    } catch (e) {
      debugPrint('Failed to delete damage report from Firestore: $e');
      throw Exception('Failed to delete damage report: ${e.toString()}');
    }
  }

  // Batch operations for multiple damage reports
  Future<void> saveMultipleDamageReports(List<Map<String, dynamic>> reports) async {
    try {
      debugPrint('Saving ${reports.length} damage reports to Firestore in batch');
      
      final batch = _firestore.batch();
      
      for (final report in reports) {
        final docRef = _damageReportsCollection.doc();
        batch.set(docRef, {
          ...report,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Successfully saved ${reports.length} damage reports to Firestore');
    } catch (e) {
      debugPrint('Failed to save multiple damage reports to Firestore: $e');
      throw Exception('Failed to save multiple damage reports: ${e.toString()}');
    }
  }

  // Search damage reports by criteria
  Future<List<Map<String, dynamic>>> searchDamageReports({
    String? ownerId,
    String? status,
    String? vehicleMake,
    String? vehicleModel,
    int? minYear,
    int? maxYear,
    double? minCost,
    double? maxCost,
  }) async {
    try {
      debugPrint('Searching damage reports with criteria: ownerId=$ownerId, status=$status, vehicleMake=$vehicleMake');
      
      Query query = _damageReportsCollection;
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (vehicleMake != null) {
        query = query.where('vehicleMake', isEqualTo: vehicleMake);
      }
      if (vehicleModel != null) {
        query = query.where('vehicleModel', isEqualTo: vehicleModel);
      }
      if (minYear != null) {
        query = query.where('vehicleYear', isGreaterThanOrEqualTo: minYear);
      }
      if (maxYear != null) {
        query = query.where('vehicleYear', isLessThanOrEqualTo: maxYear);
      }
      if (minCost != null) {
        query = query.where('estimatedCost', isGreaterThanOrEqualTo: minCost);
      }
      if (maxCost != null) {
        query = query.where('estimatedCost', isLessThanOrEqualTo: maxCost);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      final reports = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      debugPrint('Search returned ${reports.length} damage reports');
      return reports;
    } catch (e) {
      debugPrint('Failed to search damage reports: $e');
      throw Exception('Failed to search damage reports: ${e.toString()}');
    }
  }



  // Delete estimate
  Future<void> deleteEstimate(String estimateId) async {
    try {
      debugPrint('Deleting estimate from Firestore: estimateId=$estimateId');
      
      await _estimatesCollection.doc(estimateId).delete();
      
      debugPrint('Estimate deleted successfully: $estimateId');
    } catch (e) {
      debugPrint('Failed to delete estimate from Firestore: $e');
      throw Exception('Failed to delete estimate: ${e.toString()}');
    }
  }

  // Get estimates by status for a specific repair professional
  Future<List<Map<String, dynamic>>> getEstimatesByProfessionalAndStatus(String professionalId, String status) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get estimates by status: ${e.toString()}');
    }
  }

  // Get all estimates for a specific repair professional
  Future<List<Map<String, dynamic>>> getAllEstimatesForProfessional(String professionalId) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all estimates for professional: ${e.toString()}');
    }
  }

  // Get all estimates for a specific owner (vehicle owner)
  Future<List<Map<String, dynamic>>> getAllEstimatesForOwner(String ownerId) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all estimates for owner: ${e.toString()}');
    }
  }

  // Get estimates by status for a specific owner
  Future<List<Map<String, dynamic>>> getEstimatesByStatusForOwner(String ownerId, String status) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get estimates by status for owner: ${e.toString()}');
    }
  }
}
