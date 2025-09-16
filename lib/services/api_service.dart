import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payout_models.dart';

class ApiService {
  static ApiService? _instance;
  final String _baseUrl;
  final Map<String, String> _headers;

  ApiService._()
      : _baseUrl = _getBaseUrl(),
        _headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  static String _getBaseUrl() {
    // In production, this would be your actual backend URL
    // For development, you can use localhost or your development server
    if (kDebugMode) {
      return 'http://localhost:3000/api'; // Development server
    } else {
      return 'https://your-backend-api.com/api'; // Production server
    }
  }

  /// Request cash-out for a service professional
  Future<CashOutResponse> requestCashOut({
    required String professionalId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [ApiService] Sending cash-out request to backend');
      
      final request = CashOutRequest(
        professionalId: professionalId,
        amount: amount,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/cashout'),
        headers: _headers,
        body: jsonEncode({
          ...request.toMap(),
          'metadata': metadata,
        }),
      );

      print('📡 [ApiService] Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CashOutResponse.fromMap(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return CashOutResponse(
          success: false,
          error: errorData['error'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      print('❌ [ApiService] Failed to send cash-out request: $e');
      return CashOutResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Get professional balance from backend
  Future<ProfessionalBalance?> getProfessionalBalance(String professionalId) async {
    try {
      print('🔍 [ApiService] Fetching professional balance from backend');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/professionals/$professionalId/balance'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ProfessionalBalance.fromMap(responseData);
      } else {
        print('❌ [ApiService] Failed to get professional balance: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [ApiService] Failed to get professional balance: $e');
      return null;
    }
  }

  /// Get payout history from backend
  Future<List<Payout>> getPayoutHistory(String professionalId) async {
    try {
      print('🔍 [ApiService] Fetching payout history from backend');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/professionals/$professionalId/payouts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final payoutsList = responseData['payouts'] as List<dynamic>;
        return payoutsList
            .map((payoutData) => Payout.fromMap(payoutData as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ [ApiService] Failed to get payout history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ [ApiService] Failed to get payout history: $e');
      return [];
    }
  }

  /// Get payout by ID from backend
  Future<Payout?> getPayoutById(String payoutId) async {
    try {
      print('🔍 [ApiService] Fetching payout by ID from backend');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/payouts/$payoutId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Payout.fromMap(responseData);
      } else {
        print('❌ [ApiService] Failed to get payout by ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [ApiService] Failed to get payout by ID: $e');
      return null;
    }
  }

  /// Validate cash-out request with backend
  Future<CashOutValidationResult> validateCashOutRequest({
    required String professionalId,
    required double amount,
  }) async {
    try {
      print('🔍 [ApiService] Validating cash-out request with backend');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/cashout/validate'),
        headers: _headers,
        body: jsonEncode({
          'professional_id': professionalId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CashOutValidationResult(
          isValid: responseData['is_valid'] as bool,
          error: responseData['error'] as String?,
          availableBalance: (responseData['available_balance'] as num?)?.toDouble(),
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return CashOutValidationResult(
          isValid: false,
          error: errorData['error'] ?? 'Validation failed',
        );
      }
    } catch (e) {
      print('❌ [ApiService] Failed to validate cash-out request: $e');
      return CashOutValidationResult(
        isValid: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Get cash-out statistics from backend
  Future<CashOutStats> getCashOutStats(String professionalId) async {
    try {
      print('🔍 [ApiService] Fetching cash-out stats from backend');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/professionals/$professionalId/cashout-stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CashOutStats(
          availableBalance: (responseData['available_balance'] as num).toDouble(),
          totalEarned: (responseData['total_earned'] as num).toDouble(),
          totalPaidOut: (responseData['total_paid_out'] as num).toDouble(),
          pendingPayouts: responseData['pending_payouts'] as int,
          completedPayouts: responseData['completed_payouts'] as int,
          failedPayouts: responseData['failed_payouts'] as int,
        );
      } else {
        print('❌ [ApiService] Failed to get cash-out stats: ${response.statusCode}');
        return CashOutStats(
          availableBalance: 0.0,
          totalEarned: 0.0,
          totalPaidOut: 0.0,
          pendingPayouts: 0,
          completedPayouts: 0,
          failedPayouts: 0,
        );
      }
    } catch (e) {
      print('❌ [ApiService] Failed to get cash-out stats: $e');
      return CashOutStats(
        availableBalance: 0.0,
        totalEarned: 0.0,
        totalPaidOut: 0.0,
        pendingPayouts: 0,
        completedPayouts: 0,
        failedPayouts: 0,
      );
    }
  }

  /// Cancel payout request
  Future<bool> cancelPayout(String payoutId) async {
    try {
      print('🔍 [ApiService] Cancelling payout request');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/payouts/$payoutId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        print('✅ [ApiService] Payout cancelled successfully');
        return true;
      } else {
        print('❌ [ApiService] Failed to cancel payout: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [ApiService] Failed to cancel payout: $e');
      return false;
    }
  }

  /// Test backend connectivity
  Future<bool> testConnection() async {
    try {
      print('🔍 [ApiService] Testing backend connectivity');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ [ApiService] Backend connection successful');
        return true;
      } else {
        print('❌ [ApiService] Backend connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [ApiService] Backend connection error: $e');
      return false;
    }
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
    print('🔑 [ApiService] Authentication token set');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _headers.remove('Authorization');
    print('🔑 [ApiService] Authentication token cleared');
  }

  /// Update base URL (for testing or environment switching)
  void updateBaseUrl(String newUrl) {
    _instance = ApiService._();
    print('🔄 [ApiService] Base URL updated to: $newUrl');
  }
}
