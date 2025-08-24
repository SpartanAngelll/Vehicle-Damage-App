import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'damage_report.dart';

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

  UserState() {
    _loadUserData();
  }

  Future<void> signIn({
    required String email,
    required String phoneNumber,
    required UserRole role,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await Future.delayed(const Duration(milliseconds: 500));

      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _email = email;
      _phoneNumber = phoneNumber;
      _role = role;
      _bio = bio;
      _isAuthenticated = true;
      _lastLoginTime = DateTime.now();

      await _saveUserData();

      _notifyListeners();
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.delayed(const Duration(milliseconds: 300));

      _isAuthenticated = false;
      _email = null;
      _phoneNumber = null;
      _role = null;
      _userId = null;
      _lastLoginTime = null;
      _bio = null;
      _submittedEstimates.clear();

      await StorageService.clearUserData();

      _notifyListeners();
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

      _notifyListeners();
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

      _notifyListeners();
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

      await Future.delayed(const Duration(milliseconds: 400));

      _bio = newBio.trim();
      await _saveUserData();
      _notifyListeners();
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
      _notifyListeners();
    }
  }

  void updateEstimateStatus(String estimateId, EstimateStatus newStatus) {
    if (_role == UserRole.repairman) {
      final index = _submittedEstimates.indexWhere((e) => e.id == estimateId);
      if (index != -1) {
        final updatedEstimate = _submittedEstimates[index].copyWith(status: newStatus);
        _submittedEstimates[index] = updatedEstimate;
        _saveUserData();
        _notifyListeners();
      }
    }
  }

  void removeSubmittedEstimate(String estimateId) {
    if (_role == UserRole.repairman) {
      _submittedEstimates.removeWhere((e) => e.id == estimateId);
      _saveUserData();
      _notifyListeners();
    }
  }

  // Get available jobs (damage reports without estimates from this professional)
  List<DamageReport> getAvailableJobs(List<DamageReport> allReports) {
    if (_role != UserRole.repairman || _userId == null) return [];
    
    return allReports.where((report) {
      // Check if this professional has already submitted an estimate for this report
      final hasSubmitted = _submittedEstimates.any((estimate) => 
        estimate.repairProfessionalId == _userId && 
        report.id == estimate.id // This would need to be adjusted based on your data structure
      );
      
      return !hasSubmitted;
    }).toList();
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.delayed(const Duration(milliseconds: 800));

      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _email = 'user@gmail.com';
      _phoneNumber = '+1234567890';
      _role = UserRole.owner;
      _isAuthenticated = true;
      _lastLoginTime = DateTime.now();

      await _saveUserData();

      _notifyListeners();
    } catch (e) {
      _setError('Google sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.delayed(const Duration(milliseconds: 800));

      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _email = 'user@icloud.com';
      _phoneNumber = '+1234567890';
      _role = UserRole.owner;
      _isAuthenticated = true;
      _lastLoginTime = DateTime.now();

      await _saveUserData();

      _notifyListeners();
    } catch (e) {
      _setError('Apple sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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

  void _notifyListeners() {
    if (!_isLoading) {
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await StorageService.getUserId();
      final email = await StorageService.getUserEmail();
      final phone = await StorageService.getUserPhone();
      final roleString = await StorageService.getUserRole();
      final bio = await StorageService.getUserBio();
      final isAuthenticated = await StorageService.getIsAuthenticated();
      final lastLoginTime = await StorageService.getLastLoginTime();

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
        _notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> _saveUserData() async {
    try {
      if (_userId != null) {
        await StorageService.saveUserId(_userId!);
      }
      if (_email != null) {
        await StorageService.saveUserEmail(_email!);
      }
      if (_phoneNumber != null) {
        await StorageService.saveUserPhone(_phoneNumber!);
      }
      if (_role != null) {
        await StorageService.saveUserRole(_role.toString().split('.').last);
      }
      if (_bio != null) {
        await StorageService.saveUserBio(_bio!);
      }
      await StorageService.saveIsAuthenticated(_isAuthenticated);
      if (_lastLoginTime != null) {
        await StorageService.saveLastLoginTime(_lastLoginTime!);
      }
    } catch (e) {
      _setError('Failed to save user data: ${e.toString()}');
    }
  }

  // No cleanup needed for this class
}
