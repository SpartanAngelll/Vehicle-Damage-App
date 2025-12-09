import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_supabase_service.dart';

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
      
      // Sync user to Supabase
      try {
        await _syncUserToSupabase(credential.user!, userType: userType);
      } catch (e) {
        // Don't fail signup if Supabase sync fails, just log it
        debugPrint('⚠️ [FirebaseAuth] Failed to sync user to Supabase: $e');
        debugPrint('⚠️ [FirebaseAuth] User created in Firebase but not in Supabase');
      }
      
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
      
      // Sync user to Supabase on sign in (in case they weren't synced before)
      try {
        await _syncUserToSupabase(credential.user!);
      } catch (e) {
        // Don't fail signin if Supabase sync fails, just log it
        debugPrint('⚠️ [FirebaseAuth] Failed to sync user to Supabase: $e');
      }
      
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

  // Sync user to Supabase
  Future<void> _syncUserToSupabase(
    User user, {
    String? userType,
  }) async {
    try {
      final supabase = FirebaseSupabaseService.instance;
      final client = supabase.client;
      
      if (client == null) {
        debugPrint('⚠️ [FirebaseAuth] Supabase client not initialized, skipping sync');
        return;
      }

      // Get Firebase ID token
      final idToken = await user.getIdToken();
      if (idToken == null) {
        debugPrint('⚠️ [FirebaseAuth] Could not get Firebase ID token, skipping sync');
        return;
      }

      // Set session with Firebase token
      try {
        await client.auth.setSession(idToken);
      } catch (e) {
        debugPrint('⚠️ [FirebaseAuth] Could not set Supabase session: $e');
        // Continue anyway, we'll try to insert/update the user
      }

      // Use UPSERT to handle both new users and existing users gracefully
      // This prevents duplicate key errors and race conditions
      debugPrint('🔍 [FirebaseAuth] Syncing user to Supabase (UPSERT)...');
      final result = await supabase.upsert(
        table: 'users',
        data: {
          'firebase_uid': user.uid,
          'email': user.email ?? '',
          'full_name': user.displayName ?? '',
          'role': userType ?? 'owner',
          'updated_at': DateTime.now().toIso8601String(),
          // Only set created_at if this is a new user (PostgreSQL will handle this)
          // For existing users, created_at will be preserved
        },
        conflictTarget: 'firebase_uid',
      );
      
      if (result == null || result.isEmpty) {
        throw Exception('Failed to sync user to Supabase - upsert returned null');
      }
      
      debugPrint('✅ [FirebaseAuth] User synced to Supabase: ${user.uid}');
      debugPrint('🔍 [FirebaseAuth] User data: $result');
    } catch (e) {
      final supabase = FirebaseSupabaseService.instance;
      debugPrint('❌ [FirebaseAuth] Error syncing user to Supabase: $e');
      debugPrint('❌ [FirebaseAuth] User UID: ${user.uid}');
      debugPrint('❌ [FirebaseAuth] User email: ${user.email}');
      debugPrint('❌ [FirebaseAuth] Supabase client initialized: ${supabase.client != null}');
      
      // Don't rethrow - we don't want to fail signup if Supabase sync fails
      // But log it clearly so it can be fixed
      debugPrint('⚠️ [FirebaseAuth] User created in Firebase but NOT synced to Supabase');
      debugPrint('⚠️ [FirebaseAuth] Check Supabase API keys and RLS policies');
    }
  }
}
