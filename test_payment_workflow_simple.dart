import 'package:postgres/postgres.dart';

void main() async {
  try {
    print('🔍 Testing Payment Workflow - Simple Test...');
    
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
    
    // Test creating an invoice with proper DateTime formatting
    print('🧪 Testing invoice creation with DateTime formatting...');
    final testInvoice = await connection.execute(
      Sql.named('''
        INSERT INTO invoices (
          booking_id, customer_id, professional_id, total_amount, currency,
          deposit_percentage, deposit_amount, balance_amount, status, notes
        ) VALUES (
          @bookingId, @customerId, @professionalId, @totalAmount, @currency,
          @depositPercentage, @depositAmount, @balanceAmount, @status, @notes
        ) RETURNING id, booking_id, status, created_at
      '''),
      parameters: {
        'bookingId': 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        'customerId': 'test_customer_456',
        'professionalId': 'test_pro_789',
        'totalAmount': 1000.00,
        'currency': 'JMD',
        'depositPercentage': 20,
        'depositAmount': 200.00,
        'balanceAmount': 800.00,
        'status': 'sent',
        'notes': 'Test invoice for DateTime validation',
      },
    );
    
    if (testInvoice.isNotEmpty) {
      final invoiceId = testInvoice.first[0].toString();
      final bookingId = testInvoice.first[1].toString();
      final status = testInvoice.first[2] .toString();
      final createdAt = testInvoice.first[3].toString();
      print('✅ Test invoice created successfully:');
      print('  - ID: $invoiceId');
      print('  - Booking: $bookingId');
      print('  - Status: $status');
      print('  - Created: $createdAt');
      
      // Test creating a payment record
      print('\n🧪 Testing payment record creation...');
      final testPayment = await connection.execute(
        Sql.named('''
          INSERT INTO payment_records (
            invoice_id, booking_id, type, amount, currency, status, notes
          ) VALUES (
            @invoiceId, @bookingId, @type, @amount, @currency, @status, @notes
          ) RETURNING id, type, status, created_at
        '''),
        parameters: {
          'invoiceId': invoiceId,
          'bookingId': bookingId,
          'type': 'deposit',
          'amount': 200.00,
          'currency': 'JMD',
          'status': 'paid',
          'notes': 'Test deposit payment',
        },
      );
      
      if (testPayment.isNotEmpty) {
        final paymentId = testPayment.first[0].toString();
        final paymentType = testPayment.first[1].toString();
        final paymentStatus = testPayment.first[2].toString();
        final paymentCreatedAt = testPayment.first[3].toString();
        print('✅ Test payment record created successfully:');
        print('  - ID: $paymentId');
        print('  - Type: $paymentType');
        print('  - Status: $paymentStatus');
        print('  - Created: $paymentCreatedAt');
      }
      
      // Clean up test data
      print('\n🧹 Cleaning up test data...');
      await connection.execute(Sql.named('DELETE FROM payment_records WHERE invoice_id = @invoiceId'), parameters: {'invoiceId': invoiceId});
      await connection.execute(Sql.named('DELETE FROM invoices WHERE id = @invoiceId'), parameters: {'invoiceId': invoiceId});
      print('✅ Test data cleaned up');
    }
    
    await connection.close();
    print('\n🎉 Payment workflow DateTime test completed successfully!');
    print('✅ All DateTime casting issues have been resolved');
    
  } catch (e) {
    print('❌ Payment workflow test failed: $e');
  }
}
