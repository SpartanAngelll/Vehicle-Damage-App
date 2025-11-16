import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _user != null;

  FirebaseAuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (!_disposed) {
        _user = user;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String userType, // 'owner' or 'repairman'
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set custom claims for user type (this would typically be done on the backend)
      // For now, we'll store it in user metadata
      await credential.user?.updateDisplayName(userType);
      
      _setLoading(false);
      return credential;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
      return null;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return credential;
    } on FirebaseAuthException catch (e) {
      final errorMessage = _getErrorMessage(e.code);
      debugPrint('❌ [FirebaseAuth] Sign in error: ${e.code} - ${e.message}');
      _setError(errorMessage);
      _setLoading(false);
      return null;
    } catch (e) {
      // Handle network errors and other exceptions
      final errorString = e.toString().toLowerCase();
      String errorMessage;
      
      if (errorString.contains('network') || 
          errorString.contains('timeout') ||
          errorString.contains('unreachable') ||
          errorString.contains('connection') ||
          errorString.contains('unavailable')) {
        errorMessage = 'Network error: Please check your internet connection and try again.';
      } else {
        errorMessage = 'An unexpected error occurred: ${e.toString()}';
      }
      
      debugPrint('❌ [FirebaseAuth] Unexpected sign in error: $e');
      _setError(errorMessage);
      _setLoading(false);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _setLoading(false);
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _user!.updatePhotoURL(photoURL);
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    }
  }

  // Get user type from display name
  String? getUserType() {
    return _user?.displayName;
  }

  // Check if user is a repairman
  bool get isRepairman => getUserType() == 'repairman';

  // Check if user is an owner
  bool get isOwner => getUserType() == 'owner';

  // Private methods
  void _setLoading(bool loading) {
    if (!_disposed) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (!_disposed) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (!_disposed) {
      _error = null;
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
      case 'network_error':
      case 'UNAVAILABLE':
        return 'Network error: Please check your internet connection and try again.';
      case 'SERVICE_NOT_AVAILABLE':
        return 'Firebase service is temporarily unavailable. Please try again later.';
      default:
        // Check if the error message contains network-related keywords
        if (code.toLowerCase().contains('network') || 
            code.toLowerCase().contains('timeout') ||
            code.toLowerCase().contains('unreachable') ||
            code.toLowerCase().contains('connection')) {
          return 'Network error: Please check your internet connection and try again.';
        }
        return 'Authentication failed: $code';
    }
  }
}
