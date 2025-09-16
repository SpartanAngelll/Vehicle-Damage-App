import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_models.dart';
import '../models/banking_details.dart';
import 'payout_service.dart';
import 'banking_details_service.dart';

class CashOutService {
  static CashOutService? _instance;
  final PayoutService _payoutService;
  final FirebaseFirestore _firestore;

  CashOutService._()
      : _payoutService = PayoutService.instance,
        _firestore = FirebaseFirestore.instance;

  static CashOutService get instance {
    _instance ??= CashOutService._();
    return _instance!;
  }

  Future<void> initialize() async {
    await _payoutService.initialize();
    print('✅ [CashOutService] Cash Out Service initialized');
  }

  /// Get professional's current balance
  Future<ProfessionalBalance?> getProfessionalBalance(String professionalId) async {
    try {
      return await _payoutService.getProfessionalBalance(professionalId);
    } catch (e) {
      print('❌ [CashOutService] Failed to get professional balance: $e');
      return null;
    }
  }

  /// Request cash-out for a service professional
  Future<CashOutResponse> requestCashOut({
    required String professionalId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [CashOutService] Requesting cash-out for professional: $professionalId, amount: $amount');
      
      // Validate amount
      if (amount <= 0) {
        return CashOutResponse(
          success: false,
          error: 'Amount must be greater than 0',
        );
      }

      // Check if amount is reasonable (e.g., minimum $10, maximum $10,000)
      if (amount < 10) {
        return CashOutResponse(
          success: false,
          error: 'Minimum cash-out amount is \$10',
        );
      }

      if (amount > 10000) {
        return CashOutResponse(
          success: false,
          error: 'Maximum cash-out amount is \$10,000',
        );
      }

      // Check if professional has valid banking details
      final hasValidBankingDetails = await _hasValidBankingDetails(professionalId);
      if (!hasValidBankingDetails) {
        return CashOutResponse(
          success: false,
          error: 'Valid banking details not found. Please add your banking details in Settings before requesting a cash-out.',
        );
      }

      // Get current balance to validate
      final balance = await getProfessionalBalance(professionalId);
      if (balance == null) {
        return CashOutResponse(
          success: false,
          error: 'Failed to retrieve balance information',
        );
      }

      if (balance.availableBalance < amount) {
        return CashOutResponse(
          success: false,
          error: 'Insufficient balance. Available: \$${balance.availableBalance.toStringAsFixed(2)}, Requested: \$${amount.toStringAsFixed(2)}',
        );
      }

      // Process cash-out request
      final response = await _payoutService.requestCashOut(
        professionalId: professionalId,
        amount: amount,
        metadata: metadata,
      );

      if (response.success) {
        print('✅ [CashOutService] Cash-out request successful: ${response.payout?.id}');
      } else {
        print('❌ [CashOutService] Cash-out request failed: ${response.error}');
      }

      return response;
    } catch (e) {
      print('❌ [CashOutService] Failed to request cash-out: $e');
      return CashOutResponse(
        success: false,
        error: 'Failed to process cash-out request: $e',
      );
    }
  }

  /// Get payout history for a professional
  Future<List<Payout>> getPayoutHistory(String professionalId) async {
    try {
      return await _payoutService.getPayoutHistory(professionalId);
    } catch (e) {
      print('❌ [CashOutService] Failed to get payout history: $e');
      return [];
    }
  }

  /// Get banking details for a professional
  Future<BankingDetails?> getBankingDetails(String professionalId) async {
    try {
      return await BankingDetailsService.instance.getBankingDetails(professionalId);
    } catch (e) {
      print('❌ [CashOutService] Failed to get banking details: $e');
      return null;
    }
  }

  /// Check if professional has valid banking details
  Future<bool> _hasValidBankingDetails(String professionalId) async {
    try {
      final bankingDetails = await getBankingDetails(professionalId);
      return bankingDetails != null && bankingDetails.isComplete && bankingDetails.isActive;
    } catch (e) {
      print('❌ [CashOutService] Failed to check banking details: $e');
      return false;
    }
  }

  /// Get payout by ID
  Future<Payout?> getPayoutById(String payoutId) async {
    try {
      return await _payoutService.getPayoutById(payoutId);
    } catch (e) {
      print('❌ [CashOutService] Failed to get payout by ID: $e');
      return null;
    }
  }

  /// Get payout stream for real-time updates
  Stream<List<Payout>> getPayoutsStream(String professionalId) {
    return _payoutService.getPayoutsStream(professionalId);
  }

  /// Get professional balance stream for real-time updates
  Stream<ProfessionalBalance?> getProfessionalBalanceStream(String professionalId) {
    return _payoutService.getProfessionalBalanceStream(professionalId);
  }

