import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import 'api_key_service.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final Uuid _uuid = const Uuid();
  OpenAIClient? _client;
  
  // Initialize with API key from ApiKeyService
  void initialize() {
    try {
      final apiKey = ApiKeyService.openaiApiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        _client = OpenAIClient(apiKey: apiKey);
        print('🔍 [OpenAI] Initialized with API key: ${apiKey.substring(0, 8)}...');
      } else {
        print('⚠️ [OpenAI] No API key found, using mock responses');
        _client = null;
      }
    } catch (e) {
      print('❌ [OpenAI] Failed to initialize client: $e');
      _client = null;
    }
  }

  // Fetch estimate data from Firebase
  Future<Map<String, dynamic>?> _fetchEstimateData(String estimateId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('estimates').doc(estimateId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('🔍 [OpenAI] Fetched estimate data for ID: $estimateId');
        return data;
      } else {
        print('⚠️ [OpenAI] No estimate found for ID: $estimateId');
        return null;
      }
    } catch (e) {
      print('❌ [OpenAI] Error fetching estimate data: $e');
      return null;
    }
  }

  // Analyze conversation with automatic estimate data fetching
  Future<JobSummary> analyzeConversationWithEstimate({
    required List<ChatMessage> messages,
    required String estimateId,
    required String chatRoomId,
    required String customerId,
    required String professionalId,
    required String originalEstimate,
  }) async {
    return analyzeConversation(
      messages: messages,
      estimateId: estimateId,
      chatRoomId: chatRoomId,
      customerId: customerId,
      professionalId: professionalId,
      originalEstimate: originalEstimate,
      estimateData: null, // Will be fetched automatically
    );
  }

  // Analyze conversation and extract booking information
  Future<JobSummary> analyzeConversation({
    required List<ChatMessage> messages,
    required String estimateId,
    required String chatRoomId,
    required String customerId,
    required String professionalId,
    required String originalEstimate,
    Map<String, dynamic>? estimateData,
  }) async {
    try {
      print('🔍 [OpenAI] Analyzing conversation with ${messages.length} messages');
      
      // Fetch estimate data if not provided
      Map<String, dynamic>? finalEstimateData = estimateData;
      if (finalEstimateData == null && estimateId.isNotEmpty) {
        finalEstimateData = await _fetchEstimateData(estimateId);
      }
      
      // Filter out system messages and prepare conversation text
      final conversationText = _prepareConversationText(messages);
      
      // Create the analysis prompt with estimate context
      final prompt = _createAnalysisPrompt(conversationText, originalEstimate, finalEstimateData);
      
      // Use actual OpenAI API call if available, otherwise fall back to mock
      String analysisText;
      if (_client != null) {
        try {
          analysisText = await _callOpenAIAPI(prompt);
          print('🔍 [OpenAI] Using actual API response');
        } catch (e) {
          print('⚠️ [OpenAI] API call failed, falling back to mock: $e');
          analysisText = _generateMockAnalysis(conversationText, finalEstimateData);
        }
      } else {
        analysisText = _generateMockAnalysis(conversationText, finalEstimateData);
        print('🔍 [OpenAI] Using mock analysis response (no API key)');
      }
      
      // Parse the JSON response
      final analysis = _parseAnalysisResponse(analysisText);
      
      // Create job summary with booking details
      final jobSummary = JobSummary(
        id: _uuid.v4(),
        chatRoomId: chatRoomId,
        estimateId: estimateId,
        customerId: customerId,
        professionalId: professionalId,
        originalEstimate: originalEstimate,
        conversationSummary: '${analysis['service']} - ${analysis['status']}',
        extractedPrice: _extractPrice(analysis['price']),
        extractedStartTime: _parseBookingDateTime(analysis['date'], analysis['time']),
        extractedEndTime: null, // Not extracted in new format
        extractedLocation: null, // Not extracted in new format
        extractedDeliverables: _buildDeliverablesList(analysis),
        extractedImportantPoints: _buildImportantPointsList(analysis),
        confidenceScore: _calculateBookingConfidenceScore(analysis),
        createdAt: DateTime.now(),
        rawAnalysis: analysis,
      );

      print('✅ [OpenAI] Analysis completed with confidence: ${jobSummary.confidenceScore}');
      return jobSummary;
    } catch (e) {
      print('❌ [OpenAI] Error analyzing conversation: $e');
      rethrow;
    }
  }

  // Prepare conversation text for analysis
  String _prepareConversationText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    
    for (final message in messages) {
      if (message.type == MessageType.system) continue;
      
      buffer.writeln('${message.senderName}: ${message.content}');
    }
    
    return buffer.toString();
  }

  // Create the analysis prompt for booking extraction
  String _createAnalysisPrompt(String conversation, String originalEstimate, Map<String, dynamic>? estimateData) {
    // Build estimate context section
    String estimateContext = '';
    if (estimateData != null) {
      estimateContext = '''

ACCEPTED ESTIMATE CONTEXT:
- Service Description: ${estimateData['description'] ?? 'Not specified'}
- Original Cost: ${estimateData['cost'] ?? 'Not specified'}
- Lead Time: ${estimateData['leadTimeDays'] ?? 'Not specified'} days
- Professional: ${estimateData['repairProfessionalEmail'] ?? 'Not specified'}
- Status: ${estimateData['status'] ?? 'Not specified'}
- Submitted: ${estimateData['submittedAt'] ?? 'Not specified'}
- Accepted: ${estimateData['acceptedAt'] ?? 'Not specified'}

Use this estimate context to better understand the service being discussed and validate pricing information.
''';
    }

    return '''
You are an AI booking extractor. Analyze the chat conversation between a customer and service professional and extract structured booking details.

Extract ONLY the information that was explicitly agreed upon or confirmed. Return a clean JSON object with NO additional text before or after.

Required JSON structure:
{
  "service": "string - what service was booked (e.g., 'Nail appointment', 'Hair cut', 'Service')",
  "style": "string or null - specific style mentioned (e.g., 'Almond', 'Bob cut', 'Full service')",
  "color": "string or null - specific color mentioned (e.g., 'Navy Blue', 'Blonde', 'Red')",
  "date": "string - date in ISO format (YYYY-MM-DD) if possible, otherwise descriptive string",
  "time": "string or null - time in 12h format if mentioned (e.g., '10:30 AM', '2:00 PM')",
  "price": "integer - final agreed price (numbers only, no currency symbols)",
  "currency": "string - default 'JMD' unless other currency mentioned",
  "status": "string - 'Confirmed', 'Pending', or 'Cancelled' based on conversation"
}

Extraction Rules:
- SERVICE: PRIORITIZE conversation context over estimate data. Look for what service was actually discussed and agreed upon in the conversation. Only use estimate context if the conversation is unclear about the service type.
- STYLE: Extract specific style preferences mentioned (nail shape, hair style, etc.)
- COLOR: Extract specific colors mentioned for the service
- DATE: Convert relative dates (tomorrow, next week) to actual dates when possible
- TIME: Extract specific appointment times mentioned
- PRICE: Find the final total price that was agreed upon. Use estimate cost as reference but prioritize conversation prices.
- CURRENCY: Default to "JMD" unless other currency is mentioned
- STATUS: Determine booking status from conversation context

IMPORTANT: If the conversation clearly indicates a different service type than the estimate (e.g., conversation about nails but estimate is for vehicle repair), ALWAYS use the conversation service type.

$estimateContext

Original Estimate Summary: $originalEstimate

Conversation:
$conversation

Return ONLY the JSON object, no explanations or additional text.
''';
  }

  // Parse the analysis response
  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Clean the response - remove any markdown formatting
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();
      
      final parsed = json.decode(cleanResponse) as Map<String, dynamic>;
      
      // Validate required fields and set defaults
      return {
        'service': parsed['service'] ?? 'Service',
        'style': parsed['style'],
        'color': parsed['color'],
        'date': parsed['date'] ?? _getDefaultDate(),
        'time': parsed['time'],
        'price': parsed['price'] ?? 0,
        'currency': parsed['currency'] ?? 'JMD',
        'status': parsed['status'] ?? 'Pending',
      };
    } catch (e) {
      print('❌ [OpenAI] Error parsing analysis response: $e');
      print('❌ [OpenAI] Raw response: $response');
      
      // Return default structure if parsing fails
      return {
        'service': 'Service',
        'style': null,
        'color': null,
        'date': _getDefaultDate(),
        'time': null,
        'price': 0,
        'currency': 'JMD',
        'status': 'Pending',
      };
    }
  }

  // Get default date (tomorrow)
  String _getDefaultDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  }

  // Extract price from analysis
  double _extractPrice(dynamic priceValue) {
    print('🔍 [OpenAI] Extracting price from: $priceValue (type: ${priceValue.runtimeType})');
    
    if (priceValue == null) {
      print('🔍 [OpenAI] Price value is null, returning 0.0');
      return 0.0;
    }
    
    if (priceValue is num) {
      final result = priceValue.toDouble();
      print('🔍 [OpenAI] Extracted numeric price: $result');
      return result;
    }
    
    if (priceValue is String) {
      // Remove currency symbols and parse
      final cleanPrice = priceValue.replaceAll(RegExp(r'[^\d.]'), '');
      final result = double.tryParse(cleanPrice) ?? 0.0;
      print('🔍 [OpenAI] Extracted string price: $result (from "$priceValue" -> "$cleanPrice")');
      return result;
    }
    
    print('🔍 [OpenAI] Unknown price type, returning 0.0');
    return 0.0;
  }

  // Parse booking date and time
  DateTime? _parseBookingDateTime(String? date, String? time) {
    print('🔍 [OpenAI] Parsing date/time: date="$date", time="$time"');
    
    if (date == null) {
      print('🔍 [OpenAI] Date is null, returning null');
      return null;
    }
    
    try {
      // Try to parse ISO date first
      if (date.contains('-') && date.length >= 10) {
        final dateOnly = date.substring(0, 10);
        final parsedDate = DateTime.parse(dateOnly);
        
        if (time != null) {
          // Parse time and combine with date
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(time);
          if (timeMatch != null) {
            int hour = int.parse(timeMatch.group(1)!);
            final minute = int.parse(timeMatch.group(2)!);
            final period = timeMatch.group(3)?.toUpperCase();
            
            // Convert to 24-hour format
            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }
            
            final result = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
            print('🔍 [OpenAI] Parsed date/time with time: $result');
            return result;
          }
        }
        
        // If no time provided, use default time (10:00 AM)
        final result = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, 10, 0);
        print('🔍 [OpenAI] Parsed date/time with default time: $result');
        return result;
      }
      
      // Handle relative dates
      final now = DateTime.now();
      final lowerDate = date.toLowerCase();
      
      if (lowerDate.contains('tomorrow')) {
        return now.add(const Duration(days: 1));
      } else if (lowerDate.contains('today')) {
        return now;
      } else if (lowerDate.contains('next week')) {
        return now.add(const Duration(days: 7));
      }
      
      return null;
    } catch (e) {
      print('❌ [OpenAI] Error parsing booking date/time: $date $time - $e');
      return null;
    }
  }

  // Build deliverables list from booking analysis
  List<String> _buildDeliverablesList(Map<String, dynamic> analysis) {
    final deliverables = <String>[];
    
    if (analysis['service'] != null) {
      deliverables.add(analysis['service'] as String);
    }
    
    if (analysis['style'] != null) {
      deliverables.add('Style: ${analysis['style']}');
    }
    
    if (analysis['color'] != null) {
      deliverables.add('Color: ${analysis['color']}');
    }
    
    return deliverables;
  }

  // Build important points list from booking analysis
  List<String> _buildImportantPointsList(Map<String, dynamic> analysis) {
    final points = <String>[];
    
    if (analysis['date'] != null) {
      points.add('Date: ${analysis['date']}');
    }
    
    if (analysis['time'] != null) {
      points.add('Time: ${analysis['time']}');
    }
    
    if (analysis['price'] != null && analysis['currency'] != null) {
      points.add('Price: ${analysis['price']} ${analysis['currency']}');
    }
    
    if (analysis['status'] != null) {
      points.add('Status: ${analysis['status']}');
    }
    
    return points;
  }

  // Calculate confidence score for booking analysis
  double _calculateBookingConfidenceScore(Map<String, dynamic> analysis) {
    double score = 0.0;
    
    // Service confidence (required)
    if (analysis['service'] != null && 
        (analysis['service'] as String).isNotEmpty) {
      score += 0.3;
    }
    
    // Price confidence (required)
    if (analysis['price'] != null && analysis['price'] > 0) {
      score += 0.3;
    }
    
    // Date confidence
    if (analysis['date'] != null && 
        (analysis['date'] as String).isNotEmpty) {
      score += 0.2;
    }
    
    // Time confidence
    if (analysis['time'] != null && 
        (analysis['time'] as String).isNotEmpty) {
      score += 0.1;
    }
    
    // Status confidence
    if (analysis['status'] != null && 
        (analysis['status'] as String).isNotEmpty) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  // Call OpenAI API to analyze conversation
  Future<String> _callOpenAIAPI(String prompt) async {
    if (_client == null) {
      throw Exception('OpenAI client not initialized');
    }

    try {
      // For now, use the mock implementation since the API structure needs to be verified
      // TODO: Implement actual OpenAI API call once the correct API structure is determined
      throw Exception('API call not implemented yet - using mock');
    } catch (e) {
      print('❌ [OpenAI] API call error: $e');
      rethrow;
    }
  }

  // Generate mock analysis for testing (replace with actual OpenAI API call)
  String _generateMockAnalysis(String conversation, Map<String, dynamic>? estimateData) {
    // Analyze the actual conversation text to extract booking details
    final lines = conversation.split('\n');
    String? service;
    String? style;
    String? color;
    String? date;
    String? time;
    int? price;
    String currency = 'JMD';
    String status = 'Pending';
    
    // First, analyze conversation for service type (prioritize conversation context)
    String? conversationService;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('nail') || lowerLine.contains('nails') || lowerLine.contains('manicure') || lowerLine.contains('pedicure')) {
        conversationService = 'Nail appointment';
        break;
      } else if (lowerLine.contains('hair') || lowerLine.contains('cut') || lowerLine.contains('styling')) {
        conversationService = 'Hair cut';
        break;
      } else if (lowerLine.contains('repair') || lowerLine.contains('fix') || lowerLine.contains('damage') || lowerLine.contains('vehicle') || lowerLine.contains('car') || lowerLine.contains('service')) {
        conversationService = 'Service';
        break;
      }
    }
    
    // Use conversation service if found, otherwise fall back to estimate data
    if (conversationService != null) {
      service = conversationService;
      print('🔍 [OpenAI] Service type determined from conversation: $service');
      
      // Check for mismatch with estimate data
      if (estimateData != null && estimateData['description'] != null) {
        final estimateDescription = estimateData['description'].toString().toLowerCase();
        final isEstimateRepair = estimateDescription.contains('repair') || estimateDescription.contains('fix') || estimateDescription.contains('damage') || estimateDescription.contains('vehicle');
        final isConversationNail = conversationService == 'Nail appointment';
        
        if (isEstimateRepair && isConversationNail) {
          print('⚠️ [OpenAI] WARNING: Mismatch detected - Estimate is for repair service but conversation is about nail appointment. Using conversation context.');
        }
      }
    } else if (estimateData != null && estimateData['description'] != null) {
      final description = estimateData['description'].toString().toLowerCase();
      if (description.contains('nail') || description.contains('manicure')) {
        service = 'Nail appointment';
      } else if (description.contains('hair') || description.contains('cut')) {
        service = 'Hair cut';
      } else if (description.contains('repair') || description.contains('fix') || description.contains('damage')) {
        service = 'Service';
      } else {
        service = estimateData['description'].toString();
      }
      print('🔍 [OpenAI] Service type determined from estimate: $service');
    } else {
      service = 'Service'; // Generic fallback
      print('🔍 [OpenAI] Service type set to generic fallback');
    }
    
    // Look for style preferences
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('almond')) {
        style = 'Almond';
      } else if (lowerLine.contains('square')) {
        style = 'Square';
      } else if (lowerLine.contains('round')) {
        style = 'Round';
      } else if (lowerLine.contains('bob')) {
        style = 'Bob cut';
      }
    }
    
    // Look for colors
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('navy blue')) {
        color = 'Navy Blue';
      } else if (lowerLine.contains('red')) {
        color = 'Red';
      } else if (lowerLine.contains('blonde')) {
        color = 'Blonde';
      } else if (lowerLine.contains('black')) {
        color = 'Black';
      }
    }
    
    // Look for dates and times
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('tomorrow')) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        date = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      } else if (lowerLine.contains('today')) {
        final today = DateTime.now();
        date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      }
      
      // Look for time patterns
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false).firstMatch(line);
      if (timeMatch != null) {
        time = '${timeMatch.group(1)}:${timeMatch.group(2)} ${timeMatch.group(3)?.toUpperCase() ?? 'AM'}';
      }
    }
    
    // Look for price - use estimate as baseline if available
    if (estimateData != null && estimateData['cost'] != null) {
      price = (estimateData['cost'] as num).toInt();
    }
    
    // Override with conversation price if found
    for (final line in lines) {
      final priceMatch = RegExp(r'\$?(\d+(?:,\d{3})*)').firstMatch(line);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1)!.replaceAll(',', '');
        final conversationPrice = int.tryParse(priceStr);
        if (conversationPrice != null) {
          price = conversationPrice;
        }
      }
    }
    
    // Look for confirmation
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('book it') || lowerLine.contains('confirmed') || lowerLine.contains('yes') && lowerLine.contains('see you')) {
        status = 'Confirmed';
      }
    }
    
    // Set defaults
    service ??= 'Service';
    date ??= _getDefaultDate();
    time ??= '10:00 AM'; // Default time
    price ??= 100; // Default price instead of 0
    
    return json.encode({
      'service': service,
      'style': style,
      'color': color,
      'date': date,
      'time': time,
      'price': price,
      'currency': currency,
      'status': status,
    });
  }

  // Save booking data to Firebase
  Future<void> saveBookingToFirebase({
    required String bookingId,
    required Map<String, dynamic> bookingData,
    required String customerId,
    required String professionalId,
    required String chatRoomId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Create booking document
      final booking = {
        'id': bookingId,
        'customerId': customerId,
        'professionalId': professionalId,
        'chatRoomId': chatRoomId,
        'service': bookingData['service'],
        'style': bookingData['style'],
        'color': bookingData['color'],
        'date': bookingData['date'],
        'time': bookingData['time'],
        'price': bookingData['price'],
        'currency': bookingData['currency'],
        'status': bookingData['status'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('bookings').doc(bookingId).set(booking);
      
      print('✅ [OpenAI] Booking saved to Firebase: $bookingId');
    } catch (e) {
      print('❌ [OpenAI] Error saving booking to Firebase: $e');
      rethrow;
    }
  }

  // Generate booking confirmation message
  Future<String> generateBookingConfirmationMessage(JobSummary summary) async {
    try {
      final bookingData = summary.rawAnalysis;
      
      if (bookingData == null) {
        return 'Booking details have been extracted. Please review and confirm.';
      }
      
      return '''
Booking Confirmation:

Service: ${bookingData['service'] ?? 'Service'}
${bookingData['style'] != null ? 'Style: ${bookingData['style']}' : ''}
${bookingData['color'] != null ? 'Color: ${bookingData['color']}' : ''}
Date: ${bookingData['date'] ?? 'To be confirmed'}
${bookingData['time'] != null ? 'Time: ${bookingData['time']}' : ''}
Price: ${bookingData['price'] ?? 0} ${bookingData['currency'] ?? 'JMD'}
Status: ${bookingData['status'] ?? 'Pending'}

Please confirm these details are correct.
''';
    } catch (e) {
      print('❌ [OpenAI] Error generating confirmation message: $e');
      return 'Booking details have been extracted. Please review and confirm.';
    }
  }
}
