import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehicle_damage_app/firebase_options.dart';
import 'package:vehicle_damage_app/test_firebase_auth_rls.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing test environment...\n');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️  Could not load .env file: $e');
    print('   Using fallback values if available\n');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Failed to initialize Firebase: $e');
    exit(1);
  }
  
  // Initialize Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://rodzemxwopecqpazkjyk.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase initialized\n');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    print('   Make sure SUPABASE_ANON_KEY is set in .env file');
    exit(1);
  }
  
  // Check if user is signed in
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    print('❌ No Firebase user signed in.');
    print('   Please sign in with Firebase first in your app.');
    exit(1);
  }
  
  print('✅ Firebase user found: ${firebaseUser.email} (${firebaseUser.uid})\n');
  print('=' * 60);
  print('');
  
  // Run the test
  await testFirebaseAuthAndRLS();
  
  print('');
  print('=' * 60);
  print('✅ Test execution complete!');
  
  exit(0);
}

