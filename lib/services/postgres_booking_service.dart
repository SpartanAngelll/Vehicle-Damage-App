import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/booking_models.dart';
import '../models/service.dart';
import 'postgres_payment_service.dart';

/// Service for managing bookings in PostgreSQL
/// Handles booking creation, status updates, PIN management, and payment confirmations
class PostgresBookingService {
  static PostgresBookingService? _instance;
  final PostgresPaymentService _paymentService = PostgresPaymentService.instance;
  
  // Database configuration
  int get _port => int.tryParse(Platform.environment['POSTGRES_PORT'] ?? '5432') ?? 5432;
  String get _database => Platform.environment['POSTGRES_DB'] ?? 'vehicle_damage_payments';
  String get _username => Platform.environment['POSTGRES_USER'] ?? 'postgres';
  String get _password => Platform.environment['POSTGRES_PASSWORD'] ?? '#!Startpos12';
  
  String get _host {
    if (kIsWeb) {
      return 'localhost';
    } else if (Platform.isAndroid) {
      return _isEmulator() ? '10.0.2.2' : '192.168.0.53';
    } else if (Platform.isIOS) {
      return _isSimulator() ? 'localhost' : '192.168.0.53';
    } else {
      return 'localhost';
    }
  }

  PostgresBookingService._();

  static PostgresBookingService get instance {
    _instance ??= PostgresBookingService._();
    return _instance!;
  }

