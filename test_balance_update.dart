import 'dart:io';
import 'package:postgres/postgres.dart';
import 'lib/services/payment_workflow_service.dart';
import 'lib/services/payout_service.dart';
import 'lib/models/payment_models.dart';
import 'lib/models/invoice_models.dart';

/// Test script to verify balance updates after credit card payments
Future<void> main() async {
  print('🧪 Testing Balance Updates After Credit Card Payments\n');
  
  try {
    // Initialize services
    final paymentWorkflow = PaymentWorkflowService.instance;
    final payoutService = PayoutService.instance;
    
    await paymentWorkflow.initialize();
    await payoutService.initialize();
    
    // Test professional ID
    const String testProfessionalId = 'test_professional_123';
    const String testCustomerId = 'test_customer_456';
    const String testBookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    
    print('📋 Test Setup:');
    print('  Professional ID: $testProfessionalId');
    print('  Customer ID: $testCustomerId');
    print('  Booking ID: $testBookingId');
    print('');
    
    // Step 1: Create invoice
    print('1️⃣ Creating invoice...');
    final invoice = await paymentWorkflow.createInvoiceFromBooking(
      bookingId: testBookingId,
      customerId: testCustomerId,
      professionalId: testProfessionalId,
      totalAmount: 500.0,
      depositPercentage: 20, // 20% deposit = $100
      currency: 'JMD',
      notes: 'Test invoice for balance tracking',
    );
    print('✅ Invoice created: ${invoice.id}');
    print('   Total Amount: \$${invoice.totalAmount}');
    print('   Deposit Amount: \$${invoice.depositAmount}');
    print('   Balance Amount: \$${invoice.balanceAmount}');
    print('');
    
    // Step 2: Check initial balance
    print('2️⃣ Checking initial professional balance...');
    final initialBalance = await payoutService.getProfessionalBalance(testProfessionalId);
    if (initialBalance != null) {
      print('✅ Initial balance found:');
      print('   Available Balance: \$${initialBalance.availableBalance}');
      print('   Total Earned: \$${initialBalance.totalEarned}');
      print('   Total Paid Out: \$${initialBalance.totalPaidOut}');
    } else {
      print('ℹ️ No initial balance found (will be created on first payment)');
    }
    print('');
    
    // Step 3: Process deposit payment with credit card
    print('3️⃣ Processing deposit payment with credit card...');
    final depositPayment = await paymentWorkflow.processDepositPayment(
      bookingId: testBookingId,
      paymentMethod: PaymentMethod.creditCard,
      notes: 'Test credit card deposit payment',
    );
    print('✅ Deposit payment processed: ${depositPayment.id}');
    print('   Amount: \$${depositPayment.amount}');
    print('   Status: ${depositPayment.status.name}');
    print('   Payment Method: ${depositPayment.paymentMethod?.name}');
    print('');
    
    // Step 4: Check balance after deposit payment
    print('4️⃣ Checking balance after deposit payment...');
    final balanceAfterDeposit = await payoutService.getProfessionalBalance(testProfessionalId);
    if (balanceAfterDeposit != null) {
      print('✅ Balance after deposit:');
      print('   Available Balance: \$${balanceAfterDeposit.availableBalance}');
      print('   Total Earned: \$${balanceAfterDeposit.totalEarned}');
      print('   Total Paid Out: \$${balanceAfterDeposit.totalPaidOut}');
      
      // Verify the balance was updated correctly
      if (balanceAfterDeposit.availableBalance == invoice.depositAmount) {
        print('✅ Balance update CORRECT: Available balance matches deposit amount');
      } else {
        print('❌ Balance update INCORRECT: Expected \$${invoice.depositAmount}, got \$${balanceAfterDeposit.availableBalance}');
      }
    } else {
      print('❌ Failed to get balance after deposit payment');
    }
    print('');
    
    // Step 5: Process balance payment with credit card
    print('5️⃣ Processing balance payment with credit card...');
    final balancePayment = await paymentWorkflow.processBalancePayment(
      bookingId: testBookingId,
      paymentMethod: PaymentMethod.creditCard,
      notes: 'Test credit card balance payment',
    );
    print('✅ Balance payment processed: ${balancePayment.id}');
    print('   Amount: \$${balancePayment.amount}');
    print('   Status: ${balancePayment.status.name}');
    print('   Payment Method: ${balancePayment.paymentMethod?.name}');
    print('');
    
    // Step 6: Check final balance
    print('6️⃣ Checking final balance after both payments...');
    final finalBalance = await payoutService.getProfessionalBalance(testProfessionalId);
    if (finalBalance != null) {
      print('✅ Final balance:');
      print('   Available Balance: \$${finalBalance.availableBalance}');
      print('   Total Earned: \$${finalBalance.totalEarned}');
      print('   Total Paid Out: \$${finalBalance.totalPaidOut}');
      
      // Verify the final balance
      final expectedTotalEarned = invoice.totalAmount;
      final expectedAvailableBalance = invoice.totalAmount;
      
      if (finalBalance.totalEarned == expectedTotalEarned) {
        print('✅ Total earned CORRECT: \$${finalBalance.totalEarned}');
      } else {
        print('❌ Total earned INCORRECT: Expected \$${expectedTotalEarned}, got \$${finalBalance.totalEarned}');
      }
      
      if (finalBalance.availableBalance == expectedAvailableBalance) {
        print('✅ Available balance CORRECT: \$${finalBalance.availableBalance}');
      } else {
        print('❌ Available balance INCORRECT: Expected \$${expectedAvailableBalance}, got \$${finalBalance.availableBalance}');
      }
    } else {
      print('❌ Failed to get final balance');
    }
    print('');
    
    // Step 7: Test cash payment (should not update balance)
    print('7️⃣ Testing cash payment (should not update balance)...');
    const String cashBookingId = 'cash_booking_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create invoice for cash payment
    final cashInvoice = await paymentWorkflow.createInvoiceFromBooking(
      bookingId: cashBookingId,
      customerId: testCustomerId,
      professionalId: testProfessionalId,
      totalAmount: 200.0,
      depositPercentage: 0, // No deposit
      currency: 'JMD',
      notes: 'Test cash payment invoice',
    );
    
    // Process cash payment
    final cashPayment = await paymentWorkflow.processDepositPayment(
      bookingId: cashBookingId,
      paymentMethod: PaymentMethod.cash,
      notes: 'Test cash payment',
    );
    
    // Check balance after cash payment
    final balanceAfterCash = await payoutService.getProfessionalBalance(testProfessionalId);
    if (balanceAfterCash != null) {
      print('✅ Balance after cash payment:');
      print('   Available Balance: \$${balanceAfterCash.availableBalance}');
      print('   Total Earned: \$${balanceAfterCash.totalEarned}');
      print('   Total Paid Out: \$${balanceAfterCash.totalPaidOut}');
      
      // Verify cash payment didn't update balance
      if (balanceAfterCash.availableBalance == finalBalance?.availableBalance) {
        print('✅ Cash payment handled CORRECTLY: No balance update for cash payment');
      } else {
        print('❌ Cash payment handled INCORRECTLY: Balance was updated for cash payment');
      }
    }
    print('');
    
    // Step 8: Test cash-out functionality
    print('8️⃣ Testing cash-out functionality...');
    if (finalBalance != null && finalBalance.availableBalance > 0) {
      final cashOutAmount = finalBalance.availableBalance;
      print('   Requesting cash-out of \$${cashOutAmount}...');
      
      final cashOutResponse = await payoutService.requestCashOut(
        professionalId: testProfessionalId,
        amount: cashOutAmount,
        metadata: {'test': true},
      );
      
      if (cashOutResponse.success) {
        print('✅ Cash-out request successful: ${cashOutResponse.payout?.id}');
        
        // Check balance after cash-out
        final balanceAfterCashOut = await payoutService.getProfessionalBalance(testProfessionalId);
        if (balanceAfterCashOut != null) {
          print('   Balance after cash-out:');
          print('   Available Balance: \$${balanceAfterCashOut.availableBalance}');
          print('   Total Earned: \$${balanceAfterCashOut.totalEarned}');
          print('   Total Paid Out: \$${balanceAfterCashOut.totalPaidOut}');
          
          if (balanceAfterCashOut.availableBalance == 0.0) {
            print('✅ Cash-out handled CORRECTLY: Available balance reset to 0');
          } else {
            print('❌ Cash-out handled INCORRECTLY: Available balance should be 0');
          }
        }
      } else {
        print('❌ Cash-out request failed: ${cashOutResponse.error}');
      }
    } else {
      print('ℹ️ No available balance for cash-out test');
    }
    print('');
    
    print('🎉 Balance tracking test completed!');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    // Clean up
    try {
      await PaymentWorkflowService.instance.close();
      await PayoutService.instance.close();
    } catch (e) {
      print('⚠️ Error during cleanup: $e');
    }
  }
}
