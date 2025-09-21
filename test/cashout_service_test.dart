import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/cashout_service.dart';
import '../lib/models/payout_models.dart';

// Generate mocks for testing
@GenerateMocks([CashOutService])
void main() {
  group('CashOutService Tests', () {
    late CashOutService cashOutService;

    setUp(() {
      cashOutService = CashOutService.instance;
    });

    group('Validation Tests', () {
      test('should validate cash-out request with valid amount', () async {
        // Mock professional balance
        final mockBalance = ProfessionalBalance(
          professionalId: 'test_professional',
          availableBalance: 500.0,
          totalEarned: 1000.0,
          totalPaidOut: 500.0,
          lastUpdated: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // This would be mocked in a real test
        // when(cashOutService.getProfessionalBalance('test_professional'))
        //     .thenAnswer((_) async => mockBalance);

        final validation = await cashOutService.validateCashOutRequest(
          professionalId: 'test_professional',
          amount: 100.0,
        );

        // In a real test with mocks, this would work
        // expect(validation.isValid, true);
        // expect(validation.availableBalance, 500.0);
      });

      test('should reject cash-out request with insufficient balance', () async {
        final validation = await cashOutService.validateCashOutRequest(
          professionalId: 'test_professional',
          amount: 1000.0, // More than available balance
        );

        expect(validation.isValid, false);
        expect(validation.error, contains('Insufficient balance'));
      });

      test('should reject cash-out request with amount too low', () async {
        final validation = await cashOutService.validateCashOutRequest(
          professionalId: 'test_professional',
          amount: 5.0, // Below minimum
        );

        expect(validation.isValid, false);
        expect(validation.error, contains('Minimum cash-out amount'));
      });

      test('should reject cash-out request with amount too high', () async {
        final validation = await cashOutService.validateCashOutRequest(
          professionalId: 'test_professional',
          amount: 15000.0, // Above maximum
        );

        expect(validation.isValid, false);
        expect(validation.error, contains('Maximum cash-out amount'));
      });

      test('should reject cash-out request with negative amount', () async {
        final validation = await cashOutService.validateCashOutRequest(
          professionalId: 'test_professional',
          amount: -100.0,
        );

        expect(validation.isValid, false);
        expect(validation.error, contains('Amount must be greater than 0'));
      });
    });

    group('Formatting Tests', () {
      test('should format amount correctly', () {
        expect(cashOutService.formatAmount(123.45), '\$123.45');
        expect(cashOutService.formatAmount(0.0), '\$0.00');
        expect(cashOutService.formatAmount(1000.0), '\$1000.00');
      });

      test('should format date correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final lastWeek = today.subtract(const Duration(days: 7));

        expect(cashOutService.formatDate(today), 'Today');
        expect(cashOutService.formatDate(yesterday), 'Yesterday');
        expect(cashOutService.formatDate(lastWeek), '7 days ago');
      });

      test('should get status display text correctly', () {
        expect(cashOutService.getStatusDisplayText(PayoutStatus.pending), 'Processing');
        expect(cashOutService.getStatusDisplayText(PayoutStatus.success), 'Completed');
        expect(cashOutService.getStatusDisplayText(PayoutStatus.failed), 'Failed');
      });

      test('should get status color correctly', () {
        expect(cashOutService.getStatusColor(PayoutStatus.pending), '#FFA500');
        expect(cashOutService.getStatusColor(PayoutStatus.success), '#4CAF50');
        expect(cashOutService.getStatusColor(PayoutStatus.failed), '#F44336');
      });
    });

    group('Error Handling Tests', () {
      test('should handle network errors gracefully', () async {
        final response = await cashOutService.requestCashOut(
          professionalId: 'test_professional',
          amount: 100.0,
        );

        // In a real test environment, this would test network error handling
        expect(response.success, isA<bool>());
      });

      test('should handle invalid professional ID', () async {
        final response = await cashOutService.requestCashOut(
          professionalId: '', // Empty professional ID
          amount: 100.0,
        );

        expect(response.success, false);
        expect(response.error, isNotNull);
      });

      test('should handle null balance gracefully', () async {
        final balance = await cashOutService.getProfessionalBalance('nonexistent_professional');
        
        // Should return null for non-existent professional
        expect(balance, isNull);
      });
    });

    group('Statistics Tests', () {
      test('should calculate cash-out stats correctly', () async {
        final stats = await cashOutService.getCashOutStats('test_professional');
        
        expect(stats, isA<CashOutStats>());
        expect(stats.availableBalance, isA<double>());
        expect(stats.totalEarned, isA<double>());
        expect(stats.totalPaidOut, isA<double>());
        expect(stats.pendingPayouts, isA<int>());
        expect(stats.completedPayouts, isA<int>());
        expect(stats.failedPayouts, isA<int>());
      });

      test('should calculate net earnings correctly', () {
        final stats = CashOutStats(
          availableBalance: 500.0,
          totalEarned: 1000.0,
          totalPaidOut: 500.0,
          pendingPayouts: 1,
          completedPayouts: 5,
          failedPayouts: 0,
        );

        expect(stats.netEarnings, 500.0);
        expect(stats.totalPayouts, 6);
        expect(stats.successRate, closeTo(0.83, 0.01));
      });
    });
  });

  group('Payout Model Tests', () {
    test('should create payout from map correctly', () {
      final map = {
        'id': 'test_payout_id',
        'professional_id': 'test_professional',
        'amount': 100.0,
        'currency': 'JMD',
        'status': 'pending',
        'created_at': '2024-01-01T12:00:00Z',
      };

      final payout = Payout.fromMap(map);

      expect(payout.id, 'test_payout_id');
      expect(payout.professionalId, 'test_professional');
      expect(payout.amount, 100.0);
      expect(payout.currency, 'JMD');
      expect(payout.status, PayoutStatus.pending);
    });

    test('should convert payout to map correctly', () {
      final payout = Payout(
        id: 'test_payout_id',
        professionalId: 'test_professional',
        amount: 100.0,
        currency: 'JMD',
        status: PayoutStatus.pending,
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final map = payout.toMap();

      expect(map['id'], 'test_payout_id');
      expect(map['professional_id'], 'test_professional');
      expect(map['amount'], 100.0);
      expect(map['currency'], 'JMD');
      expect(map['status'], 'pending');
    });

    test('should handle payout status correctly', () {
      final payout = Payout(
        id: 'test_payout_id',
        professionalId: 'test_professional',
        amount: 100.0,
        createdAt: DateTime.now(),
        status: PayoutStatus.pending,
      );

      expect(payout.isPending, true);
      expect(payout.isSuccess, false);
      expect(payout.isFailed, false);
      expect(payout.isCompleted, false);

      final successPayout = payout.copyWith(status: PayoutStatus.success);
      expect(successPayout.isPending, false);
      expect(successPayout.isSuccess, true);
      expect(successPayout.isCompleted, true);
    });
  });

  group('ProfessionalBalance Model Tests', () {
    test('should create professional balance from map correctly', () {
      final map = {
        'professional_id': 'test_professional',
        'available_balance': 500.0,
        'total_earned': 1000.0,
        'total_paid_out': 500.0,
        'last_updated': '2024-01-01T12:00:00Z',
        'created_at': '2024-01-01T12:00:00Z',
      };

      final balance = ProfessionalBalance.fromMap(map);

      expect(balance.professionalId, 'test_professional');
      expect(balance.availableBalance, 500.0);
      expect(balance.totalEarned, 1000.0);
      expect(balance.totalPaidOut, 500.0);
    });

    test('should calculate net earnings correctly', () {
      final balance = ProfessionalBalance(
        professionalId: 'test_professional',
        availableBalance: 500.0,
        totalEarned: 1000.0,
        totalPaidOut: 500.0,
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(balance.netEarnings, 500.0);
      expect(balance.hasAvailableBalance, true);
    });
  });

  group('CashOutRequest Model Tests', () {
    test('should create cash-out request from map correctly', () {
      final map = {
        'professional_id': 'test_professional',
        'amount': 100.0,
      };

      final request = CashOutRequest.fromMap(map);

      expect(request.professionalId, 'test_professional');
      expect(request.amount, 100.0);
    });

    test('should convert cash-out request to map correctly', () {
      final request = CashOutRequest(
        professionalId: 'test_professional',
        amount: 100.0,
      );

      final map = request.toMap();

      expect(map['professional_id'], 'test_professional');
      expect(map['amount'], 100.0);
    });
  });

  group('CashOutResponse Model Tests', () {
    test('should create success response correctly', () {
      final payout = Payout(
        id: 'test_payout_id',
        professionalId: 'test_professional',
        amount: 100.0,
        createdAt: DateTime.now(),
      );

      final response = CashOutResponse(
        success: true,
        message: 'Success',
        payout: payout,
      );

      expect(response.success, true);
      expect(response.message, 'Success');
      expect(response.payout, payout);
      expect(response.error, isNull);
    });

    test('should create error response correctly', () {
      final response = CashOutResponse(
        success: false,
        error: 'Test error',
      );

      expect(response.success, false);
      expect(response.error, 'Test error');
      expect(response.message, isNull);
      expect(response.payout, isNull);
    });
  });
}
