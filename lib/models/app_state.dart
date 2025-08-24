import 'dart:io';
import 'package:flutter/foundation.dart';
import 'damage_report.dart';
import '../services/storage_service.dart';

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

  Future<void> addReport(File image, {String? description}) async {
    try {
      _setLoading(true);
      _clearError();

      final report = DamageReport(
        image: image,
        description: description ?? '',
        timestamp: DateTime.now(),
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
        _reports[reportIndex].addEstimate(estimate);
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

  void updateEstimateStatus(int reportIndex, int estimateIndex, EstimateStatus newStatus) {
    if (reportIndex >= 0 && estimateIndex >= 0 && reportIndex < _reports.length) {
      final report = _reports[reportIndex];
      if (estimateIndex < report.estimates.length) {
        final estimate = report.estimates[estimateIndex];
        final updatedEstimate = estimate.copyWith(status: newStatus);
        report.updateEstimate(estimateIndex, updatedEstimate);
        _saveReportsMetadata();
        _notifyListeners();
        
        // Notify any listeners that might be tracking this estimate
        // This ensures real-time updates across the app
        notifyListeners();
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
      report.description.toLowerCase().contains(query.toLowerCase()) ||
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
      await StorageService.getDamageReportsMetadata();
      // Note: In a real app, you'd reconstruct the full reports from metadata
      // For now, we'll just load the metadata and create placeholder reports
      _notifyListeners();
    } catch (e) {
      _setError('Failed to load reports: ${e.toString()}');
    }
  }

  Future<void> _saveReportsMetadata() async {
    try {
      final metadata = _reports.map((report) => {
        'id': report.id,
        'description': report.description,
        'timestamp': report.timestamp.millisecondsSinceEpoch,
        'estimateCount': report.estimateCount,
        'hasEstimates': report.hasEstimates,
      }).toList();
      
      await StorageService.saveDamageReportsMetadata(metadata);
    } catch (e) {
      _setError('Failed to save reports metadata: ${e.toString()}');
    }
  }
}
