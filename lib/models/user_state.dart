import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';
import '../services/services.dart';
import 'damage_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner,
  repairman,
}

class UserState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;
  String? _phoneNumber;
  UserRole? _role;
  String? _userId;
  DateTime? _lastLoginTime;
  String? _bio;
  bool _isLoading = false;
  String? _errorMessage;
  
  // For repair professionals: track submitted estimates
  final List<Estimate> _submittedEstimates = [];
  
  // For vehicle owners: track received estimates
  final List<Estimate> _receivedEstimates = [];

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  UserRole? get role => _role;
  String? get userId => _userId;
  DateTime? get lastLoginTime => _lastLoginTime;
  String? get bio => _bio;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOwner => _role == UserRole.owner;
  bool get isRepairman => _role == UserRole.repairman;
  
  // Estimate tracking getters
  List<Estimate> get submittedEstimates => List.unmodifiable(_submittedEstimates);
  List<Estimate> get pendingEstimates => _submittedEstimates.where((e) => e.status == EstimateStatus.pending).toList();
  List<Estimate> get acceptedEstimates => _submittedEstimates.where((e) => e.status == EstimateStatus.accepted).toList();
  List<Estimate> get declinedEstimates => _submittedEstimates.where((e) => e.status == EstimateStatus.declined).toList();
  int get totalSubmittedEstimates => _submittedEstimates.length;
  int get totalPendingEstimates => pendingEstimates.length;
  int get totalAcceptedEstimates => acceptedEstimates.length;
  int get totalDeclinedEstimates => declinedEstimates.length;
  
  // Estimate tracking getters for vehicle owners
  List<Estimate> get receivedEstimates => List.unmodifiable(_receivedEstimates);
  List<Estimate> get pendingReceivedEstimates => _receivedEstimates.where((e) => e.status == EstimateStatus.pending).toList();
  List<Estimate> get acceptedReceivedEstimates => _receivedEstimates.where((e) => e.status == EstimateStatus.accepted).toList();
  List<Estimate> get declinedReceivedEstimates => _receivedEstimates.where((e) => e.status == EstimateStatus.declined).toList();
  int get totalReceivedEstimates => _receivedEstimates.length;
  int get totalPendingReceivedEstimates => pendingReceivedEstimates.length;
  int get totalAcceptedReceivedEstimates => acceptedReceivedEstimates.length;
  int get totalDeclinedReceivedEstimates => declinedReceivedEstimates.length;

  UserState() {
    _loadUserData();
  }

  // Initialize user state from Firebase Auth
  void initializeFromFirebase({
    required String userId,
    required String email,
    required String userType,
    String? phoneNumber,
    String? bio,
  }) {
    debugPrint('UserState: Initializing from Firebase - userId: $userId, email: $email, userType: $userType');
    
    _userId = userId;
    _email = email;
    _phoneNumber = phoneNumber;
    _role = userType == 'owner' ? UserRole.owner : UserRole.repairman;
    _bio = bio;
    _isAuthenticated = true;
    _lastLoginTime = DateTime.now();
    
    debugPrint('UserState: Role set to ${_role.toString()}, isRepairman: ${_role == UserRole.repairman}');
    debugPrint('UserState: isOwner: ${_role == UserRole.owner}, isRepairman: ${_role == UserRole.repairman}');
    
    _saveUserData();
    notifyListeners();
  }

  // Clear user state on sign out
  void clearUserState() {
    _isAuthenticated = false;
    _email = null;
    _phoneNumber = null;
    _role = null;
    _userId = null;
    _lastLoginTime = null;
    _bio = null;
    _submittedEstimates.clear();
    _receivedEstimates.clear();
    
    LocalStorageService.clearUserData();
    notifyListeners();
  }

  // Sign out method for compatibility with existing code
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.delayed(const Duration(milliseconds: 300));

      clearUserState();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? email,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (email != null) _email = email;
      if (phoneNumber != null) _phoneNumber = phoneNumber;
      if (bio != null) _bio = bio;

      await _saveUserData();

      notifyListeners();
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changeRole(UserRole newRole) async {
    try {
      _setLoading(true);
      _clearError();

      _role = newRole;
      await _saveUserData();

      notifyListeners();
    } catch (e) {
      _setError('Role change failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBio(String newBio) async {
    try {
      _setLoading(true);
      _clearError();

      if (newBio.trim().isEmpty) {
        throw Exception('Bio cannot be empty');
      }
      if (newBio.length > 500) {
        throw Exception('Bio must be 500 characters or less');
      }

      _bio = newBio.trim();
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _setError('Bio update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Job management methods for repair professionals
  void addSubmittedEstimate(Estimate estimate) {
    if (_role == UserRole.repairman) {
      _submittedEstimates.add(estimate);
      _saveUserData();
      notifyListeners();
    }
  }

  void updateEstimateStatus(String estimateId, EstimateStatus newStatus) {
    if (_role == UserRole.repairman) {
      final index = _submittedEstimates.indexWhere((e) => e.id == estimateId);
      if (index != -1) {
        final updatedEstimate = _submittedEstimates[index].copyWith(status: newStatus);
        _submittedEstimates[index] = updatedEstimate;
        _saveUserData();
        notifyListeners();
      }
    }
  }

  void removeSubmittedEstimate(String estimateId) {
    if (_role == UserRole.repairman) {
      _submittedEstimates.removeWhere((e) => e.id == estimateId);
      _saveUserData();
      notifyListeners();
    }
  }

  // Get available jobs (damage reports without estimates from this professional)
  List<DamageReport> getAvailableJobs(List<DamageReport> allReports) {
    if (_role != UserRole.repairman || _userId == null) {
      return [];
    }

    return allReports.where((report) {
      // Only show reports that don't have estimates from this professional
      return !report.estimates.any((estimate) => estimate.repairProfessionalId == _userId);
    }).toList();
  }

  // Load estimates for repair professional
  Future<void> loadEstimatesForProfessional() async {
    if (_userId == null || !_isAuthenticated || !isRepairman) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getAllEstimatesForProfessional(_userId!);
      
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
      
      _submittedEstimates.clear();
      _submittedEstimates.addAll(estimates);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load estimates: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load estimates for vehicle owner
  Future<void> loadEstimatesForOwner() async {
    if (_userId == null || !_isAuthenticated || !isOwner) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      // Use a more efficient approach - don't create new AppState instance
      final firestoreService = FirebaseFirestoreService();
      final estimatesData = await firestoreService.getAllEstimatesForOwner(_userId!);
      
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
      
      _receivedEstimates.clear();
      _receivedEstimates.addAll(estimates);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load estimates: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update received estimate status for owners
  Future<void> updateReceivedEstimateStatus({
    required String estimateId,
    required EstimateStatus status,
    DateTime? acceptedAt,
    double? acceptedCost,
    DateTime? declinedAt,
    double? declinedCost,
  }) async {
    if (_userId == null || !_isAuthenticated || !isOwner) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      final firestoreService = FirebaseFirestoreService();
      await firestoreService.updateEstimateStatus(
        estimateId: estimateId,
        status: status.name,
        acceptedAt: acceptedAt,
        declinedAt: declinedAt,
        cost: acceptedCost ?? declinedCost,
      );
      
      // Update local state
      final index = _receivedEstimates.indexWhere((e) => e.id == estimateId);
      if (index != -1) {
        final updatedEstimate = _receivedEstimates[index].copyWith(
          status: status,
          acceptedAt: acceptedAt,
          declinedAt: declinedAt,
        );
        _receivedEstimates[index] = updatedEstimate;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update estimate status: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  EstimateStatus _parseEstimateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return EstimateStatus.accepted;
      case 'declined':
        return EstimateStatus.declined;
      case 'pending':
      default:
        return EstimateStatus.pending;
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    try {
      // Save individual user data fields
      if (_userId != null) await LocalStorageService.saveUserId(_userId!);
      if (_email != null) await LocalStorageService.saveUserEmail(_email!);
      if (_phoneNumber != null) await LocalStorageService.saveUserPhone(_phoneNumber!);
      if (_role != null) await LocalStorageService.saveUserRole(_role.toString().split('.').last);
      if (_bio != null) await LocalStorageService.saveUserBio(_bio!);
      await LocalStorageService.saveIsAuthenticated(_isAuthenticated);
      if (_lastLoginTime != null) await LocalStorageService.saveLastLoginTime(_lastLoginTime!);
    } catch (e) {
      debugPrint('Failed to save user data: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await LocalStorageService.getUserId();
      final email = await LocalStorageService.getUserEmail();
      final phone = await LocalStorageService.getUserPhone();
      final roleString = await LocalStorageService.getUserRole();
      final bio = await LocalStorageService.getUserBio();
      final isAuthenticated = await LocalStorageService.getIsAuthenticated();
      final lastLoginTime = await LocalStorageService.getLastLoginTime();

      if (userId != null && email != null && phone != null && roleString != null) {
        _userId = userId;
        _email = email;
        _phoneNumber = phone;
        _role = UserRole.values.firstWhere(
          (role) => role.toString() == 'UserRole.$roleString',
          orElse: () => UserRole.owner,
        );
        _bio = bio;
        _isAuthenticated = isAuthenticated ?? false;
        _lastLoginTime = lastLoginTime;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }
}

