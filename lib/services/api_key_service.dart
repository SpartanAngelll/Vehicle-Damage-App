import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyService {
  static String? _openaiApiKey;
  static String? _googleMapsApiKey;
  
  // Initialize API keys from .env file in project root (works for all platforms)
  static Future<void> initialize() async {
    try {
      // Load Google Maps API key from .env file
      _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (_googleMapsApiKey != null && _googleMapsApiKey!.isNotEmpty) {
        debugPrint('🔑 [ApiKeyService] Google Maps API key loaded from .env: ${_googleMapsApiKey!.substring(0, 8)}...');
      } else {
        debugPrint('⚠️ [ApiKeyService] GOOGLE_MAPS_API_KEY not found in .env file');
      }
      
      // Load OpenAI API key from .env file (for all platforms including Android)
      _openaiApiKey = dotenv.env['OPENAI_API_KEY'];
      if (_openaiApiKey != null && _openaiApiKey!.isNotEmpty) {
        debugPrint('🔑 [ApiKeyService] OpenAI API key loaded from .env: ${_openaiApiKey!.substring(0, 8)}...');
      } else {
        debugPrint('⚠️ [ApiKeyService] OPENAI_API_KEY not found in .env file');
        debugPrint('⚠️ [ApiKeyService] Make sure OPENAI_API_KEY is set in the root .env file');
      }
    } catch (e) {
      debugPrint('❌ [ApiKeyService] Failed to load API keys: $e');
      debugPrint('❌ [ApiKeyService] Make sure .env file exists in the project root and contains OPENAI_API_KEY');
    }
  }
  
  static String? get openaiApiKey => _openaiApiKey;
  static String? get googleMapsApiKey => _googleMapsApiKey;
  
  // For development/testing, you can also set the key manually
  static void setOpenAIApiKey(String key) {
    _openaiApiKey = key;
    debugPrint('🔑 [ApiKeyService] OpenAI API key set manually: ${key.substring(0, 8)}...');
  }
  
  static void setGoogleMapsApiKey(String key) {
    _googleMapsApiKey = key;
    debugPrint('🔑 [ApiKeyService] Google Maps API key set manually: ${key.substring(0, 8)}...');
  }
}
