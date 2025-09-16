import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/payout_models.dart';
import 'postgres_payment_service.dart';

class PayoutService {
  static PayoutService? _instance;
  final PostgresPaymentService _postgresService;
  final FirebaseFirestore _firestore;

  PayoutService._()
      : _postgresService = PostgresPaymentService.instance,
        _firestore = FirebaseFirestore.instance;

  static PayoutService get instance {
    _instance ??= PayoutService._();
    return _instance!;
  }

  Future<void> initialize() async {
    await _postgresService.initialize();
    print('✅ [PayoutService] Payout Service initialized');
  }

  Future<void> close() async {
    await _postgresService.close();
    print('🔌 [PayoutService] Payout Service closed');
  }

  /// Get professional's current balance
  Future<ProfessionalBalance?> getProfessionalBalance(String professionalId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final result = await connection.execute(
        Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
        parameters: {'professionalId': professionalId}
      );

      if (result.isEmpty) {
        // Create initial balance record if it doesn't exist
        return await _createInitialBalance(professionalId);
      }

      return ProfessionalBalance.fromMap({
        'professional_id': result.first[0],
        'available_balance': result.first[1],
        'total_earned': result.first[2],
        'total_paid_out': result.first[3],
        'last_updated': result.first[4],
        'created_at': result.first[5],
      });
    } catch (e) {
      print('❌ [PayoutService] Failed to get professional balance: $e');
      return null;
    }
  }

  /// Create initial balance record for a professional
  Future<ProfessionalBalance> _createInitialBalance(String professionalId) async {
    try {
      final connection = await _postgresService.getConnection();
      final now = DateTime.now();
      
      await connection.execute(
        Sql.named('''
          INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at)
          VALUES (@professionalId, @availableBalance, @totalEarned, @totalPaidOut, @lastUpdated, @createdAt)
        '''),
        parameters: {
          'professionalId': professionalId,
          'availableBalance': 0.0,
          'totalEarned': 0.0,
          'totalPaidOut': 0.0,
          'lastUpdated': now,
          'createdAt': now,
        }
      );

      return ProfessionalBalance(
        professionalId: professionalId,
        availableBalance: 0.0,
        totalEarned: 0.0,
        totalPaidOut: 0.0,
        lastUpdated: now,
        createdAt: now,
      );
    } catch (e) {
      print('❌ [PayoutService] Failed to create initial balance: $e');
      rethrow;
    }
  }

  /// Request cash-out for a service professional
  Future<CashOutResponse> requestCashOut({
    required String professionalId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [PayoutService] Processing cash-out request for professional: $professionalId, amount: $amount');
      
      // Validate amount
      if (amount <= 0) {
        return CashOutResponse(
          success: false,
          error: 'Amount must be greater than 0',
        );
      }

      // Get professional's current balance
      final balance = await getProfessionalBalance(professionalId);
      if (balance == null) {
        return CashOutResponse(
          success: false,
          error: 'Failed to retrieve professional balance',
        );
      }

      // Check if professional has sufficient balance
      if (balance.availableBalance < amount) {
        return CashOutResponse(
          success: false,
          error: 'Insufficient balance. Available: ${balance.availableBalance}, Requested: $amount',
        );
      }

      // Create payout record
      final payout = await _createPayoutRecord(
        professionalId: professionalId,
        amount: amount,
        metadata: metadata,
      );

      // Process payout through payment processor
      final payoutResult = await _processPayoutWithPaymentProcessor(payout);

      if (payoutResult.success) {
        // Update payout status to success
        await _updatePayoutStatus(
          payoutId: payout.id,
          status: PayoutStatus.success,
          paymentProcessorTransactionId: payoutResult.transactionId,
          paymentProcessorResponse: payoutResult.response,
        );

        // Update professional balance - reduce available balance and increase total paid out
        await _updateBalanceOnCashOut(professionalId, amount);

        // Sync to Firebase
        await _syncPayoutToFirebase(payout.copyWith(
          status: PayoutStatus.success,
          paymentProcessorTransactionId: payoutResult.transactionId,
          paymentProcessorResponse: payoutResult.response,
          completedAt: DateTime.now(),
        ));

        // Update professional balance in Firebase
        await _syncProfessionalBalanceToFirebase(professionalId);

        print('✅ [PayoutService] Cash-out processed successfully: ${payout.id}');
        return CashOutResponse(
          success: true,
          message: 'Cash-out processed successfully',
          payout: payout.copyWith(
            status: PayoutStatus.success,
            paymentProcessorTransactionId: payoutResult.transactionId,
            paymentProcessorResponse: payoutResult.response,
            completedAt: DateTime.now(),
          ),
        );
      } else {
        // Update payout status to failed
        await _updatePayoutStatus(
          payoutId: payout.id,
          status: PayoutStatus.failed,
          errorMessage: payoutResult.error,
        );

        // Sync to Firebase
        await _syncPayoutToFirebase(payout.copyWith(
          status: PayoutStatus.failed,
          errorMessage: payoutResult.error,
          completedAt: DateTime.now(),
        ));

        print('❌ [PayoutService] Cash-out failed: ${payoutResult.error}');
        return CashOutResponse(
          success: false,
          error: payoutResult.error,
          payout: payout.copyWith(
            status: PayoutStatus.failed,
            errorMessage: payoutResult.error,
            completedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('❌ [PayoutService] Failed to process cash-out request: $e');
      return CashOutResponse(
        success: false,
        error: 'Internal server error: $e',
      );
    }
  }

  /// Create payout record in database
  Future<Payout> _createPayoutRecord({
    required String professionalId,
    required double amount,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final connection = await _postgresService.getConnection();
      final payoutId = const Uuid().v4();
      final now = DateTime.now();

      await connection.execute(
        Sql.named('''
          INSERT INTO payouts (
            id, professional_id, amount, currency, status, created_at, metadata
          ) VALUES (
            @id, @professionalId, @amount, @currency, @status, @createdAt, @metadata
          )
        '''),
        parameters: {
          'id': payoutId,
          'professionalId': professionalId,
          'amount': amount,
          'currency': 'JMD',
          'status': PayoutStatus.pending.name,
          'createdAt': now,
          'metadata': metadata != null ? metadata.toString() : null,
        }
      );

      return Payout(
        id: payoutId,
        professionalId: professionalId,
        amount: amount,
        currency: 'JMD',
        status: PayoutStatus.pending,
        createdAt: now,
        metadata: metadata,
      );
    } catch (e) {
      print('❌ [PayoutService] Failed to create payout record: $e');
      rethrow;
    }
  }

  /// Process payout through payment processor (placeholder implementation)
  Future<PayoutProcessorResult> _processPayoutWithPaymentProcessor(Payout payout) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if payment processor is configured
      final isConfigured = await _isPaymentProcessorConfigured();
      
      if (!isConfigured) {
        // Simulate successful payout for development
        return PayoutProcessorResult(
          success: true,
          transactionId: 'MOCK_${DateTime.now().millisecondsSinceEpoch}',
          response: {
            'status': 'success',
            'transaction_id': 'MOCK_${DateTime.now().millisecondsSinceEpoch}',
            'amount': payout.amount,
            'currency': payout.currency,
            'processed_at': DateTime.now().toIso8601String(),
            'processor': 'mock',
          },
        );
      }

      // TODO: Implement actual payment processor API call
      // This would be where you integrate with Stripe, PayPal, etc.
      throw UnimplementedError('Payment processor integration not implemented');

    } catch (e) {
      print('❌ [PayoutService] Payment processor error: $e');
      return PayoutProcessorResult(
        success: false,
        error: 'Payment processor error: $e',
      );
    }
  }

  /// Check if payment processor is configured
  Future<bool> _isPaymentProcessorConfigured() async {
    // Check for environment variables or configuration
    // For now, return false to use mock processing
    return false;
  }

  /// Update payout status in database
  Future<void> _updatePayoutStatus({
    required String payoutId,
    required PayoutStatus status,
    String? paymentProcessorTransactionId,
    Map<String, dynamic>? paymentProcessorResponse,
    String? errorMessage,
  }) async {
    try {
      final connection = await _postgresService.getConnection();
      final now = DateTime.now();

      await connection.execute(
        Sql.named('''
          UPDATE payouts 
          SET status = @status, 
              payment_processor_transaction_id = @transactionId,
              payment_processor_response = @response,
              completed_at = @completedAt,
              error_message = @errorMessage
          WHERE id = @payoutId
        '''),
        parameters: {
          'payoutId': payoutId,
          'status': status.name,
          'transactionId': paymentProcessorTransactionId,
          'response': paymentProcessorResponse != null ? paymentProcessorResponse.toString() : null,
          'completedAt': status != PayoutStatus.pending ? now : null,
          'errorMessage': errorMessage,
        }
      );

      print('✅ [PayoutService] Updated payout status: $payoutId -> ${status.name}');
    } catch (e) {
      print('❌ [PayoutService] Failed to update payout status: $e');
      rethrow;
    }
  }

  /// Get payout history for a professional
  Future<List<Payout>> getPayoutHistory(String professionalId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final result = await connection.execute(
        Sql.named('''
          SELECT * FROM payouts 
          WHERE professional_id = @professionalId 
          ORDER BY created_at DESC
        '''),
        parameters: {'professionalId': professionalId}
      );

      return result.map((row) => Payout.fromMap({
        'id': row[0],
        'professional_id': row[1],
        'amount': row[2],
        'currency': row[3],
        'status': row[4],
        'payment_processor_transaction_id': row[5],
        'payment_processor_response': row[6],
        'created_at': row[7],
        'completed_at': row[8],
        'error_message': row[9],
        'metadata': row[10],
      })).toList();
    } catch (e) {
      print('❌ [PayoutService] Failed to get payout history: $e');
      return [];
    }
  }

  /// Get payout by ID
  Future<Payout?> getPayoutById(String payoutId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final result = await connection.execute(
        Sql.named('SELECT * FROM payouts WHERE id = @payoutId'),
        parameters: {'payoutId': payoutId}
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return Payout.fromMap({
        'id': row[0],
        'professional_id': row[1],
        'amount': row[2],
        'currency': row[3],
        'status': row[4],
        'payment_processor_transaction_id': row[5],
        'payment_processor_response': row[6],
        'created_at': row[7],
        'completed_at': row[8],
        'error_message': row[9],
        'metadata': row[10],
      });
    } catch (e) {
      print('❌ [PayoutService] Failed to get payout by ID: $e');
      return null;
    }
  }

  /// Sync payout to Firebase
  Future<void> _syncPayoutToFirebase(Payout payout) async {
    try {
      await _firestore
          .collection('payouts')
          .doc(payout.id)
          .set(payout.toFirestoreMap());
      
      print('✅ [PayoutService] Synced payout to Firebase: ${payout.id}');
    } catch (e) {
      print('❌ [PayoutService] Failed to sync payout to Firebase: $e');
    }
  }

  /// Sync professional balance to Firebase
  Future<void> _syncProfessionalBalanceToFirebase(String professionalId) async {
    try {
      final balance = await getProfessionalBalance(professionalId);
      if (balance != null) {
        await _firestore
            .collection('professional_balances')
            .doc(professionalId)
            .set(balance.toFirestoreMap());
        
        print('✅ [PayoutService] Synced professional balance to Firebase: $professionalId');
      }
    } catch (e) {
      print('❌ [PayoutService] Failed to sync professional balance to Firebase: $e');
    }
  }

  /// Get payout stream for real-time updates
  Stream<List<Payout>> getPayoutsStream(String professionalId) {
    return _firestore
        .collection('payouts')
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payout.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get professional balance stream for real-time updates
  Stream<ProfessionalBalance?> getProfessionalBalanceStream(String professionalId) {
    return _firestore
        .collection('professional_balances')
        .doc(professionalId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return ProfessionalBalance.fromFirestore(snapshot.data()!, snapshot.id);
        });
  }

  /// Update professional balance (called when payment is completed)
  Future<void> updateProfessionalBalanceOnPayment({
    required String professionalId,
    required double amount,
  }) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      final now = DateTime.now();

      // Get current balance to calculate new values
      final currentBalance = await getProfessionalBalance(professionalId);
      final currentAvailableBalance = currentBalance?.availableBalance ?? 0.0;
      final currentTotalEarned = currentBalance?.totalEarned ?? 0.0;

      await connection.execute(
        Sql.named('''
          INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at)
          VALUES (@professionalId, @availableBalance, @totalEarned, @totalPaidOut, @lastUpdated, @createdAt)
          ON CONFLICT (professional_id) 
          DO UPDATE SET
            available_balance = @availableBalance,
            total_earned = @totalEarned,
            last_updated = @lastUpdated
        '''),
        parameters: {
          'professionalId': professionalId,
          'availableBalance': currentAvailableBalance + amount,
          'totalEarned': currentTotalEarned + amount,
          'totalPaidOut': currentBalance?.totalPaidOut ?? 0.0,
          'lastUpdated': now,
          'createdAt': now,
        }
      );

      // Sync to Firebase
      await _syncProfessionalBalanceToFirebase(professionalId);

      print('✅ [PayoutService] Updated professional balance: $professionalId +$amount (Available: ${currentAvailableBalance + amount}, Total Earned: ${currentTotalEarned + amount})');
    } catch (e) {
      print('❌ [PayoutService] Failed to update professional balance: $e');
    }
  }

  /// Update professional balance when cash-out is processed
  Future<void> _updateBalanceOnCashOut(String professionalId, double amount) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      final now = DateTime.now();

      // Get current balance to calculate new values
      final currentBalance = await getProfessionalBalance(professionalId);
      final currentAvailableBalance = currentBalance?.availableBalance ?? 0.0;
      final currentTotalPaidOut = currentBalance?.totalPaidOut ?? 0.0;

      await connection.execute(
        Sql.named('''
          UPDATE professional_balances 
          SET available_balance = @availableBalance,
              total_paid_out = @totalPaidOut,
              last_updated = @lastUpdated
          WHERE professional_id = @professionalId
        '''),
        parameters: {
          'professionalId': professionalId,
          'availableBalance': currentAvailableBalance - amount,
          'totalPaidOut': currentTotalPaidOut + amount,
          'lastUpdated': now,
        }
      );

      print('✅ [PayoutService] Updated balance on cash-out: $professionalId -$amount (Available: ${currentAvailableBalance - amount}, Total Paid Out: ${currentTotalPaidOut + amount})');
    } catch (e) {
      print('❌ [PayoutService] Failed to update balance on cash-out: $e');
    }
  }

  /// Get all professional balances from PostgreSQL
  Future<List<ProfessionalBalance>> getAllProfessionalBalances() async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final result = await connection.execute(
        Sql.named('SELECT * FROM professional_balances ORDER BY last_updated DESC')
      );

      return result.map((row) => ProfessionalBalance.fromMap({
        'professional_id': row[0],
        'available_balance': row[1],
        'total_earned': row[2],
        'total_paid_out': row[3],
        'last_updated': row[4],
        'created_at': row[5],
      })).toList();
    } catch (e) {
      print('❌ [PayoutService] Failed to get all professional balances: $e');
      return [];
    }
  }

  /// Update professional balance manually in PostgreSQL
  Future<bool> updateProfessionalBalanceManually({
    required String professionalId,
    required double availableBalance,
    required double totalEarned,
    required double totalPaidOut,
  }) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      final now = DateTime.now();

      await connection.execute(
        Sql.named('''
          INSERT INTO professional_balances (professional_id, available_balance, total_earned, total_paid_out, last_updated, created_at)
          VALUES (@professionalId, @availableBalance, @totalEarned, @totalPaidOut, @lastUpdated, @createdAt)
          ON CONFLICT (professional_id) 
          DO UPDATE SET
            available_balance = @availableBalance,
            total_earned = @totalEarned,
            total_paid_out = @totalPaidOut,
            last_updated = @lastUpdated
        '''),
        parameters: {
          'professionalId': professionalId,
          'availableBalance': availableBalance,
          'totalEarned': totalEarned,
          'totalPaidOut': totalPaidOut,
          'lastUpdated': now,
          'createdAt': now,
        }
      );

      // Sync to Firebase
      await _syncProfessionalBalanceToFirebase(professionalId);

      print('✅ [PayoutService] Updated professional balance manually: $professionalId');
      return true;
    } catch (e) {
      print('❌ [PayoutService] Failed to update professional balance manually: $e');
      return false;
    }
  }

  /// Get balance statistics and analytics
  Future<Map<String, dynamic>> getBalanceStatistics() async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      // Get total statistics
      final totalResult = await connection.execute(
        Sql.named('''
          SELECT 
            COUNT(*) as total_professionals,
            SUM(available_balance) as total_available_balance,
            SUM(total_earned) as total_earned,
            SUM(total_paid_out) as total_paid_out,
            AVG(available_balance) as avg_available_balance,
            AVG(total_earned) as avg_total_earned
          FROM professional_balances
        ''')
      );

      // Get top earners
      final topEarnersResult = await connection.execute(
        Sql.named('''
          SELECT professional_id, total_earned, available_balance
          FROM professional_balances
          ORDER BY total_earned DESC
          LIMIT 10
        ''')
      );

      // Get recent activity (last 30 days)
      final recentActivityResult = await connection.execute(
        Sql.named('''
          SELECT 
            COUNT(*) as recent_payouts,
            SUM(amount) as recent_payout_amount
          FROM payouts
          WHERE created_at >= NOW() - INTERVAL '30 days'
        ''')
      );

      final totalStats = totalResult.isNotEmpty ? totalResult.first : [];
      final recentStats = recentActivityResult.isNotEmpty ? recentActivityResult.first : [];

      return {
        'total_professionals': totalStats.isNotEmpty ? totalStats[0] : 0,
        'total_available_balance': totalStats.isNotEmpty ? (totalStats[1] as num).toDouble() : 0.0,
        'total_earned': totalStats.isNotEmpty ? (totalStats[2] as num).toDouble() : 0.0,
        'total_paid_out': totalStats.isNotEmpty ? (totalStats[3] as num).toDouble() : 0.0,
        'avg_available_balance': totalStats.isNotEmpty ? (totalStats[4] as num).toDouble() : 0.0,
        'avg_total_earned': totalStats.isNotEmpty ? (totalStats[5] as num).toDouble() : 0.0,
        'top_earners': topEarnersResult.map((row) => {
          'professional_id': row[0],
          'total_earned': (row[1] as num).toDouble(),
          'available_balance': (row[2] as num).toDouble(),
        }).toList(),
        'recent_payouts': recentStats.isNotEmpty ? recentStats[0] : 0,
        'recent_payout_amount': recentStats.isNotEmpty ? (recentStats[1] as num).toDouble() : 0.0,
      };
    } catch (e) {
      print('❌ [PayoutService] Failed to get balance statistics: $e');
      return {};
    }
  }

  /// Validate cash-out request against PostgreSQL balance
  Future<Map<String, dynamic>> validateCashOutRequest({
    required String professionalId,
    required double amount,
  }) async {
    try {
      // Get professional balance
      final balance = await getProfessionalBalance(professionalId);
      if (balance == null) {
        return {
          'is_valid': false,
          'error': 'Professional not found',
        };
      }

      // Check minimum amount
      if (amount < 10) {
        return {
          'is_valid': false,
          'error': 'Minimum cash-out amount is \$10',
        };
      }

      // Check maximum amount
      if (amount > 10000) {
        return {
          'is_valid': false,
          'error': 'Maximum cash-out amount is \$10,000',
        };
      }

      // Check sufficient balance
      if (balance.availableBalance < amount) {
        return {
          'is_valid': false,
          'error': 'Insufficient balance. Available: \$${balance.availableBalance.toStringAsFixed(2)}',
        };
      }

      // Check for pending payouts
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final pendingResult = await connection.execute(
        Sql.named('''
          SELECT COUNT(*) FROM payouts 
          WHERE professional_id = @professionalId AND status = @status
        '''),
        parameters: {
          'professionalId': professionalId,
          'status': 'pending',
        }
      );

      final pendingCount = pendingResult.isNotEmpty ? pendingResult.first[0] as int : 0;
      if (pendingCount > 0) {
        return {
          'is_valid': false,
          'error': 'You have a pending cash-out request. Please wait for it to be processed.',
        };
      }

      return {
        'is_valid': true,
        'available_balance': balance.availableBalance,
      };
    } catch (e) {
      print('❌ [PayoutService] Failed to validate cash-out request: $e');
      return {
        'is_valid': false,
        'error': 'Validation error: $e',
      };
    }
  }

  /// Get payout history from PostgreSQL with optional limit
  Future<List<Payout>> getPayoutHistoryWithLimit(String professionalId, {int? limit}) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final limitClause = limit != null ? 'LIMIT $limit' : '';
      final result = await connection.execute(
        Sql.named('''
          SELECT * FROM payouts 
          WHERE professional_id = @professionalId 
          ORDER BY created_at DESC 
          $limitClause
        '''),
        parameters: {'professionalId': professionalId}
      );

      return result.map((row) => Payout.fromMap({
        'id': row[0],
        'professional_id': row[1],
        'amount': row[2],
        'currency': row[3],
        'status': row[4],
        'payment_processor_transaction_id': row[5],
        'payment_processor_response': row[6],
        'created_at': row[7],
        'completed_at': row[8],
        'error_message': row[9],
        'metadata': row[10],
      })).toList();
    } catch (e) {
      print('❌ [PayoutService] Failed to get payout history: $e');
      return [];
    }
  }

  /// Cancel payout in PostgreSQL
  Future<bool> cancelPayout(String payoutId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      final result = await connection.execute(
        Sql.named('''
          UPDATE payouts 
          SET status = @status 
          WHERE id = @payoutId AND status = @pendingStatus
          RETURNING id
        '''),
        parameters: {
          'status': 'cancelled',
          'payoutId': payoutId,
          'pendingStatus': 'pending',
        }
      );

      if (result.isEmpty) {
        print('❌ [PayoutService] Payout not found or cannot be cancelled: $payoutId');
        return false;
      }

      print('✅ [PayoutService] Payout cancelled successfully: $payoutId');
      return true;
    } catch (e) {
      print('❌ [PayoutService] Failed to cancel payout: $e');
      return false;
    }
  }

  /// Get cash-out statistics from PostgreSQL
  Future<Map<String, dynamic>> getCashOutStatistics(String professionalId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      
      // Get balance info
      final balanceResult = await connection.execute(
        Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
        parameters: {'professionalId': professionalId}
      );

      if (balanceResult.isEmpty) {
        return {
          'available_balance': 0.0,
          'total_earned': 0.0,
          'total_paid_out': 0.0,
          'pending_payouts': 0,
          'completed_payouts': 0,
          'failed_payouts': 0,
        };
      }

      final balance = balanceResult.first;

      // Get payout counts by status
      final statsResult = await connection.execute(
        Sql.named('''
          SELECT status, COUNT(*) 
          FROM payouts 
          WHERE professional_id = @professionalId 
          GROUP BY status
        '''),
        parameters: {'professionalId': professionalId}
      );

      final stats = {
        'pending': 0,
        'success': 0,
        'failed': 0,
        'cancelled': 0,
      };

      for (final row in statsResult) {
        final status = row[0] as String;
        final count = row[1] as int;
        stats[status] = count;
      }

      return {
        'available_balance': (balance[1] as num).toDouble(),
        'total_earned': (balance[2] as num).toDouble(),
        'total_paid_out': (balance[3] as num).toDouble(),
        'pending_payouts': stats['pending']!,
        'completed_payouts': stats['success']!,
        'failed_payouts': stats['failed']!,
        'cancelled_payouts': stats['cancelled']!,
      };
    } catch (e) {
      print('❌ [PayoutService] Failed to get cash-out statistics: $e');
      return {};
    }
  }

  /// Sync balance data between PostgreSQL and Firebase
  Future<void> syncAllBalancesToFirebase() async {
    try {
      print('🔄 [PayoutService] Starting sync of all balances to Firebase...');
      
      final balances = await getAllProfessionalBalances();
      int syncedCount = 0;
      
      for (final balance in balances) {
        try {
          await _firestore
              .collection('professional_balances')
              .doc(balance.professionalId)
              .set(balance.toFirestoreMap());
          syncedCount++;
        } catch (e) {
          print('❌ [PayoutService] Failed to sync balance for ${balance.professionalId}: $e');
        }
      }
      
      print('✅ [PayoutService] Synced $syncedCount balances to Firebase');
    } catch (e) {
      print('❌ [PayoutService] Failed to sync all balances to Firebase: $e');
    }
  }

  /// Sync balance data from Firebase to PostgreSQL
  Future<void> syncAllBalancesFromFirebase() async {
    try {
      print('🔄 [PayoutService] Starting sync of all balances from Firebase...');
      
      final snapshot = await _firestore.collection('professional_balances').get();
      int syncedCount = 0;
      
      for (final doc in snapshot.docs) {
        try {
          final balance = ProfessionalBalance.fromFirestore(doc.data(), doc.id);
          await updateProfessionalBalanceManually(
            professionalId: balance.professionalId,
            availableBalance: balance.availableBalance,
            totalEarned: balance.totalEarned,
            totalPaidOut: balance.totalPaidOut,
          );
          syncedCount++;
        } catch (e) {
          print('❌ [PayoutService] Failed to sync balance for ${doc.id}: $e');
        }
      }
      
      print('✅ [PayoutService] Synced $syncedCount balances from Firebase to PostgreSQL');
    } catch (e) {
      print('❌ [PayoutService] Failed to sync all balances from Firebase: $e');
    }
  }
}

/// Result from payment processor
class PayoutProcessorResult {
  final bool success;
  final String? transactionId;
  final Map<String, dynamic>? response;
  final String? error;

  PayoutProcessorResult({
    required this.success,
    this.transactionId,
    this.response,
    this.error,
  });
}
