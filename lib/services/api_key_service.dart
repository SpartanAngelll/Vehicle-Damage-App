import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApiKeyService {
  static const MethodChannel _channel = MethodChannel('api_keys');
  
  static String? _openaiApiKey;
  
  // Initialize API keys from native platform
  static Future<void> initialize() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // For Android, we'll get the key from BuildConfig
        _openaiApiKey = await _channel.invokeMethod('getOpenAIApiKey');
        debugPrint('🔑 [ApiKeyService] OpenAI API key loaded: ${_openaiApiKey?.substring(0, 8)}...');
      } else {
        // For other platforms, you can implement similar logic
        debugPrint('🔑 [ApiKeyService] Platform not supported for API key loading');
      }
    } catch (e) {
      debugPrint('❌ [ApiKeyService] Failed to load API keys: $e');
    }
  }
  
  static String? get openaiApiKey => _openaiApiKey;
  
  // For development/testing, you can also set the key manually
  static void setOpenAIApiKey(String key) {
    _openaiApiKey = key;
    debugPrint('🔑 [ApiKeyService] OpenAI API key set manually: ${key.substring(0, 8)}...');
  }
}
