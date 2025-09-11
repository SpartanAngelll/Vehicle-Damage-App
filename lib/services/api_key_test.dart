import 'package:flutter/foundation.dart';
import 'api_key_service.dart';

class ApiKeyTest {
  static Future<void> testApiKeyLoading() async {
    debugPrint('🧪 [ApiKeyTest] Testing API key loading...');
    
    // Initialize the service
    await ApiKeyService.initialize();
    
    // Check if OpenAI API key is loaded
    final openaiKey = ApiKeyService.openaiApiKey;
    if (openaiKey != null && openaiKey.isNotEmpty) {
      debugPrint('✅ [ApiKeyTest] OpenAI API key loaded successfully');
      debugPrint('🔑 [ApiKeyTest] Key starts with: ${openaiKey.substring(0, 8)}...');
      debugPrint('📏 [ApiKeyTest] Key length: ${openaiKey.length} characters');
      
      // Validate key format
      if (openaiKey.startsWith('sk-')) {
        debugPrint('✅ [ApiKeyTest] Key format is correct (starts with sk-)');
      } else {
        debugPrint('⚠️ [ApiKeyTest] Key format might be incorrect (should start with sk-)');
      }
    } else {
      debugPrint('❌ [ApiKeyTest] OpenAI API key not loaded');
      debugPrint('💡 [ApiKeyTest] Check that local.properties contains OPENAI_API_KEY');
    }
  }
}
