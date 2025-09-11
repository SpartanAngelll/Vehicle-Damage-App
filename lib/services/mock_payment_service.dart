import '../models/payment_models.dart';

class MockPaymentService {
  static MockPaymentService? _instance;
  Map<String, Payment> _payments = {};

  MockPaymentService._();

  static MockPaymentService get instance {
    _instance ??= MockPaymentService._();
    return _instance!;
  }

  Future<void> initialize() async {
    print('✅ [MockPayment] Mock payment service initialized');
  }

  Future<void> close() async {
    print('🔌 [MockPayment] Mock payment service closed');
  }

  Future<bool> isConnected() async {
    return true; // Mock service is always "connected"
  }

  // Create a new payment record
  Future<Payment> createPayment({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required double amount,
    String currency = 'JMD',
    int depositPercentage = 0,
    String? notes,
  }) async {
    final depositAmount = depositPercentage > 0 ? amount * depositPercentage / 100 : null;
    
    final payment = Payment(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      customerId: customerId,
      professionalId: professionalId,
      amount: amount,
      currency: currency,
      depositPercentage: depositPercentage,
      depositAmount: depositAmount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: notes,
    );

    _payments[bookingId] = payment;
    print('✅ [MockPayment] Created mock payment for booking $bookingId');
    return payment;
  }

  // Get payment by booking ID
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    return _payments[bookingId];
  }

  // Get payments by customer ID
  Future<List<Payment>> getPaymentsByCustomerId(String customerId) async {
    return _payments.values
        .where((payment) => payment.customerId == customerId)
        .toList();
  }

  // Get payments by professional ID
  Future<List<Payment>> getPaymentsByProfessionalId(String professionalId) async {
    return _payments.values
        .where((payment) => payment.professionalId == professionalId)
        .toList();
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    PaymentMethod? paymentMethod,
    String? notes,
    String? changedBy,
  }) async {
    final payment = _payments.values.firstWhere(
      (p) => p.id == paymentId,
      orElse: () => throw Exception('Payment not found'),
    );

    final updatedPayment = payment.copyWith(
      status: status,
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      notes: notes,
      updatedAt: DateTime.now(),
      paidAt: status == PaymentStatus.paid ? DateTime.now() : payment.paidAt,
      refundedAt: status == PaymentStatus.refunded ? DateTime.now() : payment.refundedAt,
    );

    _payments[payment.bookingId] = updatedPayment;
    print('✅ [MockPayment] Updated payment $paymentId status to ${status.name}');
    return true;
  }

  // Process mock payment
  Future<bool> processMockPayment({
    required String paymentId,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      final transactionId = 'MOCK_${DateTime.now().millisecondsSinceEpoch}';
      
      return await updatePaymentStatus(
        paymentId: paymentId,
        status: PaymentStatus.paid,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        notes: notes ?? 'Mock payment processed successfully',
        changedBy: 'system',
      );
    } catch (e) {
      print('❌ [MockPayment] Failed to process mock payment: $e');
      return false;
    }
  }

  // Request deposit
  Future<bool> requestDeposit({
    required String bookingId,
    required String professionalId,
    required int depositPercentage,
    required String reason,
  }) async {
    try {
      final existingPayment = _payments[bookingId];
      if (existingPayment != null) {
        final updatedPayment = existingPayment.copyWith(
          depositPercentage: depositPercentage,
          depositAmount: existingPayment.amount * depositPercentage / 100,
          notes: 'Deposit requested: $reason',
          updatedAt: DateTime.now(),
        );
        
        _payments[bookingId] = updatedPayment;
        print('✅ [MockPayment] Deposit request updated for booking $bookingId');
        return true;
      } else {
        print('⚠️ [MockPayment] No payment found for booking $bookingId');
        return false;
      }
    } catch (e) {
      print('❌ [MockPayment] Failed to request deposit: $e');
      return false;
    }
  }

  // Get payment status history
  Future<List<PaymentStatusHistory>> getPaymentStatusHistory(String paymentId) async {
    // Mock implementation - return empty list
    return [];
  }
}
