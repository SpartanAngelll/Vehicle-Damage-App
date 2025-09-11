import 'dart:core';

/// Result of content filtering
class FilterResult {
  final bool hasViolations;
  final List<String> detectedPatterns;
  final String warningMessage;

  FilterResult({
    required this.hasViolations,
    required this.detectedPatterns,
    required this.warningMessage,
  });
}

/// Service for filtering chat content to detect personal contact information
/// and external communication requests for safety purposes.
class ContentFilterService {
  static final ContentFilterService _instance = ContentFilterService._internal();
  factory ContentFilterService() => _instance;
  ContentFilterService._internal();

  // Regular expressions for detecting personal contact information
  static final RegExp _phoneNumberRegex = RegExp(
    r'(\+?1[-.\s]?)?(\(?[0-9]{3}\)?[-.\s]?)?[0-9]{3}[-.\s]?[0-9]{4}',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    caseSensitive: false,
  );

  // Patterns for detecting external communication requests
  static final List<RegExp> _externalCommunicationPatterns = [
    RegExp(r'\b(whatsapp|whats app|whats-app)\s+(me|us|him|her)\b', caseSensitive: false),
    RegExp(r'\b(text|txt)\s+(me|us|him|her)\b', caseSensitive: false),
    RegExp(r'\b(call|phone)\s+(me|us|him|her)\b', caseSensitive: false),
    RegExp(r'\b(contact|reach)\s+(me|us|him|her)\s+(directly|outside|offline)\b', caseSensitive: false),
    RegExp(r'\b(dm|direct message|private message)\s+(me|us|him|her)\b', caseSensitive: false),
    RegExp(r'\b(facebook|instagram|twitter|linkedin|snapchat|telegram)\s+(me|us|him|her)\b', caseSensitive: false),
    RegExp(r'\b(send|give)\s+(me|us|him|her)\s+(your|my)\s+(number|phone|email|contact)\b', caseSensitive: false),
    RegExp(r'\b(get|find)\s+(me|us|him|her)\s+(on|at)\s+(whatsapp|facebook|instagram|twitter)\b', caseSensitive: false),
    RegExp(r'\b(meet|see)\s+(me|us|him|her)\s+(outside|offline|in person)\b', caseSensitive: false),
    RegExp(r'\b(avoid|skip)\s+(the|this)\s+(app|platform)\b', caseSensitive: false),
  ];

  /// Filters the given content and returns information about any violations
  FilterResult filterContent(String content) {
    final detectedPatterns = <String>[];
    
    // Check for phone numbers
    if (_phoneNumberRegex.hasMatch(content)) {
      detectedPatterns.add('Phone number detected');
    }

    // Check for email addresses
    if (_emailRegex.hasMatch(content)) {
      detectedPatterns.add('Email address detected');
    }

    // Check for external communication requests
    for (final pattern in _externalCommunicationPatterns) {
      if (pattern.hasMatch(content)) {
        final match = pattern.firstMatch(content);
        if (match != null) {
          detectedPatterns.add('External communication request: "${match.group(0)}"');
        }
      }
    }

    final hasViolations = detectedPatterns.isNotEmpty;
    final warningMessage = hasViolations 
        ? "For your safety, please keep communication within the app. External communication cannot be used in case of disputes."
        : "";

    return FilterResult(
      hasViolations: hasViolations,
      detectedPatterns: detectedPatterns,
      warningMessage: warningMessage,
    );
  }

  /// Checks if content contains any violations without returning detailed information
  bool hasViolations(String content) {
    return _phoneNumberRegex.hasMatch(content) ||
           _emailRegex.hasMatch(content) ||
           _externalCommunicationPatterns.any((pattern) => pattern.hasMatch(content));
  }


  /// Gets detailed information about what was detected in the content
  Map<String, dynamic> getDetailedAnalysis(String content) {
    final phoneMatches = _phoneNumberRegex.allMatches(content).map((m) => m.group(0)).toList();
    final emailMatches = _emailRegex.allMatches(content).map((m) => m.group(0)).toList();
    
    final externalCommMatches = <String>[];
    for (final pattern in _externalCommunicationPatterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        externalCommMatches.add(match.group(0) ?? '');
      }
    }

    return {
      'phoneNumbers': phoneMatches,
      'emailAddresses': emailMatches,
      'externalCommunicationRequests': externalCommMatches,
      'hasViolations': phoneMatches.isNotEmpty || emailMatches.isNotEmpty || externalCommMatches.isNotEmpty,
    };
  }
}
