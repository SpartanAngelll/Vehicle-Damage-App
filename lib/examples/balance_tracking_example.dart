import '../services/payout_service.dart';
import '../services/firebase_firestore_service.dart';
import '../models/payout_models.dart';

/// Example demonstrating how to use the professional balance tracking methods
class BalanceTrackingExample {
  final PayoutService _payoutService = PayoutService.instance;
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Example: Get all professional balances from PostgreSQL
  Future<void> getAllBalancesExample() async {
    print('🔍 Getting all professional balances from PostgreSQL...');
    
    final balances = await _payoutService.getAllProfessionalBalances();
    
    print('📊 Found ${balances.length} professional balances:');
    for (final balance in balances) {
      print('  - Professional: ${balance.professionalId}');
      print('    Available: \$${balance.availableBalance.toStringAsFixed(2)}');
      print('    Total Earned: \$${balance.totalEarned.toStringAsFixed(2)}');
      print('    Total Paid Out: \$${balance.totalPaidOut.toStringAsFixed(2)}');
      print('    Last Updated: ${balance.lastUpdated}');
      print('');
    }
  }

  /// Example: Update professional balance manually
  Future<void> updateBalanceExample(String professionalId) async {
    print('🔧 Updating professional balance manually...');
    
    final success = await _payoutService.updateProfessionalBalanceManually(
      professionalId: professionalId,
      availableBalance: 150.00,
      totalEarned: 500.00,
      totalPaidOut: 350.00,
    );
    
    if (success) {
      print('✅ Balance updated successfully');
    } else {
      print('❌ Failed to update balance');
    }
  }

  /// Example: Get balance statistics and analytics
  Future<void> getStatisticsExample() async {
    print('📈 Getting balance statistics...');
    
    final stats = await _payoutService.getBalanceStatistics();
    
    print('📊 Balance Statistics:');
    print('  Total Professionals: ${stats['total_professionals']}');
    print('  Total Available Balance: \$${stats['total_available_balance'].toStringAsFixed(2)}');
    print('  Total Earned: \$${stats['total_earned'].toStringAsFixed(2)}');
    print('  Total Paid Out: \$${stats['total_paid_out'].toStringAsFixed(2)}');
    print('  Average Available Balance: \$${stats['avg_available_balance'].toStringAsFixed(2)}');
    print('  Average Total Earned: \$${stats['avg_total_earned'].toStringAsFixed(2)}');
    print('  Recent Payouts (30 days): ${stats['recent_payouts']}');
    print('  Recent Payout Amount: \$${stats['recent_payout_amount'].toStringAsFixed(2)}');
    
    print('\n🏆 Top Earners:');
    final topEarners = stats['top_earners'] as List;
    for (int i = 0; i < topEarners.length && i < 5; i++) {
      final earner = topEarners[i];
      print('  ${i + 1}. Professional: ${earner['professional_id']}');
      print('     Total Earned: \$${earner['total_earned'].toStringAsFixed(2)}');
      print('     Available: \$${earner['available_balance'].toStringAsFixed(2)}');
    }
  }

  /// Example: Validate cash-out request
  Future<void> validateCashOutExample(String professionalId, double amount) async {
    print('🔍 Validating cash-out request...');
    
    final validation = await _payoutService.validateCashOutRequest(
      professionalId: professionalId,
      amount: amount,
    );
    
    if (validation['is_valid']) {
      print('✅ Cash-out request is valid');
      print('   Available Balance: \$${validation['available_balance'].toStringAsFixed(2)}');
    } else {
      print('❌ Cash-out request is invalid: ${validation['error']}');
    }
  }

  /// Example: Get payout history
  Future<void> getPayoutHistoryExample(String professionalId) async {
    print('📋 Getting payout history...');
    
    final payouts = await _payoutService.getPayoutHistoryWithLimit(professionalId, limit: 10);
    
    print('📊 Found ${payouts.length} payouts:');
    for (final payout in payouts) {
      print('  - Payout ID: ${payout.id}');
      print('    Amount: \$${payout.amount.toStringAsFixed(2)} ${payout.currency}');
      print('    Status: ${payout.status.name}');
      print('    Created: ${payout.createdAt}');
      if (payout.completedAt != null) {
        print('    Completed: ${payout.completedAt}');
      }
      print('');
    }
  }

