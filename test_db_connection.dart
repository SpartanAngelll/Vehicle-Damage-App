import 'package:postgres/postgres.dart';

void main() async {
  try {
    print('🔍 Testing PostgreSQL connection...');
    
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'vehicle_damage_payments',
        username: 'postgres',
        password: '#!Startpos12',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
    
    print('✅ Connected to PostgreSQL successfully!');
    
    // Test a simple query
    final result = await connection.execute('SELECT 1 as test');
    print('✅ Query test successful: ${result}');
    
    await connection.close();
    print('🔌 Connection closed');
  } catch (e) {
    print('❌ Connection failed: $e');
    print('\n💡 Troubleshooting:');
    print('1. Make sure PostgreSQL is running');
    print('2. Check if database "vehicle_damage_payments" exists');
    print('3. Verify username and password');
    print('4. Try running the setup_database_manual.sql script');
  }
}
