import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Testing PostgreSQL Connection...');
  
  // Test different hosts
  final hosts = ['localhost', '192.168.0.53', '10.0.2.2'];
  final port = 5432;
  final database = 'vehicle_damage_payments';
  final username = 'postgres';
  final password = '#!Startpos12';
  
  for (final host in hosts) {
    print('\n📡 Testing connection to $host:$port...');
    
    try {
      final connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      
      // Test the connection
      final result = await connection.execute('SELECT 1');
      await connection.close();
      
      print('✅ SUCCESS: Connected to $host:$port');
      print('   Database: $database');
      print('   Username: $username');
      break; // Stop on first successful connection
      
    } catch (e) {
      print('❌ FAILED: $host:$port - $e');
    }
  }
  
  print('\n💡 If all connections failed:');
  print('   1. Make sure PostgreSQL is installed and running');
  print('   2. Check if port 5432 is open');
  print('   3. Verify username/password');
  print('   4. Create database: CREATE DATABASE vehicle_damage_payments;');
}
