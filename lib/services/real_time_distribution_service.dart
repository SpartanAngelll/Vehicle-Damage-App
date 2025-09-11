import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/damage_report.dart';
import '../models/user_state.dart';
import 'simple_notification_service.dart';
import 'firebase_firestore_service.dart';

class RealTimeDistributionService {
  static final RealTimeDistributionService _instance = RealTimeDistributionService._internal();
  factory RealTimeDistributionService() => _instance;
  RealTimeDistributionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SimpleNotificationService _notificationService = SimpleNotificationService();
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _damageReportsStream;
  StreamSubscription<QuerySnapshot>? _estimatesStream;
  
  // Offline queue for when connectivity is lost
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _isOnline = true;

  // Track which professionals have been notified for each report
  final Map<String, Set<String>> _notifiedProfessionals = {};
  
  // Track which professionals have submitted estimates for each report
  final Map<String, Set<String>> _estimateSubmittedProfessionals = {};

  /// Initialize the real-time distribution system
  Future<void> initialize() async {
    // Initialize notification service
    await _notificationService.initialize();
    
    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _onConnectivityChanged(results.first);
      }
    });
    
    // Start listening for new damage reports
    _startDamageReportsListener();
    
    // Start listening for estimate updates
    _startEstimatesListener();
    
    // Process offline queue if we're back online
    if (_isOnline) {
      await _processOfflineQueue();
    }
  }

  /// Start listening for new damage reports
  void _startDamageReportsListener() {
    _damageReportsStream = _firestore
        .collection('damage_reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(_onDamageReportsChanged);
  }

  /// Start listening for estimate updates
  void _startEstimatesListener() {
    _estimatesStream = _firestore
        .collection('estimates')
        .snapshots()
        .listen(_onEstimatesChanged);
  }

  /// Handle damage reports changes
  void _onDamageReportsChanged(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        _handleNewDamageReport(change.doc);
      } else if (change.type == DocumentChangeType.modified) {
        _handleDamageReportUpdate(change.doc);
      }
    }
  }

  /// Handle estimates changes
  void _onEstimatesChanged(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        _handleNewEstimate(change.doc);
      } else if (change.type == DocumentChangeType.modified) {
        _handleEstimateUpdate(change.doc);
      }
    }
  }

  /// Handle new damage report
  Future<void> _handleNewDamageReport(DocumentSnapshot doc) async {
    if (!_isOnline) {
      _addToOfflineQueue('new_damage_report', doc.data() as Map<String, dynamic>);
      return;
    }

    try {
      final damageReport = doc.data() as Map<String, dynamic>;
      final reportId = doc.id;
      
      // Check if estimate already accepted
      final hasAcceptedEstimate = await _checkIfEstimateAccepted(reportId);
      
      if (!hasAcceptedEstimate) {
        // Get eligible repair professionals
        final eligibleProfessionals = await _getEligibleProfessionals(reportId);
        
        // Send notifications to eligible professionals
        await _notifyProfessionalsForReport(reportId, eligibleProfessionals, damageReport);
        
        // Track notified professionals
        _notifiedProfessionals[reportId] = eligibleProfessionals.toSet();
      }
    } catch (e) {
      print('Error handling new damage report: $e');
    }
  }

  /// Handle damage report update
  Future<void> _handleDamageReportUpdate(DocumentSnapshot doc) async {
    if (!_isOnline) {
      _addToOfflineQueue('damage_report_update', doc.data() as Map<String, dynamic>);
      return;
    }

    try {
      final damageReport = doc.data() as Map<String, dynamic>;
      final reportId = doc.id;
      final status = damageReport['status'] as String?;
      
      // If report is completed or cancelled, stop sending notifications
      if (status == 'completed' || status == 'cancelled') {
        _notifiedProfessionals.remove(reportId);
        _estimateSubmittedProfessionals.remove(reportId);
      }
    } catch (e) {
      print('Error handling damage report update: $e');
    }
  }

  /// Handle new estimate
  Future<void> _handleNewEstimate(DocumentSnapshot doc) async {
    if (!_isOnline) {
      _addToOfflineQueue('new_estimate', doc.data() as Map<String, dynamic>);
      return;
    }

    try {
      final estimate = doc.data() as Map<String, dynamic>;
      final reportId = estimate['reportId'] as String?;
      final professionalId = estimate['professionalId'] as String?;
      
      if (reportId != null && professionalId != null) {
        // Track that this professional has submitted an estimate
        _estimateSubmittedProfessionals.putIfAbsent(reportId, () => {}).add(professionalId);
        
        // Notify the vehicle owner about the new estimate
        await _notifyOwnerAboutNewEstimate(reportId, estimate);
        
        // Check if we should stop sending notifications for this report
        await _checkIfShouldStopNotifications(reportId);
      }
    } catch (e) {
      print('Error handling new estimate: $e');
    }
  }

  /// Handle estimate update
  Future<void> _handleEstimateUpdate(DocumentSnapshot doc) async {
    if (!_isOnline) {
      _addToOfflineQueue('estimate_update', doc.data() as Map<String, dynamic>);
      return;
    }

    try {
      final estimate = doc.data() as Map<String, dynamic>;
      final reportId = estimate['reportId'] as String?;
      final status = estimate['status'] as String?;
      
      if (reportId != null) {
        if (status == 'accepted') {
          // Estimate accepted, stop all notifications for this report
          await _stopNotificationsForReport(reportId);
          
          // Notify the accepted professional
          final professionalId = estimate['professionalId'] as String?;
          if (professionalId != null) {
            await _notificationService.sendNotificationToUser(
              userId: professionalId,
              title: 'Estimate Accepted! 🎉',
              body: 'Your estimate has been accepted by the vehicle owner.',
              channelId: 'estimate_updates',
              data: {
                'type': 'estimate_accepted',
                'reportId': reportId,
                'estimateId': doc.id,
              },
            );
          }

          // Notify the owner about the acceptance
          await _notifyOwnerAboutEstimateStatus(reportId, estimate, 'accepted');
        } else if (status == 'declined') {
          // Notify the owner about the decline
          await _notifyOwnerAboutEstimateStatus(reportId, estimate, 'declined');
        }
      }
    } catch (e) {
      print('Error handling estimate update: $e');
    }
  }

  /// Check if an estimate has been accepted for a report
  Future<bool> _checkIfEstimateAccepted(String reportId) async {
    try {
      final estimatesSnapshot = await _firestore
          .collection('estimates')
          .where('reportId', isEqualTo: reportId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();
      
      return estimatesSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if estimate accepted: $e');
      return false;
    }
  }

  /// Get eligible repair professionals for a damage report
  Future<List<String>> _getEligibleProfessionals(String reportId) async {
    try {
      // Get all repair professionals
      final professionalsSnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['repairman', 'mechanic', 'serviceProfessional'])
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final eligibleProfessionals = <String>[];
      
      for (final doc in professionalsSnapshot.docs) {
        final professionalId = doc.id;
        
        // Check if already notified
        if (_notifiedProfessionals[reportId]?.contains(professionalId) == true) {
          continue;
        }
        
        // Check if already submitted estimate
        if (_estimateSubmittedProfessionals[reportId]?.contains(professionalId) == true) {
          continue;
        }
        
        eligibleProfessionals.add(professionalId);
      }
      
      return eligibleProfessionals;
    } catch (e) {
      print('Error getting eligible professionals: $e');
      return [];
    }
  }

  /// Notify professionals about a new damage report
  Future<void> _notifyProfessionalsForReport(
    String reportId,
    List<String> professionalIds,
    Map<String, dynamic> damageReport,
  ) async {
    if (professionalIds.isEmpty) return;

    final vehicleInfo = '${damageReport['vehicleYear']} ${damageReport['vehicleMake']} ${damageReport['vehicleModel']}';
    final description = damageReport['damageDescription'] as String? ?? 'No description provided';
    
    // Send notifications to all eligible professionals
    await _notificationService.sendNotificationToUsers(
      userIds: professionalIds,
      title: 'New Damage Report Available 🚗',
      body: '$vehicleInfo - $description',
      channelId: 'damage_reports',
      data: {
        'type': 'new_damage_report',
        'reportId': reportId,
        'vehicleInfo': vehicleInfo,
        'description': description,
        'estimatedCost': damageReport['estimatedCost'],
        'timestamp': damageReport['createdAt']?.toDate().millisecondsSinceEpoch,
      },
    );

    // Send estimate request prompts
    await _sendEstimateRequestPrompts(reportId, professionalIds, vehicleInfo);
  }

  /// Send estimate request prompts to professionals
  Future<void> _sendEstimateRequestPrompts(
    String reportId,
    List<String> professionalIds,
    String vehicleInfo,
  ) async {
    for (final professionalId in professionalIds) {
      await _notificationService.sendNotificationToUser(
        userId: professionalId,
        title: 'Submit Estimate Request 📋',
        body: 'Please submit an estimate for: $vehicleInfo',
        channelId: 'estimate_requests',
        data: {
          'type': 'estimate_request',
          'reportId': reportId,
          'vehicleInfo': vehicleInfo,
          'action': 'submit_estimate',
        },
      );
    }
  }

  /// Notify vehicle owner about a new estimate
  Future<void> _notifyOwnerAboutNewEstimate(String reportId, Map<String, dynamic> estimate) async {
    try {
      // Get the damage report to find the owner
      final reportDoc = await _firestore.collection('damage_reports').doc(reportId).get();
      if (!reportDoc.exists) {
        print('Damage report $reportId not found');
        return;
      }

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final ownerId = reportData['ownerId'] as String?;
      
      if (ownerId == null) {
        print('Owner ID not found in damage report $reportId');
        return;
      }

      // Get professional details
      final professionalDoc = await _firestore.collection('users').doc(estimate['professionalId']).get();
      final professionalData = professionalDoc.data() as Map<String, dynamic>?;
      final professionalName = professionalData?['name'] ?? professionalData?['email'] ?? 'Professional';

      // Get vehicle info
      final vehicleInfo = '${reportData['vehicleYear']} ${reportData['vehicleMake']} ${reportData['vehicleModel']}';
      final cost = estimate['cost']?.toString() ?? 'N/A';
      final leadTime = estimate['leadTimeDays']?.toString() ?? 'N/A';

      // Send notification to owner
      await _notificationService.sendNotificationToUser(
        userId: ownerId,
        title: 'New Estimate Received! 📋',
        body: '$professionalName submitted an estimate for your $vehicleInfo',
        channelId: 'estimate_updates',
        data: {
          'type': 'new_estimate',
          'reportId': reportId,
          'estimateId': estimate['id'] ?? estimate['professionalId'],
          'professionalId': estimate['professionalId'],
          'professionalName': professionalName,
          'vehicleInfo': vehicleInfo,
          'cost': cost,
          'leadTime': leadTime,
          'action': 'review_estimate',
        },
      );

      print('Notified owner $ownerId about new estimate from $professionalName');
    } catch (e) {
      print('Failed to notify owner about new estimate: $e');
    }
  }

  /// Notify vehicle owner about estimate status change
  Future<void> _notifyOwnerAboutEstimateStatus(String reportId, Map<String, dynamic> estimate, String status) async {
    try {
      // Get the damage report to find the owner
      final reportDoc = await _firestore.collection('damage_reports').doc(reportId).get();
      if (!reportDoc.exists) {
        print('Damage report $reportId not found');
        return;
      }

      final reportData = reportDoc.data() as Map<String, dynamic>;
      final ownerId = reportData['ownerId'] as String?;
      
      if (ownerId == null) {
        print('Owner ID not found in damage report $reportId');
        return;
      }

      // Get professional details
      final professionalDoc = await _firestore.collection('users').doc(estimate['professionalId']).get();
      final professionalData = professionalDoc.data() as Map<String, dynamic>?;
      final professionalName = professionalData?['name'] ?? professionalData?['email'] ?? 'Professional';

      // Get vehicle info
      final vehicleInfo = '${reportData['vehicleYear']} ${reportData['vehicleMake']} ${reportData['vehicleModel']}';

      String title, body;
      if (status == 'accepted') {
        title = 'Estimate Accepted! ✅';
        body = 'You accepted the estimate from $professionalName for your $vehicleInfo';
      } else {
        title = 'Estimate Declined ❌';
        body = 'You declined the estimate from $professionalName for your $vehicleInfo';
      }

      // Send notification to owner
      await _notificationService.sendNotificationToUser(
        userId: ownerId,
        title: title,
        body: body,
        channelId: 'estimate_updates',
        data: {
          'type': 'estimate_${status}',
          'reportId': reportId,
          'estimateId': estimate['id'] ?? estimate['professionalId'],
          'professionalId': estimate['professionalId'],
          'professionalName': professionalName,
          'vehicleInfo': vehicleInfo,
          'status': status,
        },
      );

      print('Notified owner $ownerId about estimate $status from $professionalName');
    } catch (e) {
      print('Failed to notify owner about estimate status: $e');
    }
  }

  /// Check if we should stop sending notifications for a report
  Future<void> _checkIfShouldStopNotifications(String reportId) async {
    try {
      // Check if estimate accepted
      final hasAcceptedEstimate = await _checkIfEstimateAccepted(reportId);
      
      if (hasAcceptedEstimate) {
        await _stopNotificationsForReport(reportId);
      }
    } catch (e) {
      print('Error checking if should stop notifications: $e');
    }
  }

  /// Stop all notifications for a specific report
  Future<void> _stopNotificationsForReport(String reportId) async {
    // Clear tracking data
    _notifiedProfessionals.remove(reportId);
    _estimateSubmittedProfessionals.remove(reportId);
    
    // Optionally send a notification to all professionals that this report is no longer available
    final professionals = await _getAllProfessionalsForReport(reportId);
    
    for (final professionalId in professionals) {
      await _notificationService.sendNotificationToUser(
        userId: professionalId,
        title: 'Report No Longer Available',
        body: 'This damage report has been assigned to another professional.',
        channelId: 'estimate_updates',
        data: {
          'type': 'report_assigned',
          'reportId': reportId,
        },
      );
    }
  }

  /// Get all professionals who were notified about a report
  Future<List<String>> _getAllProfessionalsForReport(String reportId) async {
    final notified = _notifiedProfessionals[reportId] ?? {};
    final submitted = _estimateSubmittedProfessionals[reportId] ?? {};
    
    return {...notified, ...submitted}.toList();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    
    if (_isOnline) {
      _processOfflineQueue();
    }
  }

  /// Add action to offline queue
  void _addToOfflineQueue(String action, Map<String, dynamic> data) {
    _offlineQueue.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    print('Added to offline queue: $action');
  }

  /// Process offline queue when back online
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    print('Processing offline queue with ${_offlineQueue.length} items');
    
    final queueCopy = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();
    
    for (final item in queueCopy) {
      try {
        final action = item['action'] as String;
        final data = item['data'] as Map<String, dynamic>;
        
        switch (action) {
          case 'new_damage_report':
            await _handleNewDamageReport(_createDocumentSnapshot(data));
            break;
          case 'damage_report_update':
            await _handleDamageReportUpdate(_createDocumentSnapshot(data));
            break;
          case 'new_estimate':
            await _handleNewEstimate(_createDocumentSnapshot(data));
            break;
          case 'estimate_update':
            await _handleEstimateUpdate(_createDocumentSnapshot(data));
            break;
        }
      } catch (e) {
        print('Error processing offline queue item: $e');
        // Re-add failed items to queue
        _offlineQueue.add(item);
      }
    }
  }

  /// Create a mock document snapshot for offline queue processing
  DocumentSnapshot _createDocumentSnapshot(Map<String, dynamic> data) {
    // This is a simplified approach - in production you might want to handle this differently
    return MockDocumentSnapshot(data);
  }

  /// Manually trigger distribution for a specific report
  Future<void> manuallyDistributeReport(String reportId) async {
    try {
      final reportDoc = await _firestore.collection('damage_reports').doc(reportId).get();
      if (reportDoc.exists) {
        await _handleNewDamageReport(reportDoc);
      }
    } catch (e) {
      print('Error manually distributing report: $e');
    }
  }



  /// Get distribution status for a report
  Map<String, dynamic> getDistributionStatus(String reportId) {
    final notified = _notifiedProfessionals[reportId] ?? {};
    final submitted = _estimateSubmittedProfessionals[reportId] ?? {};
    
    return {
      'reportId': reportId,
      'professionalsNotified': notified.length,
      'estimatesSubmitted': submitted.length,
      'isActive': notified.isNotEmpty && submitted.isEmpty,
    };
  }

  /// Get all estimates for a specific damage report
  Future<List<Map<String, dynamic>>> getEstimatesForReport(String reportId) async {
    try {
      final estimatesSnapshot = await _firestore
          .collection('estimates')
          .where('reportId', isEqualTo: reportId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      final estimates = <Map<String, dynamic>>[];
      for (final doc in estimatesSnapshot.docs) {
        final estimateData = doc.data();
        estimateData['id'] = doc.id;
        estimates.add(estimateData);
      }
      
      return estimates;
    } catch (e) {
      print('Failed to get estimates for report $reportId: $e');
      return [];
    }
  }

  /// Get all estimates for a specific owner
  Future<List<Map<String, dynamic>>> getEstimatesForOwner(String ownerId) async {
    try {
      print('🔍 GETTING ESTIMATES FOR OWNER: $ownerId');
      
      // First try to get estimates directly by ownerId (more efficient)
      try {
        final directEstimates = await getEstimatesByOwnerId(ownerId);
        if (directEstimates.isNotEmpty) {
          print('✅ Found ${directEstimates.length} estimates directly by ownerId');
          return directEstimates;
        }
      } catch (e) {
        print('⚠️ Direct ownerId query failed, falling back to report-based query: $e');
      }
      
      // Fall back to the old method if direct query fails or returns no results
      print('📋 Falling back to report-based estimate retrieval');
      
      // First get all damage reports by this owner
      final reportsSnapshot = await _firestore
          .collection('damage_reports')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      final reportIds = reportsSnapshot.docs.map((doc) => doc.id).toList();
      print('📋 Found ${reportIds.length} damage reports for owner $ownerId');
      
      if (reportIds.isEmpty) {
        print('ℹ️ No damage reports found for owner $ownerId');
        return [];
      }
      
      // Then get all estimates for these reports
      final estimatesSnapshot = await _firestore
          .collection('estimates')
          .where('reportId', whereIn: reportIds)
          .orderBy('submittedAt', descending: true)
          .get();
      
      final estimates = <Map<String, dynamic>>[];
      for (final doc in estimatesSnapshot.docs) {
        final estimateData = doc.data();
        estimateData['id'] = doc.id;
        estimates.add(estimateData);
        
        // Log each estimate found
        final reportId = estimateData['reportId'] as String?;
        final professionalId = estimateData['professionalId'] as String?;
        final status = estimateData['status'] as String?;
        print('   📊 Estimate: ${doc.id}, Report: $reportId, Professional: $professionalId, Status: $status');
      }
      
      print('✅ Found ${estimates.length} estimates for owner $ownerId via report-based query');
      return estimates;
    } catch (e) {
      print('❌ Failed to get estimates for owner $ownerId: $e');
      return [];
    }
  }

  /// Get estimates directly by owner ID (more efficient)
  Future<List<Map<String, dynamic>>> getEstimatesByOwnerId(String ownerId) async {
    try {
      print('🔍 GETTING ESTIMATES BY OWNER ID: $ownerId');
      
      // Query estimates collection directly by ownerId
      final estimatesSnapshot = await _firestore
          .collection('estimates')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      final estimates = <Map<String, dynamic>>[];
      for (final doc in estimatesSnapshot.docs) {
        final estimateData = doc.data();
        estimateData['id'] = doc.id;
        estimates.add(estimateData);
        
        // Log each estimate found
        final reportId = estimateData['reportId'] as String?;
        final professionalId = estimateData['professionalId'] as String?;
        final status = estimateData['status'] as String?;
        print('   📊 Direct Estimate: ${doc.id}, Report: $reportId, Professional: $professionalId, Status: $status');
      }
      
      print('✅ Found ${estimates.length} estimates directly for owner $ownerId');
      return estimates;
    } catch (e) {
      print('❌ Failed to get estimates by owner ID $ownerId: $e');
      return [];
    }
  }

  /// Manually notify about an estimate (for testing purposes)
  Future<void> manuallyNotifyAboutEstimate(String reportId, String estimateId) async {
    try {
      print('🔔 MANUAL NOTIFICATION - Report ID: $reportId, Estimate ID: $estimateId');
      
      final estimateDoc = await _firestore.collection('estimates').doc(estimateId).get();
      if (!estimateDoc.exists) {
        print('❌ Estimate $estimateId not found');
        return;
      }

      final estimate = estimateDoc.data() as Map<String, dynamic>;
      final ownerId = estimate['ownerId'] as String?;
      
      if (ownerId == null) {
        print('❌ Owner ID not found in estimate $estimateId');
        return;
      }
      
      print('📋 Found estimate for owner: $ownerId');
      await _notifyOwnerAboutNewEstimate(reportId, estimate);
      print('✅ Manual notification sent for estimate $estimateId to owner $ownerId');
    } catch (e) {
      print('❌ Failed to manually notify about estimate: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _damageReportsStream?.cancel();
    _estimatesStream?.cancel();
  }
}

// Mock document snapshot for offline queue processing
class MockDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  
  MockDocumentSnapshot(this._data);
  
  @override
  Map<String, dynamic> data() => _data;
  
  @override
  String get id => _data['id'] ?? '';
  
  @override
  bool get exists => true;
  
  // Implement other required methods with default values
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  
  // Required DocumentSnapshot methods
  @override
  DocumentReference get reference => throw UnimplementedError();
  
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  
  @override
  bool get hasPendingWrites => false;
  
  @override
  bool get isFromCache => false;
}
