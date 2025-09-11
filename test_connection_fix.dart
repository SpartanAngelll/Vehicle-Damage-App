import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Testing PostgreSQL Connection Fix...');
  print('Platform: ${Platform.operatingSystem}');
  print('');
  
  // Test the new host selection logic
  final hosts = <String>[];
  if (Platform.isAndroid) {
    // Check if running on emulator or physical device
    final isEmulator = _isEmulator();
    hosts.add(isEmulator ? '10.0.2.2' : '192.168.0.52');
    print('Android ${isEmulator ? 'Emulator' : 'Physical Device'}: ${hosts.first}');
  } else if (Platform.isIOS) {
    final isSimulator = _isSimulator();
    hosts.add(isSimulator ? 'localhost' : '192.168.0.52');
    print('iOS ${isSimulator ? 'Simulator' : 'Physical Device'}: ${hosts.first}');
  } else {
    hosts.add('localhost');
    print('Desktop/Web: ${hosts.first}');
  }
  
  // Test connection
  final port = 5432;
  final database = 'vehicle_damage_payments';
  final username = 'postgres';
  final password = '#!Startpos12';
  
  for (final host in hosts) {
    print('\n📡 Testing connection to $host:$port...');
    print('  Database: $database');
    print('  Username: $username');
    
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
      print('   This is the correct host for your platform!');
      break;
      
    } catch (e) {
      print('❌ FAILED: $host:$port - $e');
      
      if (e.toString().contains('Connection refused')) {
        print('   💡 PostgreSQL is not running on $host');
        print('   💡 Make sure PostgreSQL is installed and running');
        print('   💡 Check if port $port is open');
      } else if (e.toString().contains('authentication')) {
        print('   💡 Authentication failed - check username/password');
      } else if (e.toString().contains('database') && e.toString().contains('does not exist')) {
        print('   💡 Database does not exist - create it first');
      }
    }
  }
  
  print('\n📋 Next steps:');
  print('1. Install PostgreSQL if not already installed');
  print('2. Start PostgreSQL service');
  print('3. Create database: CREATE DATABASE vehicle_damage_payments;');
  print('4. Test your app again');
}

bool _isEmulator() {
  if (!Platform.isAndroid) return false;
  try {
    final androidInfo = Platform.environment;
    return androidInfo.containsKey('ANDROID_EMULATOR') || 
           androidInfo['ANDROID_EMULATOR'] == '1' ||
           androidInfo.containsKey('ANDROID_SERIAL') && 
           androidInfo['ANDROID_SERIAL']!.contains('emulator');
  } catch (e) {
    return false;
  }
}

bool _isSimulator() {
  if (!Platform.isIOS) return false;
  try {
    final iosInfo = Platform.environment;
    return iosInfo.containsKey('SIMULATOR_DEVICE_NAME') ||
           iosInfo.containsKey('SIMULATOR_ROOT');
  } catch (e) {
    return false;
  }
}
