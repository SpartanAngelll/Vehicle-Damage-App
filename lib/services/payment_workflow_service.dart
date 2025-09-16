import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_models.dart';
import '../models/payment_models.dart';
import '../models/booking_models.dart';
import 'postgres_payment_service.dart';
import 'firebase_firestore_service.dart';
import 'payout_service.dart';

class PaymentWorkflowService {
  static PaymentWorkflowService? _instance;
  final PostgresPaymentService _postgresService;
  final FirebaseFirestoreService _firestoreService;
  final FirebaseFirestore _firestore;
  final PayoutService _payoutService;

  PaymentWorkflowService._()
      : _postgresService = PostgresPaymentService.instance,
        _firestoreService = FirebaseFirestoreService(),
        _firestore = FirebaseFirestore.instance,
        _payoutService = PayoutService.instance;

  static PaymentWorkflowService get instance {
    _instance ??= PaymentWorkflowService._();
    return _instance!;
  }

  Future<void> initialize() async {
    await _postgresService.initialize();
    await _payoutService.initialize();
    print('✅ [PaymentWorkflow] Payment Workflow Service initialized');
  }

  Future<void> close() async {
    await _postgresService.close();
    print('🔌 [PaymentWorkflow] Payment Workflow Service closed');
  }

  /// Create invoice when booking is accepted
  Future<Invoice> createInvoiceFromBooking({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required double totalAmount,
    int depositPercentage = 0,
    String currency = 'JMD',
    String? notes,
  }) async {
    try {
      final depositAmount = depositPercentage > 0 ? totalAmount * depositPercentage / 100 : 0.0;
      final balanceAmount = totalAmount - depositAmount;

      final invoice = Invoice(
        bookingId: bookingId,
        customerId: customerId,
        professionalId: professionalId,
        totalAmount: totalAmount,
        currency: currency,
        depositPercentage: depositPercentage,
        depositAmount: depositAmount,
        balanceAmount: balanceAmount,
        status: depositPercentage > 0 ? InvoiceStatus.sent : InvoiceStatus.sent,
        dueDate: DateTime.now().add(const Duration(days: 7)), // 7 days to pay
        notes: notes,
      );

      // Store in PostgreSQL
      final createdInvoice = await _createInvoiceInPostgres(invoice);
      
      // Sync to Firestore for real-time updates
      // Sync to Firestore (temporarily disabled due to permission issues)
      // await _syncInvoiceToFirestore(createdInvoice);

      print('✅ [PaymentWorkflow] Created invoice for booking $bookingId: ${createdInvoice.id}');
      return createdInvoice;
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to create invoice: $e');
      rethrow;
    }
  }

