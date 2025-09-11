import 'package:postgres/postgres.dart';

void main() async {
  try {
    print('🔍 Testing PostgreSQL connection...');
    
    // Try with explicit SSL disable
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
    
    print('✅ Connected to PostgreSQL successfully!');
    
    // Test a simple query
    final result = await connection.execute('SELECT 1 as test');
    print('✅ Query test successful');
    
    await connection.close();
    print('🔌 Connection closed');
  } catch (e) {
    print('❌ Connection failed: $e');
    
    // Try alternative connection method
    try {
      print('\n🔄 Trying alternative connection method...');
      final connection = await Connection.open(
        Endpoint(
          host: '192.168.0.53',
          port: 5432,
          database: 'vehicle_damage_payments',
          username: 'postgres',
          password: '#!Startpos12',
        ),
      );
      print('✅ Alternative connection successful!');
      await connection.close();
    } catch (e2) {
      print('❌ Alternative connection also failed: $e2');
    }
  }
}
