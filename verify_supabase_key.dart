import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Quick script to verify Supabase API key is correct
/// Run this to check if your SUPABASE_ANON_KEY is valid

Future<void> main() async {
  print('🔍 Verifying Supabase API Key...\n');
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env file loaded');
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    print('   Make sure .env file exists in the project root');
    return;
  }
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://rodzemxwopecqpazkjyk.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  print('\n📋 Configuration:');
  print('   URL: $supabaseUrl');
  
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    print('❌ SUPABASE_ANON_KEY is missing or empty');
    print('\n📝 To fix:');
    print('   1. Go to Supabase Dashboard: https://supabase.com/dashboard');
    print('   2. Select your project');
    print('   3. Go to Settings → API');
    print('   4. Copy the "anon public" key');
    print('   5. Add it to .env file: SUPABASE_ANON_KEY=your_key_here');
    return;
  }
  
  print('   API Key length: ${supabaseAnonKey.length}');
  print('   API Key starts with: ${supabaseAnonKey.substring(0, 20)}...');
  
  // Check for common formatting issues
  if (supabaseAnonKey.contains(' ')) {
    print('⚠️  WARNING: API key contains spaces - this will cause errors!');
    print('   Remove any spaces from the key');
  }
  
  if (supabaseAnonKey.startsWith('"') || supabaseAnonKey.endsWith('"')) {
    print('⚠️  WARNING: API key is wrapped in quotes - remove them!');
  }
  
  // Test the API key by making a simple request
  print('\n🧪 Testing API key...');
  try {
    // Try to access a public endpoint (auth endpoint)
    final url = Uri.parse('$supabaseUrl/rest/v1/');
    final response = await http.get(
      url,
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
    );
    
    print('   Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 404) {
      // 404 is OK - it means the API key is valid but endpoint doesn't exist
      print('✅ API key is VALID!');
      print('   Supabase accepted the key');
    } else if (response.statusCode == 401) {
      print('❌ API key is INVALID');
      print('   Response: ${response.body}');
      print('\n📝 To fix:');
      print('   1. Go to Supabase Dashboard: https://supabase.com/dashboard');
      print('   2. Select your project: rodzemxwopecqpazkjyk');
      print('   3. Go to Settings → API');
      print('   4. Copy the "anon public" key (starts with eyJ...)');
      print('   5. Update .env file with the correct key');
      print('   6. Make sure there are NO spaces or quotes around the key');
    } else {
      print('⚠️  Unexpected response: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error testing API key: $e');
  }
  
  print('\n📝 Next Steps:');
  print('   1. If API key is invalid, get a fresh one from Supabase Dashboard');
  print('   2. Make sure Third Party Auth is configured in Supabase');
  print('   3. Check JWT configuration (see JWT_CONFIGURATION_GUIDE.md)');
}

