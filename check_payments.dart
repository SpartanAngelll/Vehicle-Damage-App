import 'package:postgres/postgres.dart';

void main() async {
  try {
    print('🔍 Checking payments in PostgreSQL database...');
    
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
    
    // Check payments table
    final payments = await connection.execute('SELECT COUNT(*) FROM payments');
    final paymentCount = payments.first[0] as int;
    print('📊 Total payments in database: $paymentCount');
    
    if (paymentCount > 0) {
      // Show recent payments
      final recentPayments = await connection.execute('''
        SELECT booking_id, customer_id, amount, currency, status, created_at 
        FROM payments 
        ORDER BY created_at DESC 
        LIMIT 5
      ''');
      
      print('\n📋 Recent payments:');
      for (final payment in recentPayments) {
        print('  - Booking: ${payment[0]} | Amount: ${payment[2]} ${payment[3]} | Status: ${payment[4]} | Date: ${payment[5]}');
      }
    } else {
      print('📝 No payments found in database');
      print('💡 Create a booking in the app to generate payment records');
    }
    
    // Check payment status history
    final history = await connection.execute('SELECT COUNT(*) FROM payment_status_history');
    final historyCount = history.first[0] as int;
    print('\n📈 Payment status history entries: $historyCount');
    
    await connection.close();
    print('\n✅ Database check complete');
    
  } catch (e) {
    print('❌ Database check failed: $e');
  }
}
