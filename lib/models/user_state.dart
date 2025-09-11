import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_firestore_service.dart';
import 'damage_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  owner,
  repairman,
  serviceProfessional, // New role for multi-category support
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
  User? _currentUser; // Firebase Auth user
  bool _disposed = false;
  
  // User profile properties
  String? _fullName;
  String? _profilePhotoUrl;
  
  // For service professionals: track categories and specializations
  List<String> _serviceCategoryIds = [];
  List<String> _specializations = [];
  String? _businessName;
  String? _businessAddress;
  String? _businessPhone;
  String? _website;
  List<String> _certifications = [];
  int _yearsOfExperience = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isVerified = false;
  bool _isAvailable = true;
  List<String> _serviceAreas = [];
  
  // For repair professionals: track submitted estimates (backward compatibility)
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
  User? get currentUser => _currentUser; // Firebase Auth user
  bool get isOwner => _role == UserRole.owner;
  bool get isRepairman => _role == UserRole.repairman;
  bool get isServiceProfessional => _role == UserRole.serviceProfessional;
  
  // User profile getters
  String? get fullName => _fullName;
  String? get profilePhotoUrl => _profilePhotoUrl;
  
  // Service professional specific getters
  List<String> get serviceCategoryIds => List.unmodifiable(_serviceCategoryIds);
  List<String> get specializations => List.unmodifiable(_specializations);
  String? get businessName => _businessName;
  String? get businessAddress => _businessAddress;
  String? get businessPhone => _businessPhone;
  String? get website => _website;
  List<String> get certifications => List.unmodifiable(_certifications);
  int get yearsOfExperience => _yearsOfExperience;
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;
  bool get isVerified => _isVerified;
  bool get isAvailable => _isAvailable;
  List<String> get serviceAreas => List.unmodifiable(_serviceAreas);
  
  // Estimate tracking getters (backward compatibility)
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Initialize user state from Firebase Auth
  void initializeFromFirebase({
    required String userId,
    required String email,
    required String userType,
    String? phoneNumber,
    String? bio,
    User? currentUser,
  }) {
    debugPrint('UserState: Initializing from Firebase - userId: $userId, email: $email, userType: $userType');
    
    _userId = userId;
    _email = email;
    _phoneNumber = phoneNumber;
    _currentUser = currentUser;
    
    // Map user types to roles with backward compatibility
    debugPrint('UserState: Mapping userType "$userType" to role');
    switch (userType) {
      case 'owner':
        _role = UserRole.owner;
        break;
      case 'repairman':
      case 'mechanic':
        _role = UserRole.repairman; // Backward compatibility
        break;
      case 'serviceProfessional':
      case 'service_professional':
        _role = UserRole.serviceProfessional;
        break;
      default:
        debugPrint('UserState: Unknown userType "$userType", defaulting to repairman');
        _role = UserRole.repairman; // Default for backward compatibility
    }
    
    _bio = bio;
    _isAuthenticated = true;
    _lastLoginTime = DateTime.now();
    
    debugPrint('UserState: Role set to ${_role.toString()}, isRepairman: ${_role == UserRole.repairman}');
    debugPrint('UserState: isOwner: ${_role == UserRole.owner}, isRepairman: ${_role == UserRole.repairman}');
    debugPrint('UserState: isServiceProfessional: ${_role == UserRole.serviceProfessional}');
    
    _saveUserData();
    
    // Load service professional profile if applicable
    if (_role == UserRole.serviceProfessional) {
      _loadServiceProfessionalProfile();
    }
    
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
    _fullName = null;
    _profilePhotoUrl = null;
    _currentUser = null;
    
    // Clear service professional fields
    _serviceCategoryIds.clear();
    _specializations.clear();
    _businessName = null;
    _businessAddress = null;
    _businessPhone = null;
    _website = null;
    _certifications.clear();
    _yearsOfExperience = 0;
    _averageRating = 0.0;
    _totalReviews = 0;
    _isVerified = false;
    _isAvailable = true;
    _serviceAreas.clear();
    
    // Clear estimates
    _submittedEstimates.clear();
    _receivedEstimates.clear();
    
    LocalStorageService.clearUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Service professional profile update methods
  Future<void> updateServiceProfessionalProfile({
    List<String>? categoryIds,
    List<String>? specializations,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? website,
    List<String>? certifications,
    int? yearsOfExperience,
    List<String>? serviceAreas,
    bool? isAvailable,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (categoryIds != null) _serviceCategoryIds = categoryIds;
      if (specializations != null) _specializations = specializations;
      if (businessName != null) _businessName = businessName;
      if (businessAddress != null) _businessAddress = businessAddress;
      if (businessPhone != null) _businessPhone = businessPhone;
      if (website != null) _website = website;
      if (certifications != null) _certifications = certifications;
      if (yearsOfExperience != null) _yearsOfExperience = yearsOfExperience;
      if (serviceAreas != null) _serviceAreas = serviceAreas;
      if (isAvailable != null) _isAvailable = isAvailable;

      await _saveUserData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } catch (e) {
      _setError('Service professional profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update service categories
  Future<void> updateServiceCategories(List<String> categoryIds) async {
    try {
      _setLoading(true);
      _clearError();

      if (categoryIds.isEmpty) {
        throw Exception('At least one service category must be selected');
      }

      _serviceCategoryIds = categoryIds;
      await _saveUserData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } catch (e) {
      _setError('Service categories update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Check if user can service a specific category
  bool canServiceCategory(String categoryId) {
    return _serviceCategoryIds.contains(categoryId);
  }

  // Refresh service professional profile from Firebase
  Future<void> refreshServiceProfessionalProfile() async {
    if (_role == UserRole.serviceProfessional) {
      await _loadServiceProfessionalProfile();
    }
  }

  // Check if user can service any of the given categories
  bool canServiceAnyCategory(List<String> categoryIds) {
    return _serviceCategoryIds.any((id) => categoryIds.contains(id));
  }

  Future<void> changeRole(UserRole newRole) async {
    try {
      _setLoading(true);
      _clearError();

      _role = newRole;
      await _saveUserData();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } catch (e) {
      _setError('Role change failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Force update user role from Firebase
  Future<void> forceUpdateRoleFromFirebase() async {
    if (_userId == null) {
      debugPrint('UserState: Cannot update role - userId is null');
      return;
    }
    
    try {
      debugPrint('UserState: Force updating role from Firebase for user: $_userId');
      final firestoreService = FirebaseFirestoreService();
      final userProfile = await firestoreService.getUserProfile(_userId!);
      
      if (userProfile != null) {
        final userType = userProfile['role'] ?? userProfile['userType'] ?? 'owner';
        debugPrint('UserState: Current role in Firebase: $userType');
        
        // Update the role based on Firebase data
        switch (userType) {
          case 'owner':
            _role = UserRole.owner;
            break;
          case 'repairman':
          case 'mechanic':
            _role = UserRole.repairman;
            break;
          case 'serviceProfessional':
          case 'service_professional':
            _role = UserRole.serviceProfessional;
            break;
          default:
            debugPrint('UserState: Unknown userType "$userType", keeping current role');
        }
        
        debugPrint('UserState: Role updated to: ${_role.toString()}');
        debugPrint('UserState: isServiceProfessional: $isServiceProfessional');
        
        await _saveUserData();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('UserState: Failed to force update role: $e');
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  void updateEstimateStatus(String estimateId, EstimateStatus newStatus) {
    if (_role == UserRole.repairman) {
      final index = _submittedEstimates.indexWhere((e) => e.id == estimateId);
      if (index != -1) {
        final updatedEstimate = _submittedEstimates[index].copyWith(status: newStatus);
        _submittedEstimates[index] = updatedEstimate;
        _saveUserData();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
      }
    }
  }

  void removeSubmittedEstimate(String estimateId) {
    if (_role == UserRole.repairman) {
      _submittedEstimates.removeWhere((e) => e.id == estimateId);
      _saveUserData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
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
          reportId: estimateData['reportId'] as String? ?? '',
          jobRequestId: estimateData['jobRequestId'] as String? ?? estimateData['requestId'] as String?,
          ownerId: estimateData['customerId'] as String? ?? estimateData['ownerId'] as String? ?? '',
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
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
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
          reportId: estimateData['reportId'] as String? ?? '',
          jobRequestId: estimateData['jobRequestId'] as String? ?? estimateData['requestId'] as String?,
          ownerId: estimateData['customerId'] as String? ?? estimateData['ownerId'] as String? ?? '',
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
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
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
        estimateId,
        status.name,
        additionalData: {
          'acceptedAt': acceptedAt,
          'declinedAt': declinedAt,
          'cost': acceptedCost ?? declinedCost,
        },
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
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
    if (!_disposed) {
      _isLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners && !_disposed) notifyListeners();
      });
    }
  }

  void _setError(String error) {
    if (!_disposed) {
      _errorMessage = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners && !_disposed) notifyListeners();
      });
    }
  }

  void _clearError() {
    if (!_disposed) {
      _errorMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners && !_disposed) notifyListeners();
      });
    }
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
        
        // Load service professional profile if applicable
        if (_role == UserRole.serviceProfessional) {
          _loadServiceProfessionalProfile();
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  // Load service professional profile from Firebase
  Future<void> _loadServiceProfessionalProfile() async {
    if (_userId == null) {
      debugPrint('UserState: Cannot load service professional profile - userId is null');
      return;
    }
    
    try {
      debugPrint('UserState: Loading service professional profile for user: $_userId');
      final firestoreService = FirebaseFirestoreService();
      final professional = await firestoreService.getServiceProfessional(_userId!);
      
      if (professional != null) {
        debugPrint('UserState: Service professional profile loaded successfully');
        debugPrint('UserState: Professional name: ${professional.fullName}');
        debugPrint('UserState: Professional categories: ${professional.categoryIds}');
        debugPrint('UserState: Professional role: service_professional');
        
        _serviceCategoryIds = professional.categoryIds;
        _specializations = professional.specializations;
        _businessName = professional.businessName;
        _businessAddress = professional.businessAddress;
        _businessPhone = professional.businessPhone;
        _website = professional.website;
        _certifications = professional.certifications;
        _yearsOfExperience = professional.yearsOfExperience;
        _averageRating = professional.averageRating;
        _totalReviews = professional.totalReviews;
        _isVerified = professional.isVerified;
        _isAvailable = professional.isAvailable;
        _serviceAreas = professional.serviceAreas;
        
        // Load user profile properties
        _fullName = professional.fullName;
        _profilePhotoUrl = professional.profilePhotoUrl;
        
        debugPrint('UserState: Categories loaded into UserState: $_serviceCategoryIds');
        debugPrint('UserState: Service category IDs getter returns: $serviceCategoryIds');
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
      } else {
        debugPrint('UserState: No service professional profile found for user: $_userId');
      }
    } catch (e) {
      debugPrint('UserState: Failed to load service professional profile: $e');
    }
  }
}

