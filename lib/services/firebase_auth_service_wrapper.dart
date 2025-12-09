import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_supabase_service.dart';

class FirebaseAuthServiceWrapper {
  static FirebaseAuthServiceWrapper? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseSupabaseService _supabase = FirebaseSupabaseService.instance;

  FirebaseAuthServiceWrapper._();

  static FirebaseAuthServiceWrapper get instance {
    _instance ??= FirebaseAuthServiceWrapper._();
    return _instance!;
  }

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _syncToSupabase(credential.user!);
      return credential;
    } catch (e) {
      debugPrint('❌ [FirebaseAuth] Sign in error: $e');
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(fullName);
      await _syncToSupabase(credential.user!, fullName: fullName, role: role);
      return credential;
    } catch (e) {
      debugPrint('❌ [FirebaseAuth] Sign up error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.client?.auth.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('❌ [FirebaseAuth] Sign out error: $e');
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('❌ [FirebaseAuth] Get token error: $e');
      return null;
    }
  }

  Future<void> _syncToSupabase(
    User user, {
    String? fullName,
    String? role,
  }) async {
    try {
      final idToken = await user.getIdToken();
      if (idToken == null) return;

      await _supabase.client?.auth.setSession(idToken);

      final existingUser = await _supabase.query(
        table: 'users',
        filters: {'firebase_uid': user.uid},
      );

      if (existingUser == null || existingUser.isEmpty) {
        await _supabase.insert(
          table: 'users',
          data: {
            'firebase_uid': user.uid,
            'email': user.email ?? '',
            'full_name': fullName ?? user.displayName ?? '',
            'role': role ?? 'owner',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await _supabase.update(
          table: 'users',
          data: {
            'email': user.email ?? existingUser[0]['email'],
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'firebase_uid': user.uid},
        );
      }
    } catch (e) {
      debugPrint('❌ [FirebaseAuth] Sync to Supabase error: $e');
    }
  }
}

