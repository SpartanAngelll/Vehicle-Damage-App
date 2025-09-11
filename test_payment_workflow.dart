import 'package:postgres/postgres.dart';

void main() async {
  try {
    print('🔍 Testing Payment Workflow Database Schema...');
    
    final connection = await Connection.open(
      Endpoint(
        host: '192.168.0.53',
        port: 5432,
        database: 'vehicle_damage_payments',
        username: 'postgres',
        password: '#!Startpos12',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
    
    // Check invoices table
    final invoices = await connection.execute('SELECT COUNT(*) FROM invoices');
    final invoiceCount = invoices.first[0] as int;
    print('📊 Total invoices in database: $invoiceCount');
    
    // Check payment_records table
    final payments = await connection.execute('SELECT COUNT(*) FROM payment_records');
    final paymentCount = payments.first[0] as int;
    print('📊 Total payment records in database: $paymentCount');
    
    // Check invoice_status_history table
    final invoiceHistory = await connection.execute('SELECT COUNT(*) FROM invoice_status_history');
    final invoiceHistoryCount = invoiceHistory.first[0] as int;
    print('📊 Total invoice status history entries: $invoiceHistoryCount');
    
    // Check payment_status_history table
    final paymentHistory = await connection.execute('SELECT COUNT(*) FROM payment_status_history');
    final paymentHistoryCount = paymentHistory.first[0] as int;
    print('📊 Total payment status history entries: $paymentHistoryCount');
    
    if (invoiceCount > 0) {
      // Show recent invoices
      final recentInvoices = await connection.execute('''
        SELECT booking_id, customer_id, total_amount, currency, deposit_percentage, status, created_at 
        FROM invoices 
        ORDER BY created_at DESC 
        LIMIT 3
      ''');
      
      print('\n📋 Recent invoices:');
      for (final invoice in recentInvoices) {
        print('  - Booking: ${invoice[0]} | Amount: ${invoice[2]} ${invoice[3]} | Deposit: ${invoice[4]}% | Status: ${invoice[5]} | Date: ${invoice[6]}');
      }
    }
    
    if (paymentCount > 0) {
      // Show recent payment records
      final recentPayments = await connection.execute('''
        SELECT booking_id, type, amount, currency, status, created_at 
        FROM payment_records 
        ORDER BY created_at DESC 
        LIMIT 3
      ''');
      
      print('\n📋 Recent payment records:');
      for (final payment in recentPayments) {
        print('  - Booking: ${payment[0]} | Type: ${payment[1]} | Amount: ${payment[2]} ${payment[3]} | Status: ${payment[4]} | Date: ${payment[5]}');
      }
    }
    
    // Test creating a sample invoice
    print('\n🧪 Testing invoice creation...');
    final uniqueBookingId = 'test_booking_${DateTime.now().millisecondsSinceEpoch}';
    final testInvoice = await connection.execute(
      Sql.named('''
        INSERT INTO invoices (
          booking_id, customer_id, professional_id, total_amount, currency,
          deposit_percentage, deposit_amount, balance_amount, status, notes
        ) VALUES (
          @bookingId, 'test_customer_456', 'test_pro_789', 1000.00, 'JMD',
          20, 200.00, 800.00, 'sent', 'Test invoice for workflow validation'
        ) RETURNING id, booking_id, status
      '''),
      parameters: {'bookingId': uniqueBookingId},
    );
    
    if (testInvoice.isNotEmpty) {
      final invoiceId = testInvoice.first[0].toString();
      final bookingId = testInvoice.first[1].toString();
      final status = testInvoice.first[2].toString();
      print('✅ Test invoice created: ID=$invoiceId, Booking=$bookingId, Status=$status');
      
      // Test creating a payment record
      final testPayment = await connection.execute(
        Sql.named('''
          INSERT INTO payment_records (
            invoice_id, booking_id, type, amount, currency, status, notes
          ) VALUES (
            @invoiceId, @bookingId, 'deposit', 200.00, 'JMD', 'paid', 'Test deposit payment'
          ) RETURNING id, type, status
        '''),
        parameters: {
          'invoiceId': invoiceId,
          'bookingId': bookingId,
        },
      );
      
      if (testPayment.isNotEmpty) {
        final paymentId = testPayment.first[0].toString();
        final paymentType = testPayment.first[1].toString();
        final paymentStatus = testPayment.first[2].toString();
        print('✅ Test payment record created: ID=$paymentId, Type=$paymentType, Status=$paymentStatus');
      }
      
      // Clean up test data
      await connection.execute(Sql.named('DELETE FROM payment_records WHERE invoice_id = @invoiceId'), parameters: {'invoiceId': invoiceId});
      await connection.execute(Sql.named('DELETE FROM invoices WHERE id = @invoiceId'), parameters: {'invoiceId': invoiceId});
      print('🧹 Test data cleaned up');
    }
    
    await connection.close();
    print('\n✅ Payment workflow database test completed successfully!');
    
  } catch (e) {
    print('❌ Payment workflow test failed: $e');
  }
}
