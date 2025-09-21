import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Simple test to verify database connection and balance tracking
Future<void> main() async {
  print('🧪 Simple Balance Tracking Test\n');
  
  try {
    // Test database connection
    print('1️⃣ Testing database connection...');
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'vehicle_damage_payments',
        username: 'postgres',
        password: '#!Startpos12',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ Database connected successfully');
    
    // Check if tables exist
    print('\n2️⃣ Checking database tables...');
    final tablesResult = await connection.execute(
      Sql.named('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\' ORDER BY table_name')
    );
    
    final tables = tablesResult.map((row) => row[0] as String).toList();
    print('📋 Found tables: ${tables.join(', ')}');
    
    // Check if payment_records table exists
    if (tables.contains('payment_records')) {
      print('✅ payment_records table exists');
    } else {
      print('❌ payment_records table missing');
    }
    
    // Check if professional_balances table exists
    if (tables.contains('professional_balances')) {
      print('✅ professional_balances table exists');
    } else {
      print('❌ professional_balances table missing');
    }
    
    // Check if invoices table exists
    if (tables.contains('invoices')) {
      print('✅ invoices table exists');
    } else {
      print('❌ invoices table missing');
    }
    
    // Test creating a professional balance
    print('\n3️⃣ Testing professional balance creation...');
    const testProfessionalId = 'test_prof_123';
    
    try {
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
          'professionalId': testProfessionalId,
          'availableBalance': 100.0,
          'totalEarned': 500.0,
          'totalPaidOut': 400.0,
          'lastUpdated': DateTime.now(),
          'createdAt': DateTime.now(),
        }
      );
      print('✅ Professional balance created/updated successfully');
      
      // Read the balance back
      final balanceResult = await connection.execute(
        Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
        parameters: {'professionalId': testProfessionalId}
      );
      
      if (balanceResult.isNotEmpty) {
        final balance = balanceResult.first;
        print('📊 Balance data:');
        print('   Professional ID: ${balance[0]}');
        print('   Available Balance: \$${balance[1]}');
        print('   Total Earned: \$${balance[2]}');
        print('   Total Paid Out: \$${balance[3]}');
        print('   Last Updated: ${balance[4]}');
      }
      
    } catch (e) {
      print('❌ Error creating professional balance: $e');
    }
    
    // Test creating a payment record
    print('\n4️⃣ Testing payment record creation...');
    const testBookingId = 'test_booking_456';
    final testInvoiceId = const Uuid().v4();
    
    try {
      // First create an invoice
      await connection.execute(
        Sql.named('''
          INSERT INTO invoices (id, booking_id, customer_id, professional_id, total_amount, currency, deposit_percentage, deposit_amount, balance_amount, status, created_at, updated_at)
          VALUES (@id, @bookingId, @customerId, @professionalId, @totalAmount, @currency, @depositPercentage, @depositAmount, @balanceAmount, @status, @createdAt, @updatedAt)
        '''),
        parameters: {
          'id': testInvoiceId,
          'bookingId': testBookingId,
          'customerId': 'test_customer_123',
          'professionalId': testProfessionalId,
          'totalAmount': 500.0,
          'currency': 'JMD',
          'depositPercentage': 20,
          'depositAmount': 100.0,
          'balanceAmount': 400.0,
          'status': 'sent',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        }
      );
      print('✅ Invoice created successfully');
      
      // Create a payment record
      final paymentId = const Uuid().v4();
      await connection.execute(
        Sql.named('''
          INSERT INTO payment_records (id, invoice_id, booking_id, type, amount, currency, status, payment_method, created_at, updated_at, total_amount)
          VALUES (@id, @invoiceId, @bookingId, @type, @amount, @currency, @status, @paymentMethod, @createdAt, @updatedAt, @totalAmount)
        '''),
        parameters: {
          'id': paymentId,
          'invoiceId': testInvoiceId,
          'bookingId': testBookingId,
          'type': 'deposit',
          'amount': 100.0,
          'currency': 'JMD',
          'status': 'pending',
          'paymentMethod': 'credit_card',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'totalAmount': 500.0,
        }
      );
      print('✅ Payment record created successfully');
      
      // Test updating payment status to paid (this should trigger balance update)
      print('\n5️⃣ Testing payment status update (should trigger balance update)...');
      await connection.execute(
        Sql.named('''
          UPDATE payment_records 
          SET status = @status, processed_at = @processedAt, updated_at = @updatedAt
          WHERE id = @paymentId
        '''),
        parameters: {
          'paymentId': paymentId,
          'status': 'paid',
          'processedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        }
      );
      print('✅ Payment status updated to paid');
      
      // Check if balance was updated by the trigger
      final updatedBalanceResult = await connection.execute(
        Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
        parameters: {'professionalId': testProfessionalId}
      );
      
      if (updatedBalanceResult.isNotEmpty) {
        final balance = updatedBalanceResult.first;
        print('📊 Updated balance after payment:');
        print('   Available Balance: \$${balance[1]}');
        print('   Total Earned: \$${balance[2]}');
        print('   Total Paid Out: \$${balance[3]}');
        
        // Check if the balance was updated correctly
        final availableBalance = double.parse(balance[1].toString());
        final totalEarned = double.parse(balance[2].toString());
        
        if (availableBalance == 200.0 && totalEarned == 600.0) {
          print('✅ Balance update trigger working correctly!');
        } else {
          print('❌ Balance update trigger not working - expected available: \$200, total: \$600');
        }
      }
      
    } catch (e) {
      print('❌ Error testing payment record: $e');
    }
    
    // Clean up test data
    print('\n6️⃣ Cleaning up test data...');
    try {
      await connection.execute(
        Sql.named('DELETE FROM payment_records WHERE booking_id = @bookingId'),
        parameters: {'bookingId': testBookingId}
      );
      await connection.execute(
        Sql.named('DELETE FROM invoices WHERE booking_id = @bookingId'),
        parameters: {'bookingId': testBookingId}
      );
      await connection.execute(
        Sql.named('DELETE FROM professional_balances WHERE professional_id = @professionalId'),
        parameters: {'professionalId': testProfessionalId}
      );
      print('✅ Test data cleaned up');
    } catch (e) {
      print('⚠️ Error cleaning up test data: $e');
    }
    
    await connection.close();
    print('\n🎉 Simple balance tracking test completed!');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