  bool _isEmulator() {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = Platform.environment;
      return androidInfo.containsKey('ANDROID_EMULATOR') || 
             androidInfo['ANDROID_EMULATOR'] == '1';
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

  Future<Connection> _getConnection() async {
    await _paymentService.initialize();
    return await _paymentService.getConnection();
  }

  /// Create a booking in PostgreSQL
  Future<String> createBooking({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required String customerName,
    required String professionalName,
    required String serviceTitle,
    required String serviceDescription,
    required double agreedPrice,
    required String currency,
    required DateTime scheduledStartTime,
    required DateTime scheduledEndTime,
    required String serviceLocation,
    List<String>? deliverables,
    List<String>? importantPoints,
    String? chatRoomId,
    String? estimateId,
    String? notes,
    TravelMode? travelMode,
    String? customerAddress,
    String? shopAddress,
    double? travelFee,
  }) async {
    try {
      final connection = await _getConnection();
      
      // Generate a 4-digit PIN for the customer
      final pin = _generatePin();
      final hashedPin = _hashPin(pin);
      
      // Use booking_id as the primary key (VARCHAR since it comes from Firestore)
      await connection.runTx((ctx) async {
        await ctx.execute(
          Sql.named('''
            INSERT INTO bookings (
              id, customer_id, professional_id, customer_name, professional_name,
              service_title, service_description, agreed_price, currency,
              scheduled_start_time, scheduled_end_time, service_location,
              deliverables, important_points, chat_room_id, estimate_id,
              status, start_pin_hash, notes, travel_mode, customer_address,
              shop_address, travel_fee, created_at, updated_at
            ) VALUES (
              @id, @customerId, @professionalId, @customerName, @professionalName,
              @serviceTitle, @serviceDescription, @agreedPrice, @currency,
              @scheduledStartTime, @scheduledEndTime, @serviceLocation,
              @deliverables, @importantPoints, @chatRoomId, @estimateId,
              @status, @startPinHash, @notes, @travelMode, @customerAddress,
              @shopAddress, @travelFee, @createdAt, @updatedAt
            )
            ON CONFLICT (id) DO UPDATE SET
              agreed_price = EXCLUDED.agreed_price,
              status = EXCLUDED.status,
              updated_at = EXCLUDED.updated_at
          '''),
          parameters: {
            'id': bookingId,
            'customerId': customerId,
            'professionalId': professionalId,
            'customerName': customerName,
            'professionalName': professionalName,
            'serviceTitle': serviceTitle,
            'serviceDescription': serviceDescription,
            'agreedPrice': agreedPrice,
            'currency': currency,
            'scheduledStartTime': scheduledStartTime,
            'scheduledEndTime': scheduledEndTime,
            'serviceLocation': serviceLocation,
            'deliverables': deliverables ?? [],
            'importantPoints': importantPoints ?? [],
            'chatRoomId': chatRoomId,
            'estimateId': estimateId,
            'status': 'confirmed',
            'startPinHash': hashedPin,
            'notes': notes,
            'travelMode': _mapTravelModeToDb(travelMode),
            'customerAddress': customerAddress,
            'shopAddress': shopAddress,
            'travelFee': travelFee ?? 0.0,
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          }
        );
      });

      print('✅ [PostgresBooking] Booking created in PostgreSQL: $bookingId');
      print('🔐 [PostgresBooking] PIN generated (hashed): ${pin.substring(0, 2)}**');
      
      // Return the PIN so it can be shown to the customer
      return pin;
    } catch (e) {
      print('❌ [PostgresBooking] Failed to create booking: $e');
      rethrow;
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? statusNotes,
    String? updatedBy,
  }) async {
    try {
      final connection = await _getConnection();
      final now = DateTime.now();
      
      // Map status to appropriate timestamp field
      String? timestampField;
      switch (status) {
        case 'on_my_way':
          timestampField = 'on_my_way_at';
          break;
        case 'in_progress':
        case 'started':
          timestampField = 'job_started_at';
          break;
        case 'completed':
          timestampField = 'job_completed_at';
          break;
        case 'reviewed':
          timestampField = 'job_accepted_at';
          break;
      }

      final updateFields = <String, dynamic>{
        'status': status,
        'updated_at': now,
      };

      if (statusNotes != null) {
        updateFields['status_notes'] = statusNotes;
      }

      if (timestampField != null) {
        updateFields[timestampField] = now;
      }

      final setClause = updateFields.keys.map((key) => '$key = @$key').join(', ');
      
      await connection.execute(
        Sql.named('UPDATE bookings SET $setClause WHERE id = @bookingId'),
        parameters: {
          'bookingId': bookingId,
          ...updateFields,
        }
      );

      print('✅ [PostgresBooking] Updated booking $bookingId status to $status');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to update booking status: $e');
      rethrow;
    }
  }

  /// Set "On My Way" status
  Future<void> setOnMyWay({
    required String bookingId,
    required String userId, // Can be customer or professional
  }) async {
    try {
      final connection = await _getConnection();
      final now = DateTime.now();
      
      // Determine who is traveling based on booking
      final bookingResult = await connection.execute(
        Sql.named('SELECT customer_id, professional_id, travel_mode FROM bookings WHERE id = @bookingId'),
        parameters: {'bookingId': bookingId}
      );
      
      final rows = await bookingResult.toList();
      if (rows.isEmpty) {
        throw Exception('Booking not found');
      }
      
      final row = rows.first;
      final customerId = row[0] as String;
      final professionalId = row[1] as String;
      final travelMode = row[2] as String?;
      
      // Determine who should be traveling
      // Database values: 'customer_location' (customer travels), 'shop_location' (pro travels)
      String? travelingUserId;
      if (travelMode == 'shop_location' || travelMode == null) {
        // Professional is traveling to customer
        travelingUserId = professionalId;
      } else if (travelMode == 'customer_location') {
        // Customer is traveling to shop
        travelingUserId = customerId;
      } else {
        // For remote services, either party can set "on my way" (though it's less common)
        // Default to customer for remote
        travelingUserId = customerId;
      }
      
      // Verify the user setting status is the one who should be traveling
      if (userId != travelingUserId) {
        throw Exception('Only the traveling party can set "On My Way" status');
      }
      
      await connection.execute(
        Sql.named('''
          UPDATE bookings 
          SET status = 'on_my_way', 
              on_my_way_at = @now,
              updated_at = @now
          WHERE id = @bookingId
        '''),
        parameters: {
          'bookingId': bookingId,
          'now': now,
        }
      );

      print('✅ [PostgresBooking] Set "On My Way" status for booking $bookingId');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to set "On My Way" status: $e');
      rethrow;
    }
  }

  /// Verify PIN and start job
  Future<bool> verifyPinAndStartJob({
    required String bookingId,
    required String pin,
  }) async {
    try {
      final connection = await _getConnection();
      
      // Get the hashed PIN from the database
      final result = await connection.execute(
        Sql.named('SELECT start_pin_hash, status FROM bookings WHERE id = @bookingId'),
        parameters: {'bookingId': bookingId}
      );
      
      final rows = await result.toList();
      if (rows.isEmpty) {
        throw Exception('Booking not found');
      }
      
      final row = rows.first;
      final storedHash = row[0] as String?;
      final currentStatus = row[1] as String;
      
      if (storedHash == null) {
        throw Exception('PIN not set for this booking');
      }
      
      // Verify the PIN
      final inputHash = _hashPin(pin);
      if (inputHash != storedHash) {
        print('❌ [PostgresBooking] PIN verification failed for booking $bookingId');
        return false;
      }
      
      // Update status to started/in_progress
      if (currentStatus != 'in_progress' && currentStatus != 'started') {
        await connection.execute(
          Sql.named('''
            UPDATE bookings 
            SET status = 'in_progress',
                job_started_at = @now,
                updated_at = @now
            WHERE id = @bookingId
          '''),
          parameters: {
            'bookingId': bookingId,
            'now': DateTime.now(),
          }
        );
      }
      
      print('✅ [PostgresBooking] PIN verified and job started for booking $bookingId');
      return true;
    } catch (e) {
      print('❌ [PostgresBooking] Failed to verify PIN: $e');
      return false;
    }
  }

  /// Mark job as completed (by professional)
  Future<void> markJobCompleted({
    required String bookingId,
    String? notes,
  }) async {
    try {
      final connection = await _getConnection();
      final now = DateTime.now();
      
      await connection.execute(
        Sql.named('''
          UPDATE bookings 
          SET status = 'completed',
              job_completed_at = @now,
              status_notes = @notes,
              updated_at = @now
          WHERE id = @bookingId
        '''),
        parameters: {
          'bookingId': bookingId,
          'now': now,
          'notes': notes,
        }
      );

      print('✅ [PostgresBooking] Job marked as completed for booking $bookingId');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to mark job as completed: $e');
      rethrow;
    }
  }

  /// Confirm job completion (by customer)
  Future<void> confirmJobCompletion({
    required String bookingId,
  }) async {
    try {
      final connection = await _getConnection();
      final now = DateTime.now();
      
      await connection.execute(
        Sql.named('''
          UPDATE bookings 
          SET status = 'reviewed',
              job_accepted_at = @now,
              updated_at = @now
          WHERE id = @bookingId
        '''),
        parameters: {
          'bookingId': bookingId,
          'now': now,
        }
      );

      print('✅ [PostgresBooking] Job completion confirmed by customer for booking $bookingId');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to confirm job completion: $e');
      rethrow;
    }
  }

  /// Confirm payment (offline payment confirmation by professional)
  Future<void> confirmPayment({
    required String bookingId,
    required String professionalId,
    required double amount,
    String? notes,
  }) async {
    try {
      final connection = await _getConnection();
      final now = DateTime.now();
      
      // Create payment confirmation record
      await connection.runTx((ctx) async {
        // Insert payment confirmation
        await ctx.execute(
          Sql.named('''
            INSERT INTO payment_confirmations (
              booking_id, professional_id, amount, confirmed_at, notes, created_at
            ) VALUES (
              @bookingId, @professionalId, @amount, @confirmedAt, @notes, @createdAt
            )
            ON CONFLICT (booking_id) DO UPDATE SET
              amount = EXCLUDED.amount,
              confirmed_at = EXCLUDED.confirmed_at,
              notes = EXCLUDED.notes,
              updated_at = EXCLUDED.updated_at
          '''),
          parameters: {
            'bookingId': bookingId,
            'professionalId': professionalId,
            'amount': amount,
            'confirmedAt': now,
            'notes': notes,
            'createdAt': now,
          }
        );
      });

      print('✅ [PostgresBooking] Payment confirmed for booking $bookingId');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to confirm payment: $e');
      rethrow;
    }
  }

  /// Get booking from PostgreSQL
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final connection = await _getConnection();
      
      final result = await connection.execute(
        Sql.named('''
          SELECT * FROM bookings WHERE id = @bookingId
        '''),
        parameters: {'bookingId': bookingId}
      );
      
      final rows = await result.toList();
      if (rows.isEmpty) {
        return null;
      }
      
      final row = rows.first;
      // Map row to booking data
      return {
        'id': row[0],
        'customer_id': row[1],
        'professional_id': row[2],
        'customer_name': row[3],
        'professional_name': row[4],
        'service_title': row[5],
        'service_description': row[6],
        'agreed_price': row[7],
        'currency': row[8],
        'scheduled_start_time': row[9],
        'scheduled_end_time': row[10],
        'service_location': row[11],
        'deliverables': row[12],
        'important_points': row[13],
        'status': row[14],
        'start_pin_hash': row[15],
        'chat_room_id': row[16],
        'estimate_id': row[17],
        'notes': row[18],
        'travel_mode': row[19],
        'customer_address': row[20],
        'shop_address': row[21],
        'travel_fee': row[22],
        'status_notes': row[23],
        'on_my_way_at': row[24],
        'job_started_at': row[25],
        'job_completed_at': row[26],
        'job_accepted_at': row[27],
        'created_at': row[28],
        'updated_at': row[29],
      };
    } catch (e) {
      print('❌ [PostgresBooking] Failed to get booking: $e');
      return null;
    }
  }

  /// Create review in PostgreSQL
  Future<void> createReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final connection = await _getConnection();
      final reviewId = const Uuid().v4();
      final now = DateTime.now();
      
      await connection.execute(
        Sql.named('''
          INSERT INTO reviews (
            id, booking_id, reviewer_id, reviewee_id, rating, title, comment,
            is_public, created_at, updated_at
          ) VALUES (
            @id, @bookingId, @reviewerId, @revieweeId, @rating, @title, @comment,
            @isPublic, @createdAt, @updatedAt
          )
        '''),
        parameters: {
          'id': reviewId,
          'bookingId': bookingId,
          'reviewerId': reviewerId,
          'revieweeId': revieweeId,
          'rating': rating,
          'title': title,
          'comment': comment,
          'isPublic': true,
          'createdAt': now,
          'updatedAt': now,
        }
      );

      print('✅ [PostgresBooking] Review created for booking $bookingId');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to create review: $e');
      rethrow;
    }
  }

  /// Initialize database tables
  Future<void> initialize() async {
    try {
      final connection = await _getConnection();
      
      // Create bookings table if it doesn't exist
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS bookings (
          id VARCHAR(255) PRIMARY KEY,
          customer_id VARCHAR(255) NOT NULL,
          professional_id VARCHAR(255) NOT NULL,
          customer_name VARCHAR(255) NOT NULL,
          professional_name VARCHAR(255) NOT NULL,
          service_title VARCHAR(255) NOT NULL,
          service_description TEXT NOT NULL,
          agreed_price DECIMAL(10,2) NOT NULL,
          currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
          scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
          scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
          service_location TEXT NOT NULL,
          deliverables TEXT[],
          important_points TEXT[],
          status VARCHAR(50) NOT NULL DEFAULT 'pending',
          start_pin_hash VARCHAR(255),
          chat_room_id VARCHAR(255),
          estimate_id VARCHAR(255),
          notes TEXT,
          travel_mode VARCHAR(20),
          customer_address TEXT,
          shop_address TEXT,
          travel_fee DECIMAL(10,2) DEFAULT 0,
          status_notes TEXT,
          on_my_way_at TIMESTAMP WITH TIME ZONE,
          job_started_at TIMESTAMP WITH TIME ZONE,
          job_completed_at TIMESTAMP WITH TIME ZONE,
          job_accepted_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          metadata JSONB
        )
      ''');
      
      // Create payment_confirmations table
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS payment_confirmations (
          booking_id VARCHAR(255) PRIMARY KEY,
          professional_id VARCHAR(255) NOT NULL,
          amount DECIMAL(10,2) NOT NULL,
          confirmed_at TIMESTAMP WITH TIME ZONE NOT NULL,
          notes TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create reviews table if it doesn't exist
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS reviews (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          booking_id VARCHAR(255) NOT NULL,
          reviewer_id VARCHAR(255) NOT NULL,
          reviewee_id VARCHAR(255) NOT NULL,
          rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
          title VARCHAR(255),
          comment TEXT,
          is_public BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          metadata JSONB
        )
      ''');
      
      // Create indexes
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_bookings_professional_id ON bookings(professional_id)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_reviews_booking_id ON reviews(booking_id)');
      await connection.execute('CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_id ON reviews(reviewee_id)');
      
      print('✅ [PostgresBooking] Database tables initialized');
    } catch (e) {
      print('❌ [PostgresBooking] Failed to initialize tables: $e');
      rethrow;
    }
  }

  /// Generate a 4-digit PIN
  String _generatePin() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  /// Hash a PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Map TravelMode enum to database values
  /// Database expects: 'customer_location' or 'shop_location'
  /// Enum values: 'customerTravels', 'proTravels', 'remote'
  String? _mapTravelModeToDb(TravelMode? travelMode) {
    if (travelMode == null) return null;
    
    switch (travelMode) {
      case TravelMode.customerTravels:
        return 'customer_location'; // Customer travels to shop
      case TravelMode.proTravels:
        return 'shop_location'; // Professional travels to customer location
      case TravelMode.remote:
        return null; // Remote services don't have travel mode
    }
  }
  
  /// Map database values to TravelMode enum
  /// Database values: 'customer_location', 'shop_location'
  /// Returns: TravelMode enum or null
  TravelMode? _mapDbToTravelMode(String? dbValue) {
    if (dbValue == null) return null;
    
    switch (dbValue) {
      case 'customer_location':
        return TravelMode.customerTravels;
      case 'shop_location':
        return TravelMode.proTravels;
      default:
        return null;
    }
  }
}

