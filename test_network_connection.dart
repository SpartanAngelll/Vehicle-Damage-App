import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Testing network connectivity to PostgreSQL...');
  
  // Test basic network connectivity
  try {
    final socket = await Socket.connect('192.168.0.53', 5432, timeout: Duration(seconds: 5));
    print('✅ Network connection to PostgreSQL server successful');
    await socket.close();
  } catch (e) {
    print('❌ Network connection failed: $e');
    print('💡 Make sure:');
    print('  1. PostgreSQL is running on your computer');
    print('  2. Windows Firewall allows port 5432');
    print('  3. Both devices are on the same network');
    return;
  }
  
  // Test PostgreSQL connection
  try {
    print('🔍 Testing PostgreSQL authentication...');
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
    
    print('✅ PostgreSQL connection successful!');
    
    // Test a simple query
    final result = await connection.execute('SELECT 1 as test');
    print('✅ Query test successful');
    
    // Test payment table
    final tables = await connection.execute('''
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'payments'
    ''');
    
    if (tables.isNotEmpty) {
      print('✅ Payments table exists');
    } else {
      print('⚠️ Payments table not found');
    }
    
    await connection.close();
    print('🔌 Connection closed');
    
  } catch (e) {
    print('❌ PostgreSQL connection failed: $e');
    print('💡 Check PostgreSQL configuration and network settings');
  }
}
