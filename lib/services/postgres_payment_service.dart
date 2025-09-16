import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_models.dart';

class PostgresPaymentService {
  static PostgresPaymentService? _instance;
  Connection? _connection;
  // Database configuration with environment variable support
  int get _port => int.tryParse(Platform.environment['POSTGRES_PORT'] ?? '5432') ?? 5432;
  String get _database => Platform.environment['POSTGRES_DB'] ?? 'vehicle_damage_payments';
  String get _username => Platform.environment['POSTGRES_USER'] ?? 'postgres';
  String get _password => Platform.environment['POSTGRES_PASSWORD'] ?? '#!Startpos12';
  
  // Dynamic host based on platform
  String get _host {
    if (kIsWeb) {
      return 'localhost'; // Web platform
    } else if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      return _isEmulator() ? '10.0.2.2' : '192.168.0.53';
    } else if (Platform.isIOS) {
      // iOS simulator or physical device
      return _isSimulator() ? 'localhost' : '192.168.0.53';
    } else {
      return 'localhost'; // Desktop platforms
    }
  }
  
  // Helper method to get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'platform': Platform.operatingSystem,
      'host': _host,
      'port': _port,
      'database': _database,
      'username': _username,
      'isEmulator': Platform.isAndroid ? _isEmulator() : null,
      'isSimulator': Platform.isIOS ? _isSimulator() : null,
      'hostDescription': _getHostDescription(),
      'environment': _getEnvironmentInfo(),
    };
  }
  
  // Get human-readable host description
  String _getHostDescription() {
    if (kIsWeb) {
      return 'Web platform (localhost)';
    } else if (Platform.isAndroid) {
      return _isEmulator() ? 'Android Emulator (10.0.2.2)' : 'Android Physical Device (192.168.0.53)';
    } else if (Platform.isIOS) {
      return _isSimulator() ? 'iOS Simulator (localhost)' : 'iOS Physical Device (192.168.0.53)';
    } else {
      return 'Desktop Platform (localhost)';
    }
  }
  
  // Get environment variable info
  String _getEnvironmentInfo() {
    final envVars = <String>[];
    if (Platform.environment.containsKey('POSTGRES_HOST')) envVars.add('HOST');
    if (Platform.environment.containsKey('POSTGRES_PORT')) envVars.add('PORT');
    if (Platform.environment.containsKey('POSTGRES_DB')) envVars.add('DB');
    if (Platform.environment.containsKey('POSTGRES_USER')) envVars.add('USER');
    if (Platform.environment.containsKey('POSTGRES_PASSWORD')) envVars.add('PASSWORD');
    
    return envVars.isEmpty ? 'Using defaults' : 'Using env vars: ${envVars.join(', ')}';
  }

  PostgresPaymentService._();

  static PostgresPaymentService get instance {
    _instance ??= PostgresPaymentService._();
    return _instance!;
  }

  // Helper methods to detect emulator/simulator
  bool _isEmulator() {
    if (!Platform.isAndroid) return false;
    try {
      // Check for emulator-specific properties
      final androidInfo = Platform.environment;
      return androidInfo.containsKey('ANDROID_EMULATOR') || 
             androidInfo['ANDROID_EMULATOR'] == '1' ||
             androidInfo.containsKey('ANDROID_SERIAL') && 
             androidInfo['ANDROID_SERIAL']!.contains('emulator');
    } catch (e) {
      // If we can't determine, assume physical device for safety
      return false;
    }
  }

  bool _isSimulator() {
    if (!Platform.isIOS) return false;
    try {
      // Check for simulator-specific properties
      final iosInfo = Platform.environment;
      return iosInfo.containsKey('SIMULATOR_DEVICE_NAME') ||
             iosInfo.containsKey('SIMULATOR_ROOT');
    } catch (e) {
      // If we can't determine, assume physical device for safety
      return false;
    }
  }

  Future<void> initialize() async {
    // If already connected, just return
    if (_connection != null && await isConnected()) {
      print('✅ [PostgresPayment] Already connected to PostgreSQL');
      return;
    }
    
    // Close any existing connection before creating a new one
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (e) {
        print('⚠️ [PostgresPayment] Error closing existing connection: $e');
      }
      _connection = null;
    }
    
    try {
      print('🔍 [PostgresPayment] Attempting to connect to PostgreSQL...');
      print('  Platform: ${Platform.operatingSystem}');
      print('  Host: $_host (${_getHostDescription()})');
      print('  Port: $_port');
      print('  Database: $_database');
      print('  Username: $_username');
      print('  Is Emulator: ${Platform.isAndroid ? _isEmulator() : 'N/A'}');
      print('  Is Simulator: ${Platform.isIOS ? _isSimulator() : 'N/A'}');
      print('  Environment: ${_getEnvironmentInfo()}');
      
      try {
        // Try to connect to the specific database
        print('🔍 [PostgresPayment] Creating connection with Endpoint:');
        print('  Host: $_host');
        print('  Port: $_port');
        print('  Database: $_database');
        
        _connection = await Connection.open(
          Endpoint(
            host: _host,
            port: _port,
            database: _database,
            username: _username,
            password: _password,
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.disable,
          ),
        );
        
        print('✅ [PostgresPayment] Connection created successfully');
      } catch (e) {
        print('⚠️ [PostgresPayment] Failed to connect to specific database, trying to create it...');
        
        // Try to connect to default postgres database to create our database
        final tempConnection = await Connection.open(
          Endpoint(
            host: _host,
            port: _port,
            database: 'postgres',
            username: _username,
            password: _password,
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.disable,
          ),
        );
        
        // Create the database
        await tempConnection.execute('CREATE DATABASE $_database');
        await tempConnection.close();
        
        // Now connect to our database
        _connection = await Connection.open(
          Endpoint(
            host: _host,
            port: _port,
            database: _database,
            username: _username,
            password: _password,
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.disable,
          ),
        );
      }
      
      // Create tables
      await _createTables();
      
      // Test the connection
      await _connection!.execute('SELECT 1');
      print('✅ [PostgresPayment] Connected to PostgreSQL database successfully');
    } catch (e) {
      print('❌ [PostgresPayment] Failed to connect to PostgreSQL: $e');
      print('💡 [PostgresPayment] Troubleshooting tips:');
      print('  Platform: ${Platform.operatingSystem}');
      print('  Host: $_host');
      print('  Port: $_port');
      print('  Database: $_database');
      print('  Username: $_username');
      
      if (e.toString().contains('Connection refused')) {
        print('  🔍 CONNECTION REFUSED - Possible causes:');
        print('    • PostgreSQL is not running on the host');
        print('    • Wrong host IP address');
        print('    • Firewall blocking port $_port');
        print('    • Current host: $_host (${_getHostDescription()})');
        if (Platform.isAndroid && !_isEmulator()) {
          print('    • For physical device: Ensure PC IP is correct (currently: $_host)');
          print('    • Check if PC and device are on same network');
          print('    • Try: ping $_host from your device');
        } else if (Platform.isAndroid && _isEmulator()) {
          print('    • For emulator: Use 10.0.2.2 (currently: $_host)');
          print('    • Make sure PostgreSQL is running on host machine');
        }
      } else if (e.toString().contains('authentication')) {
        print('  🔍 AUTHENTICATION ERROR - Check username/password');
        print('    • Username: $_username');
        print('    • Password: ${_password.substring(0, 3)}***');
      } else if (e.toString().contains('database') && e.toString().contains('does not exist')) {
        print('  🔍 DATABASE NOT FOUND - Run: psql -U $_username -c "CREATE DATABASE $_database;"');
      }
      
      print('  📋 Manual test: psql -h $_host -p $_port -U $_username -d $_database');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('🔌 [PostgresPayment] Disconnected from PostgreSQL');
    }
  }

  Future<bool> isConnected() async {
    try {
      if (_connection == null) return false;
      await _connection!.execute('SELECT 1');
      return true;
    } catch (e) {
      print('❌ [PostgresPayment] Connection check failed: $e');
      return false;
    }
  }

  // Create a new payment record
  Future<Payment> createPayment({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required double amount,
    String currency = 'JMD',
    int depositPercentage = 0,
    String? notes,
  }) async {
    try {
      await _ensureConnected();
      
      final depositAmount = depositPercentage > 0 ? amount * depositPercentage / 100 : null;
      final paymentId = const Uuid().v4();
      final now = DateTime.now();
      
      // Find the corresponding invoice for this booking
      String? invoiceId;
      try {
        final invoiceResult = await _connection!.execute(
          Sql.named('SELECT id FROM invoices WHERE booking_id = @bookingId ORDER BY created_at LIMIT 1'),
          parameters: {'bookingId': bookingId}
        );
        final invoiceRows = await invoiceResult.toList();
        if (invoiceRows.isNotEmpty) {
          invoiceId = invoiceRows.first[0] as String;
          print('🔗 [PostgresPayment] Found invoice $invoiceId for booking $bookingId');
        } else {
          print('⚠️ [PostgresPayment] No invoice found for booking $bookingId, creating payment without invoice link');
        }
      } catch (e) {
        print('⚠️ [PostgresPayment] Error finding invoice for booking $bookingId: $e');
      }
      
      // Use a transaction to ensure atomicity
      await _connection!.runTx((ctx) async {
        // Insert payment record first
        final result = await ctx.execute(
          Sql.named('''
            INSERT INTO payment_records (
              id, invoice_id, booking_id, type, amount, currency, status,
              created_at, updated_at, notes, deposit_percentage, total_amount
            ) VALUES (
              @id, @invoiceId, @bookingId, @type, @amount, @currency, @status,
              @createdAt, @updatedAt, @notes, @depositPercentage, @totalAmount
            ) RETURNING id, created_at, updated_at
          '''),
          parameters: {
            'id': paymentId,
            'invoiceId': invoiceId, // Link to invoice if found
            'bookingId': bookingId,
            'type': 'full', // Default to full payment
            'amount': amount,
            'currency': currency,
            'status': PaymentStatus.pending.name,
            'createdAt': now,
            'updatedAt': now,
            'notes': notes,
            'depositPercentage': depositPercentage,
            'totalAmount': amount, // For full payments, total_amount = amount
          }
        );

        // Add status history in the same transaction
        await ctx.execute(
          Sql.named('''
            INSERT INTO payment_status_history (
              payment_id, status, changed_at, changed_by, notes
            ) VALUES (
              @paymentId, @status, @changedAt, @changedBy, @notes
            )
          '''),
          parameters: {
            'paymentId': paymentId,
            'status': PaymentStatus.pending.name,
            'changedAt': now,
            'changedBy': 'system',
            'notes': 'Payment created',
          }
        );
      });

      // Create payment object for return
      final payment = Payment(
        id: paymentId,
        bookingId: bookingId,
        customerId: customerId,
        professionalId: professionalId,
        amount: amount,
        currency: currency,
        type: PaymentType.full,
        depositPercentage: depositPercentage,
        depositAmount: depositAmount,
        createdAt: now,
        updatedAt: now,
        notes: notes,
      );

      print('✅ [PostgresPayment] Created payment for booking $bookingId');
      return payment;
    } catch (e) {
      print('❌ [PostgresPayment] Failed to create payment: $e');
      rethrow;
    }
  }

  // Get combined payment view for a booking (aggregated across deposit + balance)
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    try {
      await _ensureConnected();

      // Get all payment records for this booking
      final result = await _connection!.execute(
        Sql.named('SELECT * FROM payment_records WHERE booking_id = @bookingId ORDER BY created_at'),
        parameters: {'bookingId': bookingId}
      );

      final rows = await result.toList();
      if (rows.isEmpty) return null;

      // If only one payment record, return it directly
      if (rows.length == 1) {
        return _mapRowToPayment(rows.first);
      }

      // Aggregate multiple payment records
      final payments = rows.map((row) => _mapRowToPayment(row)).toList();
      
      // Find the deposit payment and any balance payment
      final depositPayment = payments.firstWhere(
        (p) => p.type == PaymentType.deposit,
        orElse: () => payments.first,
      );
      
      Payment? balancePayment;
      try {
        balancePayment = payments.firstWhere((p) => p.type == PaymentType.balance);
      } catch (e) {
        balancePayment = null;
      }

      // Calculate aggregated totals
      final totalAmount = depositPayment.originalTotalAmount;
      final depositPaid = depositPayment.status == PaymentStatus.paid ? depositPayment.amount : 0.0;
      final balancePaid = balancePayment?.status == PaymentStatus.paid ? balancePayment!.amount : 0.0;
      final totalPaid = depositPaid + balancePaid;
      final remainingAmount = (totalAmount - totalPaid).clamp(0, double.infinity);
      
      // Determine overall status
      final PaymentStatus overallStatus;
      if (totalPaid >= totalAmount) {
        overallStatus = PaymentStatus.paid;
      } else if (depositPaid > 0) {
        overallStatus = PaymentStatus.pending; // Partially paid
      } else {
        overallStatus = PaymentStatus.pending;
      }
      
      // Calculate required deposit amount
      final depositRequired = depositPayment.depositPercentage > 0 
          ? totalAmount * depositPayment.depositPercentage / 100 
          : 0.0;

      // Create aggregated payment object
      return Payment(
        id: depositPayment.id, // Use deposit payment ID as primary
        bookingId: bookingId,
        customerId: depositPayment.customerId,
        professionalId: depositPayment.professionalId,
        amount: totalPaid, // Total amount paid (deposit + balance)
        currency: depositPayment.currency,
        type: PaymentType.deposit, // Keep as deposit type for UI logic
        depositPercentage: depositPayment.depositPercentage,
        depositAmount: depositRequired, // Required deposit amount (not paid amount)
        totalAmount: totalAmount,
        status: overallStatus, // Use overall status (paid when fully paid)
        paymentMethod: balancePayment?.paymentMethod ?? depositPayment.paymentMethod,
        transactionId: balancePayment?.transactionId ?? depositPayment.transactionId,
        createdAt: depositPayment.createdAt,
        updatedAt: balancePayment?.updatedAt ?? depositPayment.updatedAt,
        paidAt: overallStatus == PaymentStatus.paid ? (balancePayment?.paidAt ?? depositPayment.paidAt) : null,
        refundedAt: null,
        refundAmount: null,
        notes: 'Combined payment view',
      );
    } catch (e) {
      print('❌ [PostgresPayment] Failed to get payment by booking ID: $e');
      return null;
    }
  }

  // Get payments by customer ID
  Future<List<Payment>> getPaymentsByCustomerId(String customerId) async {
    try {
      await _ensureConnected();
      
      final result = await _connection!.execute(
        Sql.named('SELECT * FROM payment_records WHERE booking_id LIKE @customerId ORDER BY created_at DESC'),
        parameters: {'customerId': '$customerId%'}
      );

      final rows = await result.toList();
      return rows.map((row) => _mapRowToPayment(row)).toList();
    } catch (e) {
      print('❌ [PostgresPayment] Failed to get payments by customer ID: $e');
      return [];
    }
  }

  // Get payments by professional ID
  Future<List<Payment>> getPaymentsByProfessionalId(String professionalId) async {
    try {
      await _ensureConnected();
      
      final result = await _connection!.execute(
        Sql.named('SELECT * FROM payment_records WHERE booking_id LIKE @professionalId ORDER BY created_at DESC'),
        parameters: {'professionalId': '$professionalId%'}
      );

      final rows = await result.toList();
      return rows.map((row) => _mapRowToPayment(row)).toList();
    } catch (e) {
      print('❌ [PostgresPayment] Failed to get payments by professional ID: $e');
      return [];
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? transactionId,
    PaymentMethod? paymentMethod,
    String? notes,
    String? changedBy,
  }) async {
    try {
      await _ensureConnected();
      
      final now = DateTime.now();
      final statusUpdateFields = <String, dynamic>{
        'status': status.name,
        'updated_at': now,
      };

      if (status == PaymentStatus.paid) {
        statusUpdateFields['processed_at'] = now;
      }

      if (transactionId != null) {
        statusUpdateFields['transaction_id'] = transactionId;
      }

      if (paymentMethod != null) {
        statusUpdateFields['payment_method'] = paymentMethod.name;
      }

      if (notes != null) {
        statusUpdateFields['notes'] = notes;
      }

      final setClause = statusUpdateFields.keys.map((key) => '$key = @$key').join(', ');
      
      // Use transaction to ensure atomicity
      await _connection!.runTx((ctx) async {
        // Update payment record
        await ctx.execute(
          Sql.named('UPDATE payment_records SET $setClause WHERE id = @paymentId'),
          parameters: {
            'paymentId': paymentId,
            ...statusUpdateFields,
          }
        );

        // Add status history in the same transaction
        await ctx.execute(
          Sql.named('''
            INSERT INTO payment_status_history (
              payment_id, status, changed_at, changed_by, notes
            ) VALUES (
              @paymentId, @status, @changedAt, @changedBy, @notes
            )
          '''),
          parameters: {
            'paymentId': paymentId,
            'status': status.name,
            'changedAt': now,
            'changedBy': changedBy ?? 'system',
            'notes': notes,
          }
        );
      });

      print('✅ [PostgresPayment] Updated payment $paymentId status to ${status.name}');
      return true;
    } catch (e) {
      print('❌ [PostgresPayment] Failed to update payment status: $e');
      return false;
    }
  }

  // Process mock payment
  Future<bool> processMockPayment({
    required String paymentId,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      final transactionId = 'MOCK_${DateTime.now().millisecondsSinceEpoch}';
      
      return await updatePaymentStatus(
        paymentId: paymentId,
        status: PaymentStatus.paid,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        notes: notes ?? 'Mock payment processed successfully',
        changedBy: 'system',
      );
    } catch (e) {
      print('❌ [PostgresPayment] Failed to process mock payment: $e');
      return false;
    }
  }

  // Request deposit
  Future<bool> requestDeposit({
    required String bookingId,
    required String professionalId,
    required int depositPercentage,
    required String reason,
  }) async {
    try {
      await _ensureConnected();
      
      // Check if payment already exists
      final existingPayment = await getPaymentByBookingId(bookingId);
      if (existingPayment != null) {
        // Calculate deposit amount from the original total amount
        final totalAmount = existingPayment.amount; // This is the original total
        final depositAmount = totalAmount * depositPercentage / 100;
        
        // Update existing payment with deposit request
        await _connection!.runTx((ctx) async {
          // Update payment record - preserve total_amount, set amount to deposit amount
          await ctx.execute(
            Sql.named('''
              UPDATE payment_records 
              SET type = @type,
                  total_amount = @totalAmount,
                  amount = @depositAmount,
                  deposit_percentage = @depositPercentage,
                  updated_at = @updatedAt,
                  notes = @notes
              WHERE booking_id = @bookingId
            '''),
            parameters: {
              'bookingId': bookingId,
              'type': 'deposit',
              'totalAmount': totalAmount,
              'depositAmount': depositAmount,
              'depositPercentage': depositPercentage,
              'updatedAt': DateTime.now(),
              'notes': 'Deposit requested: $reason',
            }
          );

          // Add status history
          await ctx.execute(
            Sql.named('''
              INSERT INTO payment_status_history (
                payment_id, status, changed_at, changed_by, notes
              ) VALUES (
                @paymentId, @status, @changedAt, @changedBy, @notes
              )
            '''),
            parameters: {
              'paymentId': existingPayment.id,
              'status': 'pending',
              'changedAt': DateTime.now(),
              'changedBy': 'professional',
              'notes': 'Deposit requested: $reason',
            }
          );
        });
      } else {
        // This shouldn't happen as payment should be created with booking
        print('⚠️ [PostgresPayment] No payment found for booking $bookingId');
        return false;
      }

      print('✅ [PostgresPayment] Deposit request updated for booking $bookingId');
      return true;
    } catch (e) {
      print('❌ [PostgresPayment] Failed to request deposit: $e');
      return false;
    }
  }

  // Get payment status history
  Future<List<PaymentStatusHistory>> getPaymentStatusHistory(String paymentId) async {
    try {
      await _ensureConnected();
      
      final result = await _connection!.execute(
        Sql.named('''
          SELECT * FROM payment_status_history 
          WHERE payment_id = @paymentId 
          ORDER BY changed_at ASC
        '''),
        parameters: {'paymentId': paymentId}
      );

      final rows = await result.toList();
      return rows.map((row) => PaymentStatusHistory.fromMap({
        'id': row[0],
        'payment_id': row[1],
        'status': row[2],
        'changed_at': row[3],
        'changed_by': row[4],
        'notes': row[5],
      })).toList();
    } catch (e) {
      print('❌ [PostgresPayment] Failed to get payment status history: $e');
      return [];
    }
  }

  // Helper methods
  Future<void> _ensureConnected() async {
    if (!await isConnected()) {
      await initialize();
    }
  }
  
  // Test connection with different hosts (for debugging)
  Future<Map<String, bool>> testConnectionHosts() async {
    final results = <String, bool>{};
    final hosts = ['localhost', '10.0.2.2', '192.168.0.53'];
    
    for (final host in hosts) {
      try {
        print('🔍 Testing connection to $host:$_port...');
        final connection = await Connection.open(
          Endpoint(
            host: host,
            port: _port,
            database: _database,
            username: _username,
            password: _password,
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.disable,
          ),
        );
        
        await connection.execute('SELECT 1');
        await connection.close();
        results[host] = true;
        print('✅ $host:$_port - SUCCESS');
      } catch (e) {
        results[host] = false;
        print('❌ $host:$_port - FAILED: $e');
      }
    }
    
    return results;
  }
  
  // Check if balance payment is required for a booking
  Future<bool> isBalancePaymentRequired(String bookingId) async {
    try {
      await _ensureConnected();
      
      // Get all payment records for this booking
      final result = await _connection!.execute(
        Sql.named('''
          SELECT 
            type, 
            amount, 
            total_amount, 
            deposit_percentage,
            status
          FROM payment_records 
          WHERE booking_id = @bookingId
          ORDER BY created_at
        '''),
        parameters: {'bookingId': bookingId}
      );

      final rows = await result.toList();
      if (rows.isEmpty) {
        print('🔍 [PostgresPayment] No payment records found for booking $bookingId');
        return false;
      }

      // Calculate total paid and total amount
      double totalPaid = 0.0;
      double totalAmount = 0.0;
      
      for (final row in rows) {
        final type = row[0] as String;
        final amount = double.parse(row[1].toString());
        final rowTotalAmount = row[2] != null ? double.parse(row[2].toString()) : amount;
        final status = row[4] as String;
        
        if (status == 'paid') {
          totalPaid += amount;
        }
        
        // Use the total amount from any record (they should all be the same)
        if (totalAmount == 0.0) {
          totalAmount = rowTotalAmount;
        }
      }

      print('🔍 [PostgresPayment] Payment check for booking $bookingId:');
      print('  Total Amount: $totalAmount');
      print('  Total Paid: $totalPaid');
      print('  Remaining: ${totalAmount - totalPaid}');

      final remainingAmount = totalAmount - totalPaid;
      return remainingAmount > 0;
    } catch (e) {
      print('❌ [PostgresPayment] Failed to check balance payment requirement: $e');
      return false;
    }
  }
  
  // Process balance payment after deposit has been paid
  Future<Payment> processBalancePayment({
    required String bookingId,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    try {
      await _ensureConnected();
      
      // Get the existing payment record
      final existingPayment = await getPaymentByBookingId(bookingId);
      if (existingPayment == null) {
        throw Exception('No payment record found for booking $bookingId');
      }

      if (existingPayment.type != PaymentType.deposit || existingPayment.status != PaymentStatus.paid) {
        throw Exception('Deposit must be paid before processing balance payment');
      }

      final balanceAmount = existingPayment.remainingAmount;
      if (balanceAmount <= 0) {
        throw Exception('No balance remaining to pay');
      }

      final balancePaymentId = const Uuid().v4();
      final now = DateTime.now();

      // Find the corresponding invoice for this booking
      String? invoiceId;
      try {
        final invoiceResult = await _connection!.execute(
          Sql.named('SELECT id FROM invoices WHERE booking_id = @bookingId ORDER BY created_at LIMIT 1'),
          parameters: {'bookingId': bookingId}
        );
        final invoiceRows = await invoiceResult.toList();
        if (invoiceRows.isNotEmpty) {
          invoiceId = invoiceRows.first[0] as String;
          print('🔗 [PostgresPayment] Found invoice $invoiceId for balance payment booking $bookingId');
        } else {
          print('⚠️ [PostgresPayment] No invoice found for balance payment booking $bookingId');
        }
      } catch (e) {
        print('⚠️ [PostgresPayment] Error finding invoice for balance payment booking $bookingId: $e');
      }

      // Create a new payment record for the balance
      await _connection!.runTx((ctx) async {
        // Insert balance payment record
        await ctx.execute(
          Sql.named('''
            INSERT INTO payment_records (
              id, invoice_id, booking_id, type, amount, currency, status,
              payment_method, created_at, updated_at, notes, deposit_percentage, total_amount
            ) VALUES (
              @id, @invoiceId, @bookingId, @type, @amount, @currency, @status,
              @paymentMethod, @createdAt, @updatedAt, @notes, @depositPercentage, @totalAmount
            ) RETURNING id, created_at, updated_at
          '''),
          parameters: {
            'id': balancePaymentId,
            'invoiceId': invoiceId, // Link to invoice if found
            'bookingId': bookingId,
            'type': 'balance',
            'amount': balanceAmount,
            'currency': existingPayment.currency,
            'status': PaymentStatus.pending.name,
            'paymentMethod': paymentMethod.name,
            'createdAt': now,
            'updatedAt': now,
            'notes': notes ?? 'Balance payment',
            'depositPercentage': 0,
            'totalAmount': existingPayment.originalTotalAmount,
          }
        );

        // Add status history
        await ctx.execute(
          Sql.named('''
            INSERT INTO payment_status_history (
              payment_id, status, changed_at, changed_by, notes
            ) VALUES (
              @paymentId, @status, @changedAt, @changedBy, @notes
            )
          '''),
          parameters: {
            'paymentId': balancePaymentId,
            'status': PaymentStatus.pending.name,
            'changedAt': now,
            'changedBy': 'system',
            'notes': 'Balance payment created',
          }
        );
      });

      // Create payment object for return
      final balancePayment = Payment(
        id: balancePaymentId,
        bookingId: bookingId,
        customerId: existingPayment.customerId,
        professionalId: existingPayment.professionalId,
        amount: balanceAmount,
        currency: existingPayment.currency,
        type: PaymentType.balance,
        depositPercentage: 0,
        depositAmount: null,
        totalAmount: existingPayment.originalTotalAmount,
        status: PaymentStatus.pending,
        paymentMethod: paymentMethod,
        createdAt: now,
        updatedAt: now,
        notes: notes,
      );

      print('✅ [PostgresPayment] Created balance payment for booking $bookingId');
      return balancePayment;
    } catch (e) {
      print('❌ [PostgresPayment] Failed to process balance payment: $e');
      rethrow;
    }
  }

  Future<Connection> getConnection() async {
    await _ensureConnected();
    return _connection!;
  }

  Payment _mapRowToPayment(List<dynamic> row) {
    final totalAmount = row[15] != null ? double.parse(row[15] as String) : double.parse(row[4] as String);
    final currentAmount = double.parse(row[4] as String);
    final depositPercentage = row[14] as int;
    
    return Payment(
      id: row[0].toString(),
      bookingId: row[2] as String, // booking_id is now at index 2
      customerId: 'unknown', // We don't store customer_id in payment_records
      professionalId: 'unknown', // We don't store professional_id in payment_records
      amount: currentAmount, // This is the deposit amount for deposit payments
      currency: row[5] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.name == (row[3] as String),
        orElse: () => PaymentType.full,
      ),
      depositPercentage: depositPercentage,
      depositAmount: depositPercentage > 0 ? (totalAmount * depositPercentage / 100) : null,
      totalAmount: totalAmount, // Original total amount
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (row[6] as String),
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: row[7] != null 
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == (row[7] as String),
              orElse: () => PaymentMethod.creditCard,
            )
          : null,
      transactionId: row[8] as String?,
      createdAt: row[9] as DateTime,
      updatedAt: row[10] as DateTime,
      paidAt: row[11] as DateTime?, // processed_at
      refundedAt: null, // Not stored in payment_records
      refundAmount: null, // Not stored in payment_records
      notes: row[12] as String?,
    );
  }

  Future<void> _addStatusHistory(
    String paymentId,
    PaymentStatus status,
    String? notes,
    [String? changedBy]
  ) async {
    try {
      await _connection!.execute(
        Sql.named('''
          INSERT INTO payment_status_history (
            payment_id, status, changed_at, changed_by, notes
          ) VALUES (
            @paymentId, @status, @changedAt, @changedBy, @notes
          )
        '''),
        parameters: {
          'paymentId': paymentId,
          'status': status.name,
          'changedAt': DateTime.now(),
          'changedBy': changedBy ?? 'system',
          'notes': notes,
        }
      );
    } catch (e) {
      print('❌ [PostgresPayment] Failed to add status history: $e');
    }
  }

  Future<void> _createTables() async {
    try {
      print('🔧 [PostgresPayment] Creating database tables...');
      
      // Enable UUID extension
      await _connection!.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
      
      // Create payment_records table (using new schema)
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS payment_records (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          invoice_id UUID,
          booking_id VARCHAR(255) NOT NULL,
          type VARCHAR(50) NOT NULL DEFAULT 'full',
          amount DECIMAL(10,2) NOT NULL,
          currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
          status VARCHAR(50) NOT NULL DEFAULT 'pending',
          payment_method VARCHAR(50),
          transaction_id VARCHAR(255),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          processed_at TIMESTAMP WITH TIME ZONE,
          notes TEXT,
          metadata JSONB,
          deposit_percentage INTEGER DEFAULT 0,
          total_amount NUMERIC
        )
      ''');
      
      // Add missing columns if they don't exist
      await _connection!.execute('ALTER TABLE payment_records ADD COLUMN IF NOT EXISTS deposit_percentage INTEGER DEFAULT 0');
      await _connection!.execute('ALTER TABLE payment_records ADD COLUMN IF NOT EXISTS total_amount NUMERIC');
      await _connection!.execute('ALTER TABLE payment_records ALTER COLUMN invoice_id DROP NOT NULL');
      await _connection!.execute('ALTER TABLE payment_records ALTER COLUMN total_amount DROP NOT NULL');
      
      // Create payment status history table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS payment_status_history (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          payment_id UUID NOT NULL REFERENCES payment_records(id) ON DELETE CASCADE,
          status VARCHAR(50) NOT NULL,
          changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          changed_by VARCHAR(255),
          notes TEXT
        )
      ''');
      
      // Create indexes
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_payment_records_booking_id ON payment_records(booking_id)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_payment_records_status ON payment_records(status)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_payment_records_type ON payment_records(type)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_payment_status_history_payment_id ON payment_status_history(payment_id)');
      
      // Create trigger function
      await _connection!.execute('''
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS \$\$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        \$\$ language 'plpgsql'
      ''');
      
      // Create trigger only if it doesn't already exist
      await _connection!.execute(r'''
        DO $$
        BEGIN
          IF NOT EXISTS (
            SELECT 1
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            WHERE t.tgname = 'update_payment_records_updated_at'
              AND c.relname = 'payment_records'
          ) THEN
            CREATE TRIGGER update_payment_records_updated_at
            BEFORE UPDATE ON payment_records
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
          END IF;
        END
        $$;
      ''');
      
      print('✅ [PostgresPayment] Database tables created successfully');
    } catch (e) {
      print('❌ [PostgresPayment] Failed to create tables: $e');
      rethrow;
    }
  }
}
