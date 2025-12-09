import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_auth_service_wrapper.dart';
import 'firebase_supabase_service.dart';

Future<void> initializeServices() async {
  await Firebase.initializeApp();
  
  await FirebaseSupabaseService.instance.initialize(
    supabaseUrl: 'https://your-project.supabase.co',
    supabaseAnonKey: 'your-anon-key',
  );
}

