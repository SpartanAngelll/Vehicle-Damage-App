import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_professional.dart';
import '../models/booking_models.dart';

class FirebaseFirestoreService {
  static final FirebaseFirestoreService _instance = FirebaseFirestoreService._internal();
  factory FirebaseFirestoreService() => _instance;
  FirebaseFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _serviceProfessionalsCollection => _firestore.collection('service_professionals');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _damageReportsCollection => _firestore.collection('damage_reports');
  CollectionReference get _estimatesCollection => _firestore.collection('estimates');
  CollectionReference get _usernamesCollection => _firestore.collection('usernames');

  /// Get user bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId, {String? userType}) async {
    try {
      String fieldName = userType == 'professional' ? 'professionalId' : 'customerId';
      
      final querySnapshot = await _bookingsCollection
          .where(fieldName, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting user bookings: $e');
      rethrow;
    }
  }

  /// Get service professional by ID
  Future<ServiceProfessional?> getServiceProfessional(String professionalId) async {
    try {
      print('🔍 [FirebaseFirestoreService] Getting service professional profile for ID: $professionalId');
      
      // First, try the service_professionals collection
      var doc = await _serviceProfessionalsCollection.doc(professionalId).get();
      print('🔍 [FirebaseFirestoreService] service_professionals collection - Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        // Try the users collection (in case the data is stored there with role field)
        print('🔍 [FirebaseFirestoreService] Trying users collection...');
        doc = await _usersCollection.doc(professionalId).get();
        print('🔍 [FirebaseFirestoreService] users collection - Document exists: ${doc.exists}');
        
        if (!doc.exists) {
          // Try the professionals collection (alternative naming)
          print('🔍 [FirebaseFirestoreService] Trying professionals collection...');
          doc = await _firestore.collection('professionals').doc(professionalId).get();
          print('🔍 [FirebaseFirestoreService] professionals collection - Document exists: ${doc.exists}');
        }
      }
      
      if (!doc.exists) {
        print('❌ [FirebaseFirestoreService] No document found for professional ID: $professionalId in any collection');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      print('🔍 [FirebaseFirestoreService] Document data: $data');
      
      // Check if this is a user document with role field
      if (data['role'] == 'service_professional') {
        print('🔍 [FirebaseFirestoreService] Found service professional in users collection');
        print('🔍 [FirebaseFirestoreService] User document fields: ${data.keys.toList()}');
        
        // Check if this is a complete service professional profile or just a basic user with role
        final hasServiceProfessionalFields = data.containsKey('categoryIds') || 
                                           data.containsKey('specializations') || 
                                           data.containsKey('businessName');
        
        if (!hasServiceProfessionalFields) {
          print('⚠️ [FirebaseFirestoreService] User has service_professional role but incomplete profile - missing service professional fields');
          print('⚠️ [FirebaseFirestoreService] This user needs to complete their service professional registration');
          return null; // Return null to trigger registration flow
        }
        
        final professional = ServiceProfessional.fromMap(data, doc.id);
        print('✅ [FirebaseFirestoreService] Service professional profile loaded successfully from users collection');
        return professional;
      } else {
        // Regular service professional document
        final professional = ServiceProfessional.fromMap(data, doc.id);
        print('✅ [FirebaseFirestoreService] Service professional profile loaded successfully');
        return professional;
      }
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting service professional: $e');
      return null;
    }
  }

  /// Update service professional
  Future<void> updateServiceProfessional(ServiceProfessional professional) async {
    try {
      print('🔍 [FirebaseFirestoreService] Updating service professional profile for user: ${professional.userId}');
      print('🔍 [FirebaseFirestoreService] Using document ID: ${professional.userId}');
      print('🔍 [FirebaseFirestoreService] Professional data: ${professional.toMap()}');
      
      // Update the service professional profile using the user ID as the document ID
      await _serviceProfessionalsCollection.doc(professional.userId).update(professional.toMap());
      print('✅ [FirebaseFirestoreService] Service professional profile updated successfully');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating service professional: $e');
      rethrow;
    }
  }

  /// Mark professional as on the way
  Future<void> markProfessionalOnWay(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': 'on_my_way',
        'onMyWayAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error marking professional on way: $e');
      rethrow;
    }
  }

  /// Mark job as started
  Future<void> markJobStarted(String bookingId, String pin) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': 'in_progress',
        'jobStartedAt': FieldValue.serverTimestamp(),
        'customerPin': pin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error marking job started: $e');
      rethrow;
    }
  }

  /// Mark job as completed
  Future<void> markJobCompleted(String bookingId, {String? notes}) async {
    try {
      final updateData = {
        'status': 'completed',
        'jobCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (notes != null) {
        updateData['statusNotes'] = notes;
      }

      await _bookingsCollection.doc(bookingId).update(updateData);
      
      // Update service professional's job completion count
      await _updateProfessionalJobStats(bookingId);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error marking job completed: $e');
      rethrow;
    }
  }

  /// Accept job as completed (customer action)
  Future<void> acceptJobAsCompleted(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': 'reviewed',
        'jobAcceptedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update service professional's job completion count
      await _updateProfessionalJobStats(bookingId);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error accepting job as completed: $e');
      rethrow;
    }
  }

  /// Save booking data
  Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    try {
      await _bookingsCollection.doc(bookingData['id']).set(bookingData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error saving booking: $e');
      rethrow;
    }
  }

  /// Check if a job has been completed
  Future<bool> isJobCompleted(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      
      return status == 'completed' || status == 'reviewed';
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error checking job completion: $e');
      return false;
    }
  }

  /// Check if a job has been reviewed (accepted as completed by customer)
  Future<bool> isJobReviewed(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      
      return status == 'reviewed';
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error checking job review status: $e');
      return false;
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting booking by ID: $e');
      return null;
    }
  }


  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting user profile: $e');
      return null;
    }
  }

  /// Create damage report
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
      final docRef = await _damageReportsCollection.add({
        'ownerId': ownerId,
        'vehicleMake': vehicleMake,
        'vehicleModel': vehicleModel,
        'vehicleYear': vehicleYear,
        'damageDescription': damageDescription,
        'estimatedCost': estimatedCost,
        'additionalNotes': additionalNotes,
        'imageUrls': imageUrls,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating damage report: $e');
      rethrow;
    }
  }

  /// Get damage report by ID
  Future<Map<String, dynamic>?> getDamageReport(String reportId) async {
    try {
      final doc = await _damageReportsCollection.doc(reportId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting damage report: $e');
      return null;
    }
  }

  /// Get user's damage reports
  Future<List<Map<String, dynamic>>> getDamageReportsForUser(String userId) async {
    try {
      final querySnapshot = await _damageReportsCollection
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting user damage reports: $e');
      return [];
    }
  }

  /// Get all pending damage reports
  Future<List<Map<String, dynamic>>> getAllPendingDamageReports() async {
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
      print('❌ [FirebaseFirestoreService] Error getting pending damage reports: $e');
      return [];
    }
  }

  /// Update damage report
  Future<void> updateDamageReport(String reportId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _damageReportsCollection.doc(reportId).update(updates);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating damage report: $e');
      rethrow;
    }
  }

  /// Update damage report status
  Future<void> updateDamageReportStatus(String reportId, String status) async {
    try {
      await _damageReportsCollection.doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating damage report status: $e');
      rethrow;
    }
  }

  /// Delete damage report
  Future<void> deleteDamageReport(String reportId) async {
    try {
      await _damageReportsCollection.doc(reportId).delete();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error deleting damage report: $e');
      rethrow;
    }
  }

  /// Create estimate
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
      });
      
      return docRef.id;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating estimate: $e');
      rethrow;
    }
  }

  /// Get estimates for report
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
      print('❌ [FirebaseFirestoreService] Error getting estimates for report: $e');
      return [];
    }
  }

  /// Get estimates for user
  Future<List<Map<String, dynamic>>> getEstimatesForUser(String userId) async {
    try {
      final querySnapshot = await _estimatesCollection
          .where('professionalId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting estimates for user: $e');
      return [];
    }
  }

  /// Update estimate status
  Future<void> updateEstimateStatus(String estimateId, String status, {Map<String, dynamic>? additionalData}) async {
    try {
      final updateData = <String, Object>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'accepted') {
        updateData['acceptedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'declined') {
        updateData['declinedAt'] = FieldValue.serverTimestamp();
      }

      if (additionalData != null) {
        // Filter out null values and ensure proper types for Firestore
        final filteredData = <String, Object>{};
        additionalData.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              filteredData[key] = Timestamp.fromDate(value);
            } else {
              filteredData[key] = value as Object;
            }
          }
        });
        updateData.addAll(filteredData);
      }

      await _estimatesCollection.doc(estimateId).update(updateData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating estimate status: $e');
      rethrow;
    }
  }

  /// Delete estimate
  Future<void> deleteEstimate(String estimateId) async {
    try {
      await _estimatesCollection.doc(estimateId).delete();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error deleting estimate: $e');
      rethrow;
    }
  }

  /// Search damage reports
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

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error searching damage reports: $e');
      return [];
    }
  }

  /// Get damage reports stream
  Stream<QuerySnapshot> getDamageReportsStream(String ownerId) {
    return _damageReportsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get available jobs stream
  Stream<QuerySnapshot> getAvailableJobsStream() {
    return _damageReportsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get estimates stream
  Stream<QuerySnapshot> getEstimatesStream(String professionalId) {
    return _estimatesCollection
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  /// Get job request by ID
  Future<Map<String, dynamic>?> getJobRequest(String jobRequestId) async {
    try {
      final doc = await _firestore.collection('job_requests').doc(jobRequestId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting job request: $e');
      return null;
    }
  }

  /// Get estimate by ID
  Future<Map<String, dynamic>?> getEstimate(String estimateId) async {
    try {
      final doc = await _estimatesCollection.doc(estimateId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting estimate: $e');
      return null;
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting booking: $e');
      return null;
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String status, {Map<String, dynamic>? additionalData}) async {
    try {
      final updateData = <String, Object>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        // Filter out null values and ensure proper types for Firestore
        final filteredData = <String, Object>{};
        additionalData.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              filteredData[key] = Timestamp.fromDate(value);
            } else {
              filteredData[key] = value as Object;
            }
          }
        });
        updateData.addAll(filteredData);
      }

      await _bookingsCollection.doc(bookingId).update(updateData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating booking status: $e');
      rethrow;
    }
  }

  /// Get all estimates for professional
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
      print('❌ [FirebaseFirestoreService] Error getting all estimates for professional: $e');
      return [];
    }
  }

  /// Get job requests by categories
  Future<List<Map<String, dynamic>>> getJobRequestsByCategories(List<String> categoryIds) async {
    try {
      final querySnapshot = await _firestore.collection('job_requests')
          .where('categoryIds', arrayContainsAny: categoryIds)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting job requests by categories: $e');
      return [];
    }
  }

  /// Create estimate for service request
  Future<String> createEstimateForServiceRequest({
    required String jobRequestId,
    required String professionalId,
    required String professionalEmail,
    String? professionalBio,
    required double cost,
    required int leadTimeDays,
    required String description,
    List<String> imageUrls = const [],
  }) async {
    try {
      // Get the job request to find the customer ID
      final jobRequestData = await getJobRequest(jobRequestId);
      if (jobRequestData == null) {
        throw Exception('Job request not found: $jobRequestId');
      }
      
      final customerId = jobRequestData['customerId'] as String?;
      if (customerId == null) {
        throw Exception('Job request missing customerId: $jobRequestId');
      }

      final docRef = await _estimatesCollection.add({
        'jobRequestId': jobRequestId,
        'ownerId': customerId, // Add ownerId so customers can see the estimate
        'professionalId': professionalId,
        'professionalEmail': professionalEmail,
        'professionalBio': professionalBio,
        'cost': cost,
        'leadTimeDays': leadTimeDays, // Store as minutes (new format)
        'description': description,
        'imageUrls': imageUrls,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating estimate for service request: $e');
      rethrow;
    }
  }

  /// Migrate estimates with owner ID
  Future<void> migrateEstimatesWithOwnerId() async {
    try {
      // This is a migration method - implementation depends on specific migration needs
      print('ℹ️ [FirebaseFirestoreService] Migration method called - no action needed');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error in migration: $e');
      rethrow;
    }
  }

  /// Get damage reports for owner (alias for getDamageReportsForUser)
  Future<List<Map<String, dynamic>>> getDamageReportsForOwner(String ownerId) async {
    return getDamageReportsForUser(ownerId);
  }

  /// Get all estimates for owner
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
      print('❌ [FirebaseFirestoreService] Error getting all estimates for owner: $e');
      return [];
    }
  }

  /// Create user profile
  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      await _usersCollection.doc(userData['id']).set(userData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating user profile: $e');
      rethrow;
    }
  }

  /// Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _usernamesCollection.doc(username.toLowerCase()).get();
      return doc.exists;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error checking username availability: $e');
      rethrow;
    }
  }

  /// Reserve username for a user
  Future<void> reserveUsername(String username, String userId) async {
    try {
      await _usernamesCollection.doc(username.toLowerCase()).set({
        'userId': userId,
        'username': username,
        'reservedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error reserving username: $e');
      rethrow;
    }
  }

  /// Release username reservation
  Future<void> releaseUsername(String username) async {
    try {
      await _usernamesCollection.doc(username.toLowerCase()).delete();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error releasing username: $e');
      rethrow;
    }
  }

  /// Update user profile with username and profile picture
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? fullName,
    String? profilePhotoUrl,
    String? bio,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (username != null) {
        updateData['username'] = username;
        // Reserve the new username
        await reserveUsername(username, userId);
      }
      
      if (fullName != null) {
        updateData['fullName'] = fullName;
      }
      
      if (profilePhotoUrl != null) {
        updateData['profilePhotoUrl'] = profilePhotoUrl;
      }
      
      if (bio != null) {
        updateData['bio'] = bio;
      }

      await _usersCollection.doc(userId).update(updateData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get job requests for customer
  Future<List<Map<String, dynamic>>> getJobRequestsForCustomer(String customerId) async {
    try {
      final querySnapshot = await _firestore.collection('job_requests')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting job requests for customer: $e');
      return [];
    }
  }

  /// Cancel job request
  Future<void> cancelJobRequest(String requestId) async {
    try {
      await _firestore.collection('job_requests').doc(requestId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error cancelling job request: $e');
      rethrow;
    }
  }

  /// Create job request
  Future<String> createJobRequest(Map<String, dynamic> requestData) async {
    try {
      // Ensure all required fields are present
      final now = DateTime.now();
      final completeRequestData = {
        ...requestData,
        'status': requestData['status'] ?? 'pending',
        'createdAt': requestData['createdAt'] ?? Timestamp.fromDate(now),
        'updatedAt': requestData['updatedAt'] ?? Timestamp.fromDate(now),
        'tags': requestData['tags'] ?? <String>[],
      };
      
      final docRef = await _firestore.collection('job_requests').add(completeRequestData);
      return docRef.id;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating job request: $e');
      rethrow;
    }
  }

  /// Create service professional profile
  Future<String> createServiceProfessionalProfile(ServiceProfessional professional) async {
    try {
      print('🔍 [FirebaseFirestoreService] Creating service professional profile for user: ${professional.userId}');
      print('🔍 [FirebaseFirestoreService] Professional data: ${professional.toMap()}');
      
      // Create the service professional profile using the user ID as the document ID
      await _serviceProfessionalsCollection.doc(professional.userId).set(professional.toMap());
      print('✅ [FirebaseFirestoreService] Service professional profile document created');
      
      // Update the user's role in the users collection
      await _usersCollection.doc(professional.userId).update({
        'role': 'service_professional',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [FirebaseFirestoreService] User role updated to service_professional');
      
      print('✅ [FirebaseFirestoreService] Service professional profile created and user role updated');
      return professional.userId;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error creating service professional profile: $e');
      print('❌ [FirebaseFirestoreService] Error details: ${e.toString()}');
      rethrow;
    }
  }

  /// Update estimate status with enum
  Future<void> updateEstimateStatusWithEnum(String estimateId, String status, {Map<String, dynamic>? additionalData}) async {
    return updateEstimateStatus(estimateId, status, additionalData: additionalData);
  }

  /// Update job request status
  Future<void> updateJobRequestStatus(String requestId, String status, {Map<String, dynamic>? additionalData}) async {
    try {
      final updateData = <String, Object>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        // Filter out null values and ensure proper types for Firestore
        final filteredData = <String, Object>{};
        additionalData.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              filteredData[key] = Timestamp.fromDate(value);
            } else {
              filteredData[key] = value as Object;
            }
          }
        });
        updateData.addAll(filteredData);
      }

      await _firestore.collection('job_requests').doc(requestId).update(updateData);
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating job request status: $e');
      rethrow;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [FirebaseFirestoreService] User role updated to: $role');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating user role: $e');
      rethrow;
    }
  }

  /// Get only the statistics data for a professional
  Future<Map<String, dynamic>?> getProfessionalStats(String professionalId) async {
    try {
      print('🔍 [FirebaseFirestoreService] Getting stats for professional: $professionalId');
      
      // First, try the service_professionals collection
      var doc = await _serviceProfessionalsCollection.doc(professionalId).get();
      print('🔍 [FirebaseFirestoreService] service_professionals collection - Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        // Try the users collection (in case the data is stored there with role field)
        print('🔍 [FirebaseFirestoreService] Trying users collection...');
        doc = await _usersCollection.doc(professionalId).get();
        print('🔍 [FirebaseFirestoreService] users collection - Document exists: ${doc.exists}');
        
        if (!doc.exists) {
          // Try the professionals collection (alternative naming)
          print('🔍 [FirebaseFirestoreService] Trying professionals collection...');
          doc = await _firestore.collection('professionals').doc(professionalId).get();
          print('🔍 [FirebaseFirestoreService] professionals collection - Document exists: ${doc.exists}');
        }
      }
      
      if (!doc.exists) {
        print('❌ [FirebaseFirestoreService] Professional document not found: $professionalId');
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      print('🔍 [FirebaseFirestoreService] Found document with fields: ${data.keys.toList()}');
      
      return {
        'jobsCompleted': data['jobsCompleted'] ?? 0,
        'averageRating': (data['averageRating'] as num?)?.toDouble() ?? 0.0,
        'totalReviews': data['totalReviews'] ?? 0,
      };
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting professional stats: $e');
      return null;
    }
  }

  /// Refresh service professional job statistics (public method)
  Future<void> refreshProfessionalJobStats(String professionalId) async {
    try {
      print('🔍 [FirebaseFirestoreService] Refreshing job stats for professional: $professionalId');
      
      // Count completed jobs for this professional
      final completedJobsQuery = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('status', isEqualTo: 'reviewed')
          .get();

      final completedJobsCount = completedJobsQuery.docs.length;
      print('🔍 [FirebaseFirestoreService] Found $completedJobsCount completed jobs');

      // Get rating statistics
      final reviewsQuery = await _firestore.collection('reviews')
          .where('professionalId', isEqualTo: professionalId)
          .get();

      double averageRating = 0.0;
      int totalReviews = reviewsQuery.docs.length;
      print('🔍 [FirebaseFirestoreService] Found $totalReviews reviews');

      if (totalReviews > 0) {
        double totalRating = 0.0;
        for (final reviewDoc in reviewsQuery.docs) {
          final reviewData = reviewDoc.data() as Map<String, dynamic>;
          final rating = (reviewData['rating'] as num).toDouble();
          totalRating += rating;
          print('🔍 [FirebaseFirestoreService] Review rating: $rating');
        }
        averageRating = totalRating / totalReviews;
        print('🔍 [FirebaseFirestoreService] Calculated average rating: ${averageRating.toStringAsFixed(1)}');
      }

      // Update professional statistics
      print('🔍 [FirebaseFirestoreService] Updating professional document with stats...');
      await _serviceProfessionalsCollection.doc(professionalId).update({
        'jobsCompleted': completedJobsCount,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [FirebaseFirestoreService] Refreshed professional stats - Jobs: $completedJobsCount, Rating: ${averageRating.toStringAsFixed(1)}, Reviews: $totalReviews');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error refreshing professional job stats: $e');
      rethrow;
    }
  }

  /// Update service professional job statistics
  Future<void> _updateProfessionalJobStats(String bookingId) async {
    try {
      // Get booking details
      final bookingDoc = await _bookingsCollection.doc(bookingId).get();
      if (!bookingDoc.exists) {
        print('❌ [FirebaseFirestoreService] Booking not found: $bookingId');
        return;
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final professionalId = bookingData['professionalId'] as String?;
      
      if (professionalId == null) {
        print('❌ [FirebaseFirestoreService] No professional ID found in booking: $bookingId');
        return;
      }

      // Get current professional data
      final professionalDoc = await _serviceProfessionalsCollection.doc(professionalId).get();
      if (!professionalDoc.exists) {
        print('❌ [FirebaseFirestoreService] Professional not found: $professionalId');
        return;
      }

      final professionalData = professionalDoc.data() as Map<String, dynamic>;
      
      // Count completed jobs for this professional
      final completedJobsQuery = await _bookingsCollection
          .where('professionalId', isEqualTo: professionalId)
          .where('status', isEqualTo: 'reviewed')
          .get();

      final completedJobsCount = completedJobsQuery.docs.length;

      // Get rating statistics
      final reviewsQuery = await _firestore.collection('reviews')
          .where('professionalId', isEqualTo: professionalId)
          .get();

      double averageRating = 0.0;
      int totalReviews = reviewsQuery.docs.length;

      if (totalReviews > 0) {
        double totalRating = 0.0;
        for (final reviewDoc in reviewsQuery.docs) {
          final reviewData = reviewDoc.data() as Map<String, dynamic>;
          totalRating += (reviewData['rating'] as num).toDouble();
        }
        averageRating = totalRating / totalReviews;
      }

      // Update professional statistics
      await _serviceProfessionalsCollection.doc(professionalId).update({
        'jobsCompleted': completedJobsCount,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [FirebaseFirestoreService] Updated professional stats - Jobs: $completedJobsCount, Rating: ${averageRating.toStringAsFixed(1)}, Reviews: $totalReviews');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating professional job stats: $e');
      // Don't rethrow to avoid breaking the main job completion flow
    }
  }

  /// Get professional balance from Firebase
  Future<Map<String, dynamic>?> getProfessionalBalance(String professionalId) async {
    try {
      final doc = await _firestore.collection('professional_balances').doc(professionalId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting professional balance: $e');
      return null;
    }
  }

  /// Update professional balance in Firebase
  Future<void> updateProfessionalBalance(String professionalId, Map<String, dynamic> balanceData) async {
    try {
      await _firestore.collection('professional_balances').doc(professionalId).set({
        ...balanceData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ [FirebaseFirestoreService] Updated professional balance: $professionalId');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating professional balance: $e');
      rethrow;
    }
  }

  /// Get all professional balances from Firebase
  Future<List<Map<String, dynamic>>> getAllProfessionalBalances() async {
    try {
      final querySnapshot = await _firestore.collection('professional_balances').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting all professional balances: $e');
      return [];
    }
  }

  /// Get payout history from Firebase
  Future<List<Map<String, dynamic>>> getPayoutHistory(String professionalId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('payouts')
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting payout history: $e');
      return [];
    }
  }

  /// Get payout by ID from Firebase
  Future<Map<String, dynamic>?> getPayoutById(String payoutId) async {
    try {
      final doc = await _firestore.collection('payouts').doc(payoutId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error getting payout by ID: $e');
      return null;
    }
  }

  /// Update payout status in Firebase
  Future<void> updatePayoutStatus(String payoutId, String status, {Map<String, dynamic>? additionalData}) async {
    try {
      final updateData = <String, Object>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'success' || status == 'failed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      if (additionalData != null) {
        // Filter out null values and ensure proper types for Firestore
        final filteredData = <String, Object>{};
        additionalData.forEach((key, value) {
          if (value != null) {
            if (value is DateTime) {
              filteredData[key] = Timestamp.fromDate(value);
            } else {
              filteredData[key] = value as Object;
            }
          }
        });
        updateData.addAll(filteredData);
      }

      await _firestore.collection('payouts').doc(payoutId).update(updateData);
      print('✅ [FirebaseFirestoreService] Updated payout status: $payoutId -> $status');
    } catch (e) {
      print('❌ [FirebaseFirestoreService] Error updating payout status: $e');
      rethrow;
    }
  }

  /// Get payout stream for real-time updates
  Stream<List<Map<String, dynamic>>> getPayoutsStream(String professionalId) {
    return _firestore
        .collection('payouts')
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  /// Get professional balance stream for real-time updates
  Stream<Map<String, dynamic>?> getProfessionalBalanceStream(String professionalId) {
    return _firestore
        .collection('professional_balances')
        .doc(professionalId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          final data = snapshot.data() as Map<String, dynamic>;
          data['id'] = snapshot.id;
          return data;
        });
  }
}
