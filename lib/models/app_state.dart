import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'damage_report.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_firestore_service.dart';

class AppState extends ChangeNotifier {
  final List<DamageReport> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedReportIndex;
  bool _isUploading = false;

  // Getters
  List<DamageReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DamageReport? get selectedReport => _selectedReportIndex != null && _selectedReportIndex! < _reports.length 
      ? _reports[_selectedReportIndex!] 
      : null;
  int? get selectedReportIndex => _selectedReportIndex;
  bool get isUploading => _isUploading;

  AppState() {
    _loadReports();
  }

  Future<void> addReport({
    required String ownerId,
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String damageDescription,
    required File? image,
    required double estimatedCost,
    String? additionalNotes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create damage report in Firestore
      final reportId = await FirebaseFirestoreService().createDamageReport(
        ownerId: ownerId,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
        damageDescription: damageDescription,
        estimatedCost: estimatedCost,
        additionalNotes: additionalNotes,
      );

      // Create local DamageReport object with Firestore document ID
      final report = DamageReport(
        id: reportId, // Use the Firestore document ID
        ownerId: ownerId,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleYear: vehicleYear,
        damageDescription: damageDescription,
        imageUrls: const [], // Initialize with empty list
        estimatedCost: estimatedCost,
        additionalNotes: additionalNotes,
        status: 'pending',
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _reports.add(report);
      await _saveReportsMetadata();
      _notifyListeners();

      _selectedReportIndex = _reports.length - 1;
    } catch (e) {
      _setError('Failed to add damage report: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load damage reports from Firestore with correct IDs
  Future<void> loadDamageReportsFromFirestore(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final firestoreService = FirebaseFirestoreService();
      final reportsData = await firestoreService.getDamageReportsForOwner(userId);
      
      _reports.clear();
      for (final reportData in reportsData) {
        final report = DamageReport(
          id: reportData['id'] as String, // Use Firestore document ID
          ownerId: reportData['ownerId'] as String,
          vehicleMake: reportData['vehicleMake'] as String,
          vehicleModel: reportData['vehicleModel'] as String,
          vehicleYear: reportData['vehicleYear'] as int,
          damageDescription: reportData['damageDescription'] as String,
          imageUrls: List<String>.from(reportData['imageUrls'] ?? []),
          estimatedCost: (reportData['estimatedCost'] as num).toDouble(),
          additionalNotes: reportData['additionalNotes'] as String?,
          status: reportData['status'] as String? ?? 'pending',
          timestamp: (reportData['timestamp'] as Timestamp).toDate(),
          createdAt: (reportData['createdAt'] as Timestamp).toDate(),
          updatedAt: (reportData['updatedAt'] as Timestamp).toDate(),
        );
        _reports.add(report);
      }
      
      await _saveReportsMetadata();
      _notifyListeners();
    } catch (e) {
      _setError('Failed to load damage reports: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load all estimates for a specific owner (vehicle owner)
  Future<List<Estimate>> loadEstimatesForOwner(String ownerId) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getAllEstimatesForOwner(ownerId);
      
      final estimates = <Estimate>[];
      for (final estimateData in estimatesData) {
        final estimate = Estimate(
          id: estimateData['id'] as String,
          reportId: estimateData['reportId'] as String,
          ownerId: estimateData['ownerId'] as String,
          repairProfessionalId: estimateData['professionalId'] as String,
          repairProfessionalEmail: estimateData['professionalEmail'] as String,
          repairProfessionalBio: estimateData['professionalBio'] as String?,
          cost: (estimateData['cost'] as num).toDouble(),
          leadTimeDays: estimateData['leadTimeDays'] as int,
          description: estimateData['description'] as String,
          imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
          status: _parseEstimateStatus(estimateData['status'] as String),
          submittedAt: (estimateData['submittedAt'] as Timestamp).toDate(),
          updatedAt: estimateData['updatedAt'] != null 
              ? (estimateData['updatedAt'] as Timestamp).toDate() 
              : null,
          acceptedAt: estimateData['acceptedAt'] != null 
              ? (estimateData['acceptedAt'] as Timestamp).toDate() 
              : null,
          declinedAt: estimateData['declinedAt'] != null 
              ? (estimateData['declinedAt'] as Timestamp).toDate() 
              : null,
        );
        estimates.add(estimate);
      }
      
      return estimates;
    } catch (e) {
      _setError('Failed to load estimates for owner: ${e.toString()}');
      return [];
    }
  }

  // Load all estimates for a specific repair professional
  Future<List<Estimate>> loadEstimatesForProfessional(String professionalId) async {
    try {
      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getAllEstimatesForProfessional(professionalId);
      
      final estimates = <Estimate>[];
      for (final estimateData in estimatesData) {
        final estimate = Estimate(
          id: estimateData['id'] as String,
          reportId: estimateData['reportId'] as String,
          ownerId: estimateData['ownerId'] as String,
          repairProfessionalId: estimateData['professionalId'] as String,
          repairProfessionalEmail: estimateData['professionalEmail'] as String,
          repairProfessionalBio: estimateData['professionalBio'] as String?,
          cost: (estimateData['cost'] as num).toDouble(),
          leadTimeDays: estimateData['leadTimeDays'] as int,
          description: estimateData['description'] as String,
          imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
          status: _parseEstimateStatus(estimateData['status'] as String),
          submittedAt: (estimateData['submittedAt'] as Timestamp).toDate(),
          updatedAt: estimateData['updatedAt'] != null 
              ? (estimateData['updatedAt'] as Timestamp).toDate() 
              : null,
          acceptedAt: estimateData['acceptedAt'] != null 
              ? (estimateData['acceptedAt'] as Timestamp).toDate() 
              : null,
          declinedAt: estimateData['declinedAt'] != null 
              ? (estimateData['declinedAt'] as Timestamp).toDate() 
              : null,
        );
        estimates.add(estimate);
      }
      
      return estimates;
    } catch (e) {
      _setError('Failed to load estimates for professional: ${e.toString()}');
      return [];
    }
  }



  void removeReport(int index) {
    if (index >= 0 && index < _reports.length) {
      _reports.removeAt(index);
      _saveReportsMetadata();
      _notifyListeners();
      
      // Adjust selected index if needed
      if (_selectedReportIndex != null) {
        if (_selectedReportIndex! >= _reports.length) {
          _selectedReportIndex = _reports.isEmpty ? null : _reports.length - 1;
        } else if (_selectedReportIndex! > index) {
          _selectedReportIndex = _selectedReportIndex! - 1;
        }
      }
    }
  }

  void updateReportDescription(int index, String newDescription) {
    if (index >= 0 && index < _reports.length) {
      final report = _reports[index];
      final updatedReport = report.copyWith(description: newDescription);
      _reports[index] = updatedReport;
      _saveReportsMetadata();
      _notifyListeners();
    }
  }

  Future<void> addEstimate(int reportIndex, Estimate estimate) async {
    try {
      if (reportIndex >= 0 && reportIndex < _reports.length) {
        // Save to Firestore first to get the document ID
        final firestoreService = FirebaseFirestoreService();
        final firestoreId = await firestoreService.createEstimate(
          reportId: estimate.reportId,
          ownerId: estimate.ownerId,
          professionalId: estimate.repairProfessionalId,
          professionalEmail: estimate.repairProfessionalEmail,
          professionalBio: estimate.repairProfessionalBio,
          cost: estimate.cost,
          leadTimeDays: estimate.leadTimeDays,
          description: estimate.description,
          imageUrls: estimate.imageUrls,
        );
        
        // Create a new estimate with the Firestore document ID
        final estimateWithFirestoreId = estimate.copyWith(id: firestoreId);
        
        // Add estimate to local memory with the correct ID
        _reports[reportIndex].addEstimate(estimateWithFirestoreId);
        
        // Update local storage metadata
        await _saveReportsMetadata();
        _notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add estimate: ${e.toString()}');
    }
  }

  void removeEstimate(int reportIndex, int estimateIndex) {
    if (reportIndex >= 0 && estimateIndex >= 0 && reportIndex < _reports.length) {
      final report = _reports[reportIndex];
      if (estimateIndex < report.estimates.length) {
        report.removeEstimate(estimateIndex);
        _saveReportsMetadata();
        _notifyListeners();
      }
    }
  }

  void updateEstimate(int reportIndex, int estimateIndex, Estimate newEstimate) {
    if (reportIndex >= 0 && estimateIndex >= 0 && reportIndex < _reports.length) {
      final report = _reports[reportIndex];
      if (estimateIndex < report.estimates.length) {
        report.updateEstimate(estimateIndex, newEstimate);
        _saveReportsMetadata();
        _notifyListeners();
      }
    }
  }

  Future<void> updateEstimateStatus(int reportIndex, int estimateIndex, EstimateStatus newStatus) async {
    if (reportIndex >= 0 && estimateIndex >= 0 && reportIndex < _reports.length) {
      final report = _reports[reportIndex];
      if (estimateIndex < report.estimates.length) {
        final estimate = report.estimates[estimateIndex];
        
        // Update local estimate with new status and appropriate timestamps
        final now = DateTime.now();
        final updatedEstimate = estimate.copyWith(
          status: newStatus,
          updatedAt: now,
          acceptedAt: newStatus == EstimateStatus.accepted ? now : estimate.acceptedAt,
          declinedAt: newStatus == EstimateStatus.declined ? now : estimate.declinedAt,
        );
        
        // Update local state
        report.updateEstimate(estimateIndex, updatedEstimate);
        _saveReportsMetadata();
        _notifyListeners();
        
        // Update Firestore
        try {
          debugPrint('Updating estimate in Firestore...');
          debugPrint('Estimate ID: ${estimate.id}');
          debugPrint('New Status: ${newStatus.name}');
          debugPrint('Owner ID: ${estimate.ownerId}');
          debugPrint('Professional ID: ${estimate.repairProfessionalId}');
          
          final firestoreService = FirebaseFirestoreService();
          await firestoreService.updateEstimateStatus(
            estimateId: estimate.id,
            status: newStatus.name,
            acceptedAt: updatedEstimate.acceptedAt,
            declinedAt: updatedEstimate.declinedAt,
            cost: estimate.cost, // Include cost for accepted estimates
          );
        } catch (e) {
          // If Firestore update fails, revert local changes
          final revertedEstimate = estimate.copyWith(
            status: estimate.status,
            updatedAt: estimate.updatedAt,
            acceptedAt: estimate.acceptedAt,
            declinedAt: estimate.declinedAt,
          );
          report.updateEstimate(estimateIndex, revertedEstimate);
          _saveReportsMetadata();
          _notifyListeners();
          
          // Re-throw the error so the UI can handle it
          throw e;
        }
      }
    }
  }

  // Get estimates by status for a specific repair professional
  List<Estimate> getEstimatesByProfessionalAndStatus(String professionalId, EstimateStatus status) {
    final estimates = <Estimate>[];
    for (final report in _reports) {
      for (final estimate in report.estimates) {
        if (estimate.repairProfessionalId == professionalId && estimate.status == status) {
          estimates.add(estimate);
        }
      }
    }
    return estimates;
  }

  // Get all estimates for a specific repair professional
  List<Estimate> getAllEstimatesByProfessional(String professionalId) {
    final estimates = <Estimate>[];
    for (final report in _reports) {
      for (final estimate in report.estimates) {
        if (estimate.repairProfessionalId == professionalId) {
          estimates.add(estimate);
        }
      }
    }
    return estimates;
  }

  // Get damage reports that a professional hasn't submitted estimates for
  List<DamageReport> getAvailableJobsForProfessional(String professionalId) {
    return _reports.where((report) {
      // Check if this professional has already submitted an estimate for this report
      final hasSubmitted = report.estimates.any((estimate) => 
        estimate.repairProfessionalId == professionalId
      );
      return !hasSubmitted;
    }).toList();
  }

  void selectReport(int index) {
    if (index >= 0 && index < _reports.length) {
      _selectedReportIndex = index;
      _notifyListeners();
    }
  }

  void clearSelection() {
    _selectedReportIndex = null;
    _notifyListeners();
  }

  void setUploading(bool uploading) {
    _isUploading = uploading;
    _notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    _notifyListeners();
  }

  void clearAllReports() {
    _reports.clear();
    _selectedReportIndex = null;
    _saveReportsMetadata();
    _notifyListeners();
  }

  void reorderReports(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _reports.removeAt(oldIndex);
    _reports.insert(newIndex, item);
    _saveReportsMetadata();
    _notifyListeners();
  }

  List<DamageReport> searchReports(String query) {
    if (query.isEmpty) return reports;
    return reports.where((report) =>
      report.damageDescription.toLowerCase().contains(query.toLowerCase()) ||
      report.estimates.any((estimate) =>
        estimate.description.toLowerCase().contains(query.toLowerCase()) ||
        estimate.repairProfessionalEmail.toLowerCase().contains(query.toLowerCase())
      )
    ).toList();
  }

  List<DamageReport> getReportsWithEstimates() {
    return reports.where((report) => report.hasEstimates).toList();
  }

  List<DamageReport> getReportsWithoutEstimates() {
    return reports.where((report) => !report.hasEstimates).toList();
  }

  int get totalEstimates {
    return reports.fold(0, (sum, report) => sum + report.estimateCount);
  }

  double get averageEstimatesPerReport {
    if (reports.isEmpty) return 0.0;
    return totalEstimates / reports.length;
  }

  void _notifyListeners() {
    if (!_isLoading) {
      notifyListeners();
    }
  }

  // No cleanup needed for this class

  // Storage methods
  Future<void> _loadReports() async {
    try {
      await LocalStorageService.getDamageReportsMetadata();
      // Note: In a real app, you'd reconstruct the full reports from metadata
      // For now, we'll just load the metadata and create placeholder reports
      _notifyListeners();
    } catch (e) {
      _setError('Failed to load reports: ${e.toString()}');
    }
  }



  // Load all pending damage reports (for professionals)
  Future<void> loadPendingDamageReportsFromFirestore() async {
    try {
      _setLoading(true);
      _clearError();

      final firestoreService = FirebaseFirestoreService();
      final reportsData = await firestoreService.getAllPendingDamageReports();
      
      _reports.clear();
      for (final reportData in reportsData) {
        final report = DamageReport(
          ownerId: reportData['ownerId'] as String,
          vehicleMake: reportData['vehicleMake'] as String,
          vehicleModel: reportData['vehicleModel'] as String,
          vehicleYear: reportData['vehicleYear'] as int,
          damageDescription: reportData['damageDescription'] as String,
          imageUrls: List<String>.from(reportData['imageUrls'] ?? []),
          estimatedCost: (reportData['estimatedCost'] as num).toDouble(),
          additionalNotes: reportData['additionalNotes'] as String?,
          status: reportData['status'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(reportData['timestamp'] as int),
          createdAt: DateTime.fromMillisecondsSinceEpoch(reportData['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(reportData['updatedAt'] as int),
          image: null, // Images are stored as URLs in Firestore
        );
        _reports.add(report);
      }

      await _saveReportsMetadata();
      _notifyListeners();
    } catch (e) {
      _setError('Failed to load pending damage reports from Firestore: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Search damage reports in Firestore
  Future<void> searchDamageReportsInFirestore({
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
      _setLoading(true);
      _clearError();

      final firestoreService = FirebaseFirestoreService();
      final reportsData = await firestoreService.searchDamageReports(
        ownerId: ownerId,
        status: status,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        minYear: minYear,
        maxYear: maxYear,
        minCost: minCost,
        maxCost: maxCost,
      );
      
      _reports.clear();
      for (final reportData in reportsData) {
        final report = DamageReport(
          ownerId: reportData['ownerId'] as String,
          vehicleMake: reportData['vehicleMake'] as String,
          vehicleModel: reportData['vehicleModel'] as String,
          vehicleYear: reportData['vehicleYear'] as int,
          damageDescription: reportData['damageDescription'] as String,
          imageUrls: List<String>.from(reportData['imageUrls'] ?? []),
          estimatedCost: (reportData['estimatedCost'] as num).toDouble(),
          additionalNotes: reportData['additionalNotes'] as String?,
          status: reportData['status'] as String,
          timestamp: DateTime.fromMillisecondsSinceEpoch(reportData['timestamp'] as int),
          createdAt: DateTime.fromMillisecondsSinceEpoch(reportData['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(reportData['updatedAt'] as int),
          image: null, // Images are stored as URLs in Firestore
        );
        _reports.add(report);
      }

      await _saveReportsMetadata();
      _notifyListeners();
    } catch (e) {
      _setError('Failed to search damage reports in Firestore: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveReportsMetadata() async {
    try {
      final metadata = _reports.map((report) => {
        'id': report.id,
        'description': report.damageDescription,
        'timestamp': report.timestamp.millisecondsSinceEpoch,
        'estimateCount': report.estimateCount,
        'hasEstimates': report.hasEstimates,
      }).toList();
      
      await LocalStorageService.saveDamageReportsMetadata(metadata);
    } catch (e) {
      _setError('Failed to save reports metadata: ${e.toString()}');
    }
  }

  // Sync local data with Firestore
  Future<void> syncWithFirestore(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Load user's damage reports from Firestore
      await loadDamageReportsFromFirestore(userId);
      
      // Load any pending estimates for these reports
      for (final report in _reports) {
        if (report.hasEstimates) {
          // Load estimates from Firestore for this report
          // This would require additional methods in FirebaseFirestoreService
          // For now, we'll just mark that estimates exist
        }
      }
      
      _notifyListeners();
    } catch (e) {
      _setError('Failed to sync with Firestore: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load estimates for a specific damage report from Firestore
  Future<void> loadEstimatesForReport(String reportId) async {
    try {
      _setLoading(true);
      _clearError();

      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getEstimatesForReport(reportId);
      
      // Find the report and update its estimates
      final reportIndex = _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        final report = _reports[reportIndex];
        
        // Clear existing estimates
        report.clearEstimates();
        
        // Add estimates from Firestore
        for (final estimateData in estimatesData) {
          final estimate = Estimate(
            reportId: estimateData['reportId'] as String,
            ownerId: estimateData['ownerId'] as String,
            repairProfessionalId: estimateData['professionalId'] as String,
            repairProfessionalEmail: estimateData['professionalEmail'] as String,
            repairProfessionalBio: estimateData['professionalBio'] as String?,
            cost: (estimateData['cost'] as num).toDouble(),
            leadTimeDays: estimateData['leadTimeDays'] as int,
            description: estimateData['description'] as String,
            imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
            status: _parseEstimateStatus(estimateData['status'] as String),
            submittedAt: (estimateData['submittedAt'] as Timestamp).toDate(),
            updatedAt: (estimateData['updatedAt'] as Timestamp).toDate(),
            acceptedAt: estimateData['acceptedAt'] != null 
                ? (estimateData['acceptedAt'] as Timestamp).toDate() 
                : null,
            declinedAt: estimateData['declinedAt'] != null 
                ? (estimateData['declinedAt'] as Timestamp).toDate() 
                : null,
          );
          report.addEstimate(estimate);
        }
        
        _reports[reportIndex] = report;
        await _saveReportsMetadata();
        _notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load estimates for report: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to parse estimate status string to enum
  EstimateStatus _parseEstimateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EstimateStatus.pending;
      case 'accepted':
        return EstimateStatus.accepted;
      case 'declined':
        return EstimateStatus.declined;
      default:
        return EstimateStatus.pending;
    }
  }

  // Update damage report status in Firestore
  Future<void> updateDamageReportStatusInFirestore(String reportId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateDamageReportStatus(reportId, status);
      
      // Update local report status
      final reportIndex = _reports.indexWhere((report) => report.id == reportId);
      if (reportIndex != -1) {
        _reports[reportIndex] = _reports[reportIndex].copyWith(status: status);
        await _saveReportsMetadata();
        _notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update damage report status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update estimate status in Firestore
  Future<void> updateEstimateStatusInFirestore(String estimateId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateEstimateStatus(estimateId: estimateId, status: status);
      
      // Update local estimate status
      for (final report in _reports) {
        final estimateIndex = report.estimates.indexWhere((estimate) => estimate.id == estimateId);
        if (estimateIndex != -1) {
          final estimate = report.estimates[estimateIndex];
          final updatedEstimate = estimate.copyWith(status: _parseEstimateStatus(status));
          report.updateEstimate(estimateIndex, updatedEstimate);
          await _saveReportsMetadata();
          _notifyListeners();
          break;
        }
      }
    } catch (e) {
      _setError('Failed to update estimate status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}
