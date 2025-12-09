import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

/// Simple test to verify balance tracking without Flutter dependencies
Future<void> main() async {
  print('🧪 Simple Balance Tracking Test (No Flutter)\n');
  
  try {
    // Test database connection
    print('1️⃣ Testing database connection...');
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'vehicle_damage_payments',
        username: 'postgres',
        password: (() {
          final password = Platform.environment['POSTGRES_PASSWORD'];
          if (password == null || password.isEmpty) {
            throw Exception('POSTGRES_PASSWORD environment variable is required');
          }
          return password;
        })(),
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ Database connected successfully');
    
    // Test professional ID (unique for each test run)
    final testProfessionalId = 'test_prof_${DateTime.now().millisecondsSinceEpoch}';
    const testCustomerId = 'test_customer_456';
    final testBookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    final testInvoiceId = const Uuid().v4();
    
    print('\n2️⃣ Testing complete payment workflow...');
    print('   Professional ID: $testProfessionalId');
    print('   Customer ID: $testCustomerId');
    print('   Booking ID: $testBookingId');
    print('   Invoice ID: $testInvoiceId');
    
    // Step 1: Create invoice
    print('\n3️⃣ Creating invoice...');
    await connection.execute(
      Sql.named('''
        INSERT INTO invoices (id, booking_id, customer_id, professional_id, total_amount, currency, deposit_percentage, deposit_amount, balance_amount, status, created_at, updated_at)
        VALUES (@id, @bookingId, @customerId, @professionalId, @totalAmount, @currency, @depositPercentage, @depositAmount, @balanceAmount, @status, @createdAt, @updatedAt)
      '''),
      parameters: {
        'id': testInvoiceId,
        'bookingId': testBookingId,
        'customerId': testCustomerId,
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
    
    // Step 2: Check initial balance
    print('\n4️⃣ Checking initial professional balance...');
    final initialBalanceResult = await connection.execute(
      Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
      parameters: {'professionalId': testProfessionalId}
    );
    
    if (initialBalanceResult.isNotEmpty) {
      final balance = initialBalanceResult.first;
      print('   Initial Available Balance: \$${balance[1]}');
      print('   Initial Total Earned: \$${balance[2]}');
      print('   Initial Total Paid Out: \$${balance[3]}');
    } else {
      print('   No initial balance found (will be created on first payment)');
    }
    
    // Step 3: Create and process deposit payment (credit card)
    print('\n5️⃣ Processing deposit payment with credit card...');
    final depositPaymentId = const Uuid().v4();
    
    // Create payment record
    await connection.execute(
      Sql.named('''
        INSERT INTO payment_records (id, invoice_id, booking_id, type, amount, currency, status, payment_method, created_at, updated_at, total_amount)
        VALUES (@id, @invoiceId, @bookingId, @type, @amount, @currency, @status, @paymentMethod, @createdAt, @updatedAt, @totalAmount)
      '''),
      parameters: {
        'id': depositPaymentId,
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
    print('✅ Deposit payment record created');
    
    // Update payment status to paid (this should trigger balance update)
    await connection.execute(
      Sql.named('''
        UPDATE payment_records 
        SET status = @status, processed_at = @processedAt, updated_at = @updatedAt
        WHERE id = @paymentId
      '''),
      parameters: {
        'paymentId': depositPaymentId,
        'status': 'paid',
        'processedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      }
    );
    print('✅ Deposit payment status updated to paid');
    
    // Check balance after deposit payment
    final balanceAfterDepositResult = await connection.execute(
      Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
      parameters: {'professionalId': testProfessionalId}
    );
    
    if (balanceAfterDepositResult.isNotEmpty) {
      final balance = balanceAfterDepositResult.first;
      print('\n📊 Balance after deposit payment:');
      print('   Available Balance: \$${balance[1]}');
      print('   Total Earned: \$${balance[2]}');
      print('   Total Paid Out: \$${balance[3]}');
      
      // Verify the balance was updated correctly
      final availableBalance = double.parse(balance[1].toString());
      final totalEarned = double.parse(balance[2].toString());
      
      if (availableBalance == 100.0 && totalEarned == 100.0) {
        print('✅ Deposit payment balance update CORRECT!');
      } else {
        print('❌ Deposit payment balance update INCORRECT');
        print('   Expected: Available=\$100, Total=\$100');
        print('   Got: Available=\$${availableBalance}, Total=\$${totalEarned}');
      }
    } else {
      print('❌ No balance found after deposit payment');
    }
    
    // Step 4: Process balance payment (credit card)
    print('\n6️⃣ Processing balance payment with credit card...');
    final balancePaymentId = const Uuid().v4();
    
    // Create balance payment record
    await connection.execute(
      Sql.named('''
        INSERT INTO payment_records (id, invoice_id, booking_id, type, amount, currency, status, payment_method, created_at, updated_at, total_amount)
        VALUES (@id, @invoiceId, @bookingId, @type, @amount, @currency, @status, @paymentMethod, @createdAt, @updatedAt, @totalAmount)
      '''),
      parameters: {
        'id': balancePaymentId,
        'invoiceId': testInvoiceId,
        'bookingId': testBookingId,
        'type': 'balance',
        'amount': 400.0,
        'currency': 'JMD',
        'status': 'pending',
        'paymentMethod': 'credit_card',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'totalAmount': 500.0,
      }
    );
    print('✅ Balance payment record created');
    
    // Update balance payment status to paid
    await connection.execute(
      Sql.named('''
        UPDATE payment_records 
        SET status = @status, processed_at = @processedAt, updated_at = @updatedAt
        WHERE id = @paymentId
      '''),
      parameters: {
        'paymentId': balancePaymentId,
        'status': 'paid',
        'processedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      }
    );
    print('✅ Balance payment status updated to paid');
    
    // Check final balance
    final finalBalanceResult = await connection.execute(
      Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
      parameters: {'professionalId': testProfessionalId}
    );
    
    if (finalBalanceResult.isNotEmpty) {
      final balance = finalBalanceResult.first;
      print('\n📊 Final balance after both payments:');
      print('   Available Balance: \$${balance[1]}');
      print('   Total Earned: \$${balance[2]}');
      print('   Total Paid Out: \$${balance[3]}');
      
      // Verify the final balance
      final availableBalance = double.parse(balance[1].toString());
      final totalEarned = double.parse(balance[2].toString());
      
      if (availableBalance == 500.0 && totalEarned == 500.0) {
        print('✅ Final balance CORRECT!');
        print('   Available balance matches total amount earned');
      } else {
        print('❌ Final balance INCORRECT');
        print('   Expected: Available=\$500, Total=\$500');
        print('   Got: Available=\$${availableBalance}, Total=\$${totalEarned}');
      }
    } else {
      print('❌ No final balance found');
    }
    
    // Step 5: Test cash payment (should not update balance)
    print('\n7️⃣ Testing cash payment (should not update balance)...');
    final cashBookingId = 'cash_booking_${DateTime.now().millisecondsSinceEpoch}';
    final cashInvoiceId = const Uuid().v4();
    final cashPaymentId = const Uuid().v4();
    
    // Use a different professional ID for cash payment test to avoid interference
    final cashProfessionalId = 'cash_prof_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create cash invoice
    await connection.execute(
      Sql.named('''
        INSERT INTO invoices (id, booking_id, customer_id, professional_id, total_amount, currency, deposit_percentage, deposit_amount, balance_amount, status, created_at, updated_at)
        VALUES (@id, @bookingId, @customerId, @professionalId, @totalAmount, @currency, @depositPercentage, @depositAmount, @balanceAmount, @status, @createdAt, @updatedAt)
      '''),
      parameters: {
        'id': cashInvoiceId,
        'bookingId': cashBookingId,
        'customerId': testCustomerId,
        'professionalId': cashProfessionalId,
        'totalAmount': 200.0,
        'currency': 'JMD',
        'depositPercentage': 0,
        'depositAmount': 0.0,
        'balanceAmount': 200.0,
        'status': 'sent',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      }
    );
    
    // Create cash payment record
    await connection.execute(
      Sql.named('''
        INSERT INTO payment_records (id, invoice_id, booking_id, type, amount, currency, status, payment_method, created_at, updated_at, total_amount)
        VALUES (@id, @invoiceId, @bookingId, @type, @amount, @currency, @status, @paymentMethod, @createdAt, @updatedAt, @totalAmount)
      '''),
      parameters: {
        'id': cashPaymentId,
        'invoiceId': cashInvoiceId,
        'bookingId': cashBookingId,
        'type': 'full',
        'amount': 200.0,
        'currency': 'JMD',
        'status': 'pending',
        'paymentMethod': 'cash',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'totalAmount': 200.0,
      }
    );
    
    // Update cash payment status to paid
    await connection.execute(
      Sql.named('''
        UPDATE payment_records 
        SET status = @status, processed_at = @processedAt, updated_at = @updatedAt
        WHERE id = @paymentId
      '''),
      parameters: {
        'paymentId': cashPaymentId,
        'status': 'paid',
        'processedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      }
    );
    
    // Check balance after cash payment
    final balanceAfterCashResult = await connection.execute(
      Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
      parameters: {'professionalId': cashProfessionalId}
    );
    
    if (balanceAfterCashResult.isNotEmpty) {
      final balance = balanceAfterCashResult.first;
      final availableBalance = double.parse(balance[1].toString());
      final totalEarned = double.parse(balance[2].toString());
      
      print('📊 Balance after cash payment:');
      print('   Available Balance: \$${balance[1]}');
      print('   Total Earned: \$${balance[2]}');
      print('   Total Paid Out: \$${balance[3]}');
      
      // Verify cash payment didn't update available balance
      if (availableBalance == 500.0) {
        print('✅ Cash payment handled CORRECTLY: No balance update for cash payment');
      } else {
        print('❌ Cash payment handled INCORRECTLY: Balance was updated for cash payment');
      }
    }
    
    // Step 6: Test cash-out functionality
    print('\n8️⃣ Testing cash-out functionality...');
    final balanceBeforeCashOutResult = await connection.execute(
      Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
      parameters: {'professionalId': testProfessionalId}
    );
    
    if (balanceBeforeCashOutResult.isNotEmpty) {
      final balance = balanceBeforeCashOutResult.first;
      final availableBalance = double.parse(balance[1].toString());
      
      if (availableBalance > 0) {
        print('   Requesting cash-out of \$${availableBalance}...');
        
        // Create payout record
        final payoutId = const Uuid().v4();
        await connection.execute(
          Sql.named('''
            INSERT INTO payouts (id, professional_id, amount, currency, status, created_at)
            VALUES (@id, @professionalId, @amount, @currency, @status, @createdAt)
          '''),
          parameters: {
            'id': payoutId,
            'professionalId': testProfessionalId,
            'amount': availableBalance,
            'currency': 'JMD',
            'status': 'pending',
            'createdAt': DateTime.now(),
          }
        );
        
        // Update payout status to success (this should trigger balance update)
        await connection.execute(
          Sql.named('''
            UPDATE payouts 
            SET status = @status, completed_at = @completedAt
            WHERE id = @payoutId
          '''),
          parameters: {
            'payoutId': payoutId,
            'status': 'success',
            'completedAt': DateTime.now(),
          }
        );
        
        // Check balance after cash-out
        final balanceAfterCashOutResult = await connection.execute(
          Sql.named('SELECT * FROM professional_balances WHERE professional_id = @professionalId'),
          parameters: {'professionalId': testProfessionalId}
        );
        
        if (balanceAfterCashOutResult.isNotEmpty) {
          final balance = balanceAfterCashOutResult.first;
          final availableBalanceAfter = double.parse(balance[1].toString());
          final totalPaidOut = double.parse(balance[3].toString());
          
          print('📊 Balance after cash-out:');
          print('   Available Balance: \$${balance[1]}');
          print('   Total Earned: \$${balance[2]}');
          print('   Total Paid Out: \$${balance[3]}');
          
          if (availableBalanceAfter == 0.0 && totalPaidOut == availableBalance) {
            print('✅ Cash-out handled CORRECTLY: Available balance reset to 0');
          } else {
            print('❌ Cash-out handled INCORRECTLY');
            print('   Expected: Available=\$0, Total Paid Out=\$${availableBalance}');
            print('   Got: Available=\$${availableBalanceAfter}, Total Paid Out=\$${totalPaidOut}');
          }
        }
      } else {
        print('ℹ️ No available balance for cash-out test');
      }
    }
    
    // Clean up test data
    print('\n9️⃣ Cleaning up test data...');
    try {
      await connection.execute(
        Sql.named('DELETE FROM payment_records WHERE booking_id IN (@bookingId1, @bookingId2)'),
        parameters: {'bookingId1': testBookingId, 'bookingId2': cashBookingId}
      );
      await connection.execute(
        Sql.named('DELETE FROM invoices WHERE booking_id IN (@bookingId1, @bookingId2)'),
        parameters: {'bookingId1': testBookingId, 'bookingId2': cashBookingId}
      );
      await connection.execute(
        Sql.named('DELETE FROM payouts WHERE professional_id IN (@professionalId1, @professionalId2)'),
        parameters: {'professionalId1': testProfessionalId, 'professionalId2': cashProfessionalId}
      );
      await connection.execute(
        Sql.named('DELETE FROM professional_balances WHERE professional_id IN (@professionalId1, @professionalId2)'),
        parameters: {'professionalId1': testProfessionalId, 'professionalId2': cashProfessionalId}
      );
      print('✅ Test data cleaned up');
    } catch (e) {
      print('⚠️ Error cleaning up test data: $e');
    }
    
    await connection.close();
    print('\n🎉 Balance tracking test completed successfully!');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