  /// Example: Get cash-out statistics for a professional
  Future<void> getCashOutStatsExample(String professionalId) async {
    print('📊 Getting cash-out statistics...');
    
    final stats = await _payoutService.getCashOutStatistics(professionalId);
    
    print('📈 Cash-out Statistics for Professional: $professionalId');
    print('  Available Balance: \$${stats['available_balance'].toStringAsFixed(2)}');
    print('  Total Earned: \$${stats['total_earned'].toStringAsFixed(2)}');
    print('  Total Paid Out: \$${stats['total_paid_out'].toStringAsFixed(2)}');
    print('  Pending Payouts: ${stats['pending_payouts']}');
    print('  Completed Payouts: ${stats['completed_payouts']}');
    print('  Failed Payouts: ${stats['failed_payouts']}');
    print('  Cancelled Payouts: ${stats['cancelled_payouts']}');
  }

  /// Example: Sync balances between PostgreSQL and Firebase
  Future<void> syncBalancesExample() async {
    print('🔄 Syncing balances between PostgreSQL and Firebase...');
    
    // Sync from PostgreSQL to Firebase
    await _payoutService.syncAllBalancesToFirebase();
    
    // Sync from Firebase to PostgreSQL
    await _payoutService.syncAllBalancesFromFirebase();
    
    print('✅ Balance sync completed');
  }

  /// Example: Cancel a payout
  Future<void> cancelPayoutExample(String payoutId) async {
    print('❌ Cancelling payout...');
    
    final success = await _payoutService.cancelPayout(payoutId);
    
    if (success) {
      print('✅ Payout cancelled successfully');
    } else {
      print('❌ Failed to cancel payout (may not exist or not in pending status)');
    }
  }

  /// Example: Get professional balance from Firebase
  Future<void> getFirebaseBalanceExample(String professionalId) async {
    print('🔥 Getting professional balance from Firebase...');
    
    final balance = await _firestoreService.getProfessionalBalance(professionalId);
    
    if (balance != null) {
      print('📊 Firebase Balance Data:');
      print('  Professional ID: ${balance['id']}');
      print('  Available Balance: \$${balance['availableBalance'].toStringAsFixed(2)}');
      print('  Total Earned: \$${balance['totalEarned'].toStringAsFixed(2)}');
      print('  Total Paid Out: \$${balance['totalPaidOut'].toStringAsFixed(2)}');
      print('  Last Updated: ${balance['lastUpdated']}');
    } else {
      print('❌ No balance found in Firebase for professional: $professionalId');
    }
  }

  /// Example: Get payout history from Firebase
  Future<void> getFirebasePayoutHistoryExample(String professionalId) async {
    print('🔥 Getting payout history from Firebase...');
    
    final payouts = await _firestoreService.getPayoutHistory(professionalId, limit: 5);
    
    print('📊 Found ${payouts.length} payouts in Firebase:');
    for (final payout in payouts) {
      print('  - Payout ID: ${payout['id']}');
      print('    Amount: \$${payout['amount'].toStringAsFixed(2)} ${payout['currency']}');
      print('    Status: ${payout['status']}');
      print('    Created: ${payout['createdAt']}');
      print('');
    }
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    print('🚀 Running Professional Balance Tracking Examples\n');
    
    // Initialize the payout service
    await _payoutService.initialize();
    
    // Example professional ID (replace with actual ID)
    const String exampleProfessionalId = 'example_professional_123';
    const String examplePayoutId = 'example_payout_456';
    
    try {
      // Run examples
      await getAllBalancesExample();
      await getStatisticsExample();
      await validateCashOutExample(exampleProfessionalId, 50.0);
      await getPayoutHistoryExample(exampleProfessionalId);
      await getCashOutStatsExample(exampleProfessionalId);
      await getFirebaseBalanceExample(exampleProfessionalId);
      await getFirebasePayoutHistoryExample(exampleProfessionalId);
      await syncBalancesExample();
      
      print('✅ All examples completed successfully!');
    } catch (e) {
      print('❌ Error running examples: $e');
    } finally {
      // Close the payout service
      await _payoutService.close();
    }
  }
}