  /// Process deposit payment
  Future<PaymentRecord> processDepositPayment({
    required String bookingId,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      // Get invoice from PostgreSQL
      final invoice = await _getInvoiceByBookingId(bookingId);
      if (invoice == null) {
        throw Exception('Invoice not found for booking $bookingId');
      }

      if (!invoice.isDepositRequired) {
        throw Exception('No deposit required for this booking');
      }

      if (invoice.isDepositPaid) {
        throw Exception('Deposit already paid for this booking');
      }

      // Create payment record
      final paymentRecord = PaymentRecord(
        invoiceId: invoice.id,
        bookingId: bookingId,
        type: PaymentType.deposit,
        amount: invoice.depositAmount,
        currency: invoice.currency,
        status: PaymentStatus.pending,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      // Store payment record in PostgreSQL
      final createdPayment = await _createPaymentRecordInPostgres(paymentRecord);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update payment status to paid
      final updatedPayment = await _updatePaymentStatus(
        paymentId: createdPayment.id,
        status: PaymentStatus.paid,
        transactionId: 'DEP_${DateTime.now().millisecondsSinceEpoch}',
        notes: 'Deposit payment processed successfully',
      );

      // Update invoice status
      await _updateInvoiceStatus(
        invoiceId: invoice.id,
        status: InvoiceStatus.depositPaid,
        notes: 'Deposit payment received',
      );

      // Update professional balance (only for non-cash payments)
      if (paymentMethod != PaymentMethod.cash) {
        await _payoutService.updateProfessionalBalanceOnPayment(
          professionalId: invoice.professionalId,
          amount: invoice.depositAmount,
        );
        print('✅ [PaymentWorkflow] Updated professional balance for deposit payment: ${invoice.depositAmount}');
      } else {
        print('ℹ️ [PaymentWorkflow] Cash payment - no balance update needed');
      }

      // Sync to Firestore (temporarily disabled due to permission issues)
      // await _syncPaymentToFirestore(updatedPayment);
      // await _syncInvoiceToFirestore(invoice.copyWith(status: InvoiceStatus.depositPaid));

      print('✅ [PaymentWorkflow] Deposit payment processed for booking $bookingId');
      return updatedPayment;
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to process deposit payment: $e');
      rethrow;
    }
  }

  /// Process balance payment after job completion
  Future<PaymentRecord> processBalancePayment({
    required String bookingId,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      // Get invoice from PostgreSQL
      final invoice = await _getInvoiceByBookingId(bookingId);
      if (invoice == null) {
        throw Exception('Invoice not found for booking $bookingId');
      }

      if (invoice.isFullyPaid) {
        throw Exception('Invoice already fully paid');
      }

      // Create payment record for balance
      final paymentRecord = PaymentRecord(
        invoiceId: invoice.id,
        bookingId: bookingId,
        type: PaymentType.balance,
        amount: invoice.balanceAmount,
        currency: invoice.currency,
        status: PaymentStatus.pending,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      // Store payment record in PostgreSQL
      final createdPayment = await _createPaymentRecordInPostgres(paymentRecord);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update payment status to paid
      final updatedPayment = await _updatePaymentStatus(
        paymentId: createdPayment.id,
        status: PaymentStatus.paid,
        transactionId: 'BAL_${DateTime.now().millisecondsSinceEpoch}',
        notes: 'Balance payment processed successfully',
      );

      // Update invoice status to fully paid
      await _updateInvoiceStatus(
        invoiceId: invoice.id,
        status: InvoiceStatus.paid,
        notes: 'Full payment received',
      );

      // Update professional balance (only for non-cash payments)
      if (paymentMethod != PaymentMethod.cash) {
        await _payoutService.updateProfessionalBalanceOnPayment(
          professionalId: invoice.professionalId,
          amount: invoice.balanceAmount,
        );
        print('✅ [PaymentWorkflow] Updated professional balance for balance payment: ${invoice.balanceAmount}');
      } else {
        print('ℹ️ [PaymentWorkflow] Cash payment - no balance update needed');
      }

      // Sync to Firestore (temporarily disabled due to permission issues)
      // await _syncPaymentToFirestore(updatedPayment);
      // await _syncInvoiceToFirestore(invoice.copyWith(status: InvoiceStatus.paid));

      print('✅ [PaymentWorkflow] Balance payment processed for booking $bookingId');
      return updatedPayment;
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to process balance payment: $e');
      rethrow;
    }
  }

  /// Get invoice by booking ID
  Future<Invoice?> getInvoiceByBookingId(String bookingId) async {
    return await _getInvoiceByBookingId(bookingId);
  }

  /// Get payment records for a booking
  Future<List<PaymentRecord>> getPaymentRecordsByBookingId(String bookingId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      final result = await connection.execute(
        Sql.named('SELECT * FROM payment_records WHERE booking_id = @bookingId ORDER BY created_at DESC'),
        parameters: {'bookingId': bookingId},
      );

      return result.map((row) => _mapRowToPaymentRecord(row)).toList();
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to get payment records: $e');
      return [];
    }
  }

  /// Check if deposit is required and not paid
  Future<bool> isDepositRequiredAndUnpaid(String bookingId) async {
    final invoice = await _getInvoiceByBookingId(bookingId);
    return invoice?.isDepositRequired == true && invoice?.isDepositPaid == false;
  }

  /// Check if balance payment is required
  Future<bool> isBalancePaymentRequired(String bookingId) async {
    try {
      // First try to check using payment_records (preferred method)
      await _postgresService.initialize();
      return await _postgresService.isBalancePaymentRequired(bookingId);
    } catch (e) {
      print('⚠️ [PaymentWorkflow] Failed to check balance using payment_records, trying invoice method: $e');
      // Fallback to invoice method
      final invoice = await _getInvoiceByBookingId(bookingId);
      return invoice?.isFullyPaid == false;
    }
  }

  // Private methods for PostgreSQL operations

  Future<Invoice> _createInvoiceInPostgres(Invoice invoice) async {
      final connection = await _postgresService.getConnection();
    final result = await connection.execute(
      Sql.named('''
      INSERT INTO invoices (
        id, booking_id, customer_id, professional_id, total_amount, currency,
        deposit_percentage, deposit_amount, balance_amount, status, created_at,
        updated_at, sent_at, due_date, notes, metadata
      ) VALUES (
        @id, @bookingId, @customerId, @professionalId, @totalAmount, @currency,
        @depositPercentage, @depositAmount, @balanceAmount, @status, @createdAt,
        @updatedAt, @sentAt, @dueDate, @notes, @metadata
      ) RETURNING *
      '''),
      parameters: {
        'id': invoice.id,
        'bookingId': invoice.bookingId,
        'customerId': invoice.customerId,
        'professionalId': invoice.professionalId,
        'totalAmount': invoice.totalAmount,
        'currency': invoice.currency,
        'depositPercentage': invoice.depositPercentage,
        'depositAmount': invoice.depositAmount,
        'balanceAmount': invoice.balanceAmount,
        'status': invoice.status.name,
        'createdAt': invoice.createdAt,
        'updatedAt': invoice.updatedAt,
        'sentAt': invoice.sentAt,
        'dueDate': invoice.dueDate,
        'notes': invoice.notes,
        'metadata': invoice.metadata != null ? invoice.metadata.toString() : null,
      },
    );

    return _mapRowToInvoice(result.first);
  }

  Future<PaymentRecord> _createPaymentRecordInPostgres(PaymentRecord payment) async {
      final connection = await _postgresService.getConnection();
    final result = await connection.execute(
      Sql.named('''
      INSERT INTO payment_records (
        id, invoice_id, booking_id, type, amount, currency, status,
        payment_method, transaction_id, created_at, updated_at,
        processed_at, notes, metadata
      ) VALUES (
        @id, @invoiceId, @bookingId, @type, @amount, @currency, @status,
        @paymentMethod, @transactionId, @createdAt, @updatedAt,
        @processedAt, @notes, @metadata
      ) RETURNING *
      '''),
      parameters: {
        'id': payment.id,
        'invoiceId': payment.invoiceId,
        'bookingId': payment.bookingId,
        'type': payment.type.name,
        'amount': payment.amount,
        'currency': payment.currency,
        'status': payment.status.name,
        'paymentMethod': payment.paymentMethod?.name,
        'transactionId': payment.transactionId,
        'createdAt': payment.createdAt,
        'updatedAt': payment.updatedAt,
        'processedAt': payment.processedAt,
        'notes': payment.notes,
        'metadata': payment.metadata != null ? payment.metadata.toString() : null,
      },
    );

    return _mapRowToPaymentRecord(result.first);
  }

  Future<Invoice?> _getInvoiceByBookingId(String bookingId) async {
    try {
      await _postgresService.initialize();
      final connection = await _postgresService.getConnection();
      final result = await connection.execute(
        Sql.named('SELECT * FROM invoices WHERE booking_id = @bookingId'),
        parameters: {'bookingId': bookingId},
      );

      if (result.isEmpty) return null;
      return _mapRowToInvoice(result.first);
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to get invoice: $e');
      return null;
    }
  }

  Future<PaymentRecord> _updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    String? notes,
  }) async {
      final connection = await _postgresService.getConnection();
    final result = await connection.execute(
      Sql.named('''
      UPDATE payment_records 
      SET status = @status, transaction_id = @transactionId, 
          processed_at = @processedAt, updated_at = @updatedAt, notes = @notes
      WHERE id = @paymentId
      RETURNING *
      '''),
      parameters: {
        'paymentId': paymentId,
        'status': status.name,
        'transactionId': transactionId,
        'processedAt': status == PaymentStatus.paid ? DateTime.now() : null,
        'updatedAt': DateTime.now(),
        'notes': notes,
      },
    );

    return _mapRowToPaymentRecord(result.first);
  }

  Future<void> _updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
    String? notes,
  }) async {
      final connection = await _postgresService.getConnection();
    await connection.execute(
      Sql.named('''
      UPDATE invoices 
      SET status = @status, updated_at = @updatedAt, notes = @notes
      WHERE id = @invoiceId
      '''),
      parameters: {
        'invoiceId': invoiceId,
        'status': status.name,
        'updatedAt': DateTime.now(),
        'notes': notes,
      },
    );
  }

  // Firestore sync methods

  Future<void> _syncInvoiceToFirestore(Invoice invoice) async {
    try {
      await _firestore.collection('invoices').doc(invoice.id).set({
        'id': invoice.id,
        'bookingId': invoice.bookingId,
        'customerId': invoice.customerId,
        'professionalId': invoice.professionalId,
        'totalAmount': invoice.totalAmount,
        'currency': invoice.currency,
        'depositPercentage': invoice.depositPercentage,
        'depositAmount': invoice.depositAmount,
        'balanceAmount': invoice.balanceAmount,
        'status': invoice.status.name,
        'createdAt': Timestamp.fromDate(invoice.createdAt),
        'updatedAt': Timestamp.fromDate(invoice.updatedAt),
        'sentAt': invoice.sentAt != null ? Timestamp.fromDate(invoice.sentAt!) : null,
        'dueDate': invoice.dueDate != null ? Timestamp.fromDate(invoice.dueDate!) : null,
        'notes': invoice.notes,
        'metadata': invoice.metadata,
        'isDepositRequired': invoice.isDepositRequired,
        'isDepositPaid': invoice.isDepositPaid,
        'isFullyPaid': invoice.isFullyPaid,
        'isOverdue': invoice.isOverdue,
      });
      print('✅ [PaymentWorkflow] Synced invoice to Firestore: ${invoice.id}');
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to sync invoice to Firestore: $e');
    }
  }

  Future<void> _syncPaymentToFirestore(PaymentRecord payment) async {
    try {
      await _firestore.collection('payments').doc(payment.id).set({
        'id': payment.id,
        'invoiceId': payment.invoiceId,
        'bookingId': payment.bookingId,
        'type': payment.type.name,
        'amount': payment.amount,
        'currency': payment.currency,
        'status': payment.status.name,
        'paymentMethod': payment.paymentMethod?.name,
        'transactionId': payment.transactionId,
        'createdAt': Timestamp.fromDate(payment.createdAt),
        'updatedAt': Timestamp.fromDate(payment.updatedAt),
        'processedAt': payment.processedAt != null ? Timestamp.fromDate(payment.processedAt!) : null,
        'notes': payment.notes,
        'metadata': payment.metadata,
        'isProcessed': payment.isProcessed,
        'isPending': payment.isPending,
        'isRefunded': payment.isRefunded,
      });
      print('✅ [PaymentWorkflow] Synced payment to Firestore: ${payment.id}');
    } catch (e) {
      print('❌ [PaymentWorkflow] Failed to sync payment to Firestore: $e');
    }
  }

  // Helper methods for mapping database rows

  Invoice _mapRowToInvoice(List<dynamic> row) {
    return Invoice(
      id: row[0].toString(),
      bookingId: row[1] as String,
      customerId: row[2] as String,
      professionalId: row[3] as String,
      totalAmount: double.parse(row[4].toString()),
      currency: row[5] as String,
      depositPercentage: int.parse(row[6].toString()),
      depositAmount: double.parse(row[7].toString()),
      balanceAmount: double.parse(row[8].toString()),
      status: InvoiceStatus.values.firstWhere((e) => e.name == (row[9] as String)),
      createdAt: row[10] as DateTime,
      updatedAt: row[11] as DateTime,
      sentAt: row[12] as DateTime?,
      dueDate: row[13] as DateTime?,
      notes: row[14] as String?,
      metadata: row[16] != null ? Map<String, dynamic>.from(row[16] as Map) : null, // metadata is at index 16
    );
  }

  PaymentRecord _mapRowToPaymentRecord(List<dynamic> row) {
    return PaymentRecord(
      id: row[0].toString(),
      invoiceId: row[1] as String,
      bookingId: row[2] as String,
      type: PaymentType.values.firstWhere((e) => e.name == (row[3] as String)),
      amount: double.parse(row[4].toString()),
      currency: row[5] as String,
      status: PaymentStatus.values.firstWhere((e) => e.name == (row[6] as String)),
      paymentMethod: row[7] != null 
          ? PaymentMethod.values.firstWhere((e) => e.name == (row[7] as String))
          : null,
      transactionId: row[8] as String?,
      createdAt: row[9] as DateTime,
      updatedAt: row[10] as DateTime,
      processedAt: row[11] as DateTime?,
      notes: row[12] as String?,
      metadata: row[13] != null ? Map<String, dynamic>.from(row[13] as Map) : null,
    );
  }
}