  /// Check if professional can request cash-out
  Future<CashOutValidationResult> validateCashOutRequest({
    required String professionalId,
    required double amount,
  }) async {
    try {
      // Get current balance
      final balance = await getProfessionalBalance(professionalId);
      if (balance == null) {
        return CashOutValidationResult(
          isValid: false,
          error: 'Failed to retrieve balance information',
        );
      }

      // Check if professional has any available balance
      if (balance.availableBalance <= 0) {
        return CashOutValidationResult(
          isValid: false,
          error: 'No available balance for cash-out',
        );
      }

      // Check if amount is valid
      if (amount <= 0) {
        return CashOutValidationResult(
          isValid: false,
          error: 'Amount must be greater than 0',
        );
      }

      // Check minimum amount
      if (amount < 10) {
        return CashOutValidationResult(
          isValid: false,
          error: 'Minimum cash-out amount is \$10',
        );
      }

      // Check maximum amount
      if (amount > 10000) {
        return CashOutValidationResult(
          isValid: false,
          error: 'Maximum cash-out amount is \$10,000',
        );
      }

      // Check if amount exceeds available balance
      if (amount > balance.availableBalance) {
        return CashOutValidationResult(
          isValid: false,
          error: 'Insufficient balance. Available: \$${balance.availableBalance.toStringAsFixed(2)}',
        );
      }

      // Check if there are any pending payouts
      final pendingPayouts = await _getPendingPayouts(professionalId);
      if (pendingPayouts.isNotEmpty) {
        return CashOutValidationResult(
          isValid: false,
          error: 'You have a pending cash-out request. Please wait for it to be processed.',
        );
      }

      return CashOutValidationResult(
        isValid: true,
        availableBalance: balance.availableBalance,
      );
    } catch (e) {
      print('❌ [CashOutService] Failed to validate cash-out request: $e');
      return CashOutValidationResult(
        isValid: false,
        error: 'Failed to validate request: $e',
      );
    }
  }

  /// Get pending payouts for a professional
  Future<List<Payout>> _getPendingPayouts(String professionalId) async {
    try {
      final allPayouts = await getPayoutHistory(professionalId);
      return allPayouts.where((payout) => payout.isPending).toList();
    } catch (e) {
      print('❌ [CashOutService] Failed to get pending payouts: $e');
      return [];
    }
  }

  /// Get cash-out statistics for a professional
  Future<CashOutStats> getCashOutStats(String professionalId) async {
    try {
      final balance = await getProfessionalBalance(professionalId);
      final allPayouts = await getPayoutHistory(professionalId);
      
      if (balance == null) {
        return CashOutStats(
          availableBalance: 0.0,
          totalEarned: 0.0,
          totalPaidOut: 0.0,
          pendingPayouts: 0,
          completedPayouts: 0,
          failedPayouts: 0,
        );
      }

      final pendingPayouts = allPayouts.where((p) => p.isPending).length;
      final completedPayouts = allPayouts.where((p) => p.isSuccess).length;
      final failedPayouts = allPayouts.where((p) => p.isFailed).length;

      return CashOutStats(
        availableBalance: balance.availableBalance,
        totalEarned: balance.totalEarned,
        totalPaidOut: balance.totalPaidOut,
        pendingPayouts: pendingPayouts,
        completedPayouts: completedPayouts,
        failedPayouts: failedPayouts,
      );
    } catch (e) {
      print('❌ [CashOutService] Failed to get cash-out stats: $e');
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

  /// Cancel a pending payout (if allowed)
  Future<bool> cancelPayout(String payoutId) async {
    try {
      // Get the payout
      final payout = await getPayoutById(payoutId);
      if (payout == null) {
        print('❌ [CashOutService] Payout not found: $payoutId');
        return false;
      }

      if (!payout.isPending) {
        print('❌ [CashOutService] Cannot cancel payout that is not pending: ${payout.status}');
        return false;
      }

      // TODO: Implement payout cancellation logic
      // This would typically involve updating the payout status to cancelled
      // and potentially refunding any processing fees
      
      print('⚠️ [CashOutService] Payout cancellation not implemented yet');
      return false;
    } catch (e) {
      print('❌ [CashOutService] Failed to cancel payout: $e');
      return false;
    }
  }

  /// Get recent payouts for dashboard
  Future<List<Payout>> getRecentPayouts(String professionalId, {int limit = 5}) async {
    try {
      final allPayouts = await getPayoutHistory(professionalId);
      return allPayouts.take(limit).toList();
    } catch (e) {
      print('❌ [CashOutService] Failed to get recent payouts: $e');
      return [];
    }
  }

  /// Format amount for display
  String formatAmount(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date for display
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get status display text
  String getStatusDisplayText(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return 'Processing';
      case PayoutStatus.success:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
    }
  }

  /// Get status color
  String getStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.pending:
        return '#FFA500'; // Orange
      case PayoutStatus.success:
        return '#4CAF50'; // Green
      case PayoutStatus.failed:
        return '#F44336'; // Red
    }
  }
}

/// Cash-out validation result
class CashOutValidationResult {
  final bool isValid;
  final String? error;
  final double? availableBalance;

  CashOutValidationResult({
    required this.isValid,
    this.error,
    this.availableBalance,
  });
}

