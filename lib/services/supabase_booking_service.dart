import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';
import 'firebase_supabase_service.dart';
import '../models/service.dart';

/// Service for managing bookings in Supabase using REST API
/// Replaces PostgresBookingService to use Supabase REST API instead of direct PostgreSQL connection
class SupabaseBookingService {
  static SupabaseBookingService? _instance;
  final FirebaseSupabaseService _supabase = FirebaseSupabaseService.instance;

  SupabaseBookingService._();

  static SupabaseBookingService get instance {
    _instance ??= SupabaseBookingService._();
    return _instance!;
  }

  /// Generate a 4-digit PIN for customer verification
  String _generatePin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Map TravelMode enum to database string
  /// Database expects: 'customer_location' or 'shop_location'
  /// Enum values: 'customerTravels', 'proTravels', 'remote'
  String? _mapTravelModeToDb(TravelMode? mode) {
    if (mode == null) return null;
    switch (mode) {
      case TravelMode.customerTravels:
        return 'customer_location'; // Customer travels to shop
      case TravelMode.proTravels:
        return 'shop_location'; // Professional travels to customer location
      case TravelMode.remote:
        return null; // Remote services don't have travel mode
    }
  }

  /// Create a booking in Supabase
  /// Returns the generated PIN for customer verification
  Future<String> createBooking({
    required String bookingId,
    required String customerId, // Firebase UID
    required String professionalId, // Firebase UID
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
      // Generate a 4-digit PIN for the customer
      final pin = _generatePin();
      final hashedPin = _hashPin(pin);

      debugPrint('🔍 [SupabaseBooking] Creating booking in Supabase: $bookingId');

      // Helper function to check if a string is a valid UUID
      bool _isValidUUID(String? str) {
        if (str == null || str.isEmpty) return false;
        // UUID format: 8-4-4-4-12 hexadecimal characters
        final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        return uuidRegex.hasMatch(str);
      }

      // Build booking data
      final bookingData = <String, dynamic>{
        'id': bookingId,
        'customer_id': customerId, // Firebase UID (VARCHAR)
        'professional_id': professionalId, // Firebase UID (VARCHAR)
        'customer_name': customerName,
        'professional_name': professionalName,
        'service_title': serviceTitle,
        'service_description': serviceDescription,
        'agreed_price': agreedPrice,
        'currency': currency,
        'scheduled_start_time': scheduledStartTime.toIso8601String(),
        'scheduled_end_time': scheduledEndTime.toIso8601String(),
        'service_location': serviceLocation,
        'deliverables': deliverables ?? [],
        'important_points': importantPoints ?? [],
        'status': 'confirmed',
        'start_pin_hash': hashedPin,
        'notes': notes,
        'travel_mode': _mapTravelModeToDb(travelMode),
        'customer_address': customerAddress,
        'shop_address': shopAddress,
        'travel_fee': travelFee ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only include estimate_id if it's a valid UUID (Supabase expects UUID, not Firebase doc ID)
      if (estimateId != null && _isValidUUID(estimateId)) {
        bookingData['estimate_id'] = estimateId;
        debugPrint('🔍 [SupabaseBooking] Including estimate_id (valid UUID): $estimateId');
      } else if (estimateId != null) {
        debugPrint('⚠️ [SupabaseBooking] estimate_id is not a valid UUID (Firebase doc ID): $estimateId - omitting from insert');
        // Don't include estimate_id if it's not a valid UUID
      }

      // Only include chat_room_id if it's a valid UUID
      if (chatRoomId != null && _isValidUUID(chatRoomId)) {
        bookingData['chat_room_id'] = chatRoomId;
        debugPrint('🔍 [SupabaseBooking] Including chat_room_id (valid UUID): $chatRoomId');
      } else if (chatRoomId != null) {
        debugPrint('⚠️ [SupabaseBooking] chat_room_id is not a valid UUID (Firebase doc ID): $chatRoomId - omitting from insert');
        // Don't include chat_room_id if it's not a valid UUID
      }

      // Upsert booking into Supabase (handles both new and existing bookings)
      // This prevents duplicate key errors if booking already exists
      final response = await _supabase.upsert(
        table: 'bookings',
        data: bookingData,
        conflictTarget: 'id', // Primary key column
      );

      if (response == null || response.isEmpty) {
        throw Exception('Failed to create/update booking in Supabase - no response');
      }

      debugPrint('✅ [SupabaseBooking] Booking created/updated in Supabase: $bookingId');
      debugPrint('🔐 [SupabaseBooking] PIN generated (hashed): ${pin.substring(0, 2)}**');

      // Return the PIN so it can be shown to the customer
      return pin;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to create booking: $e');
      rethrow;
    }
  }

  /// Update booking status
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    String? statusNotes,
    DateTime? onMyWayAt,
    DateTime? jobStartedAt,
    DateTime? jobCompletedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (statusNotes != null) {
        updateData['status_notes'] = statusNotes;
      }
      if (onMyWayAt != null) {
        updateData['on_my_way_at'] = onMyWayAt.toIso8601String();
      }
      if (jobStartedAt != null) {
        updateData['job_started_at'] = jobStartedAt.toIso8601String();
      }
      if (jobCompletedAt != null) {
        updateData['job_completed_at'] = jobCompletedAt.toIso8601String();
      }

      final response = await _supabase.update(
        table: 'bookings',
        data: updateData,
        filters: {'id': bookingId},
      );

      if (response == null) {
        debugPrint('⚠️ [SupabaseBooking] Update returned null for booking: $bookingId');
        return false;
      }

      debugPrint('✅ [SupabaseBooking] Booking status updated: $bookingId -> $status');
      return true;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to update booking status: $e');
      return false;
    }
  }

  /// Verify PIN for booking start
  Future<bool> verifyPin({
    required String bookingId,
    required String pin,
  }) async {
    try {
      // Get booking from Supabase
      final bookingResponse = await _supabase.query(
        table: 'bookings',
        filters: {'id': bookingId},
      );

      if (bookingResponse == null || bookingResponse.isEmpty) {
        debugPrint('⚠️ [SupabaseBooking] Booking not found: $bookingId');
        return false;
      }

      final booking = bookingResponse[0];
      final storedHash = booking['start_pin_hash'] as String?;

      if (storedHash == null) {
        debugPrint('⚠️ [SupabaseBooking] No PIN hash stored for booking: $bookingId');
        return false;
      }

      // Hash the provided PIN and compare
      final providedHash = _hashPin(pin);
      final isValid = providedHash == storedHash;

      if (isValid) {
        debugPrint('✅ [SupabaseBooking] PIN verified for booking: $bookingId');
      } else {
        debugPrint('❌ [SupabaseBooking] PIN verification failed for booking: $bookingId');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Error verifying PIN: $e');
      return false;
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final response = await _supabase.query(
        table: 'bookings',
        filters: {'id': bookingId},
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      return response[0];
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Error getting booking: $e');
      return null;
    }
  }

  /// Set "On My Way" status
  /// Validates that the user is the traveling party based on travel_mode
  Future<bool> setOnMyWay({
    required String bookingId,
    required String userId, // Can be customer or professional
  }) async {
    try {
      // Get booking to determine who should be traveling
      final booking = await getBooking(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      final customerId = booking['customer_id'] as String;
      final professionalId = booking['professional_id'] as String;
      final travelMode = booking['travel_mode'] as String?;

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
        // For remote services, default to customer
        travelingUserId = customerId;
      }

      // Verify the user setting status is the one who should be traveling
      if (userId != travelingUserId) {
        throw Exception('Only the traveling party can set "On My Way" status');
      }

      // Update booking status
      final now = DateTime.now();
      final success = await updateBookingStatus(
        bookingId: bookingId,
        status: 'on_my_way',
        onMyWayAt: now,
      );

      if (success) {
        debugPrint('✅ [SupabaseBooking] Set "On My Way" status for booking $bookingId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to set "On My Way" status: $e');
      rethrow;
    }
  }

  /// Verify PIN and start job
  Future<bool> verifyPinAndStartJob({
    required String bookingId,
    required String pin,
  }) async {
    try {
      // Get booking to verify PIN
      final booking = await getBooking(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      final storedHash = booking['start_pin_hash'] as String?;
      final currentStatus = booking['status'] as String?;

      if (storedHash == null) {
        throw Exception('PIN not set for this booking');
      }

      // Verify the PIN
      final providedHash = _hashPin(pin);
      if (providedHash != storedHash) {
        debugPrint('❌ [SupabaseBooking] PIN verification failed for booking $bookingId');
        return false;
      }

      // Update status to started/in_progress if not already
      if (currentStatus != 'in_progress' && currentStatus != 'started') {
        final now = DateTime.now();
        final success = await updateBookingStatus(
          bookingId: bookingId,
          status: 'in_progress',
          jobStartedAt: now,
        );

        if (success) {
          debugPrint('✅ [SupabaseBooking] PIN verified and job started for booking $bookingId');
        }

        return success;
      }

      debugPrint('✅ [SupabaseBooking] PIN verified for booking $bookingId (job already started)');
      return true;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to verify PIN: $e');
      return false;
    }
  }

  /// Mark job as completed (by professional)
  Future<bool> markJobCompleted({
    required String bookingId,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final success = await updateBookingStatus(
        bookingId: bookingId,
        status: 'completed',
        statusNotes: notes,
        jobCompletedAt: now,
      );

      if (success) {
        debugPrint('✅ [SupabaseBooking] Job marked as completed for booking $bookingId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to mark job as completed: $e');
      return false;
    }
  }

  /// Confirm job completion (by customer)
  Future<bool> confirmJobCompletion({
    required String bookingId,
  }) async {
    try {
      final now = DateTime.now();
      final success = await updateBookingStatus(
        bookingId: bookingId,
        status: 'reviewed',
        jobCompletedAt: now, // This should be job_accepted_at, but we'll use the same field
      );

      // Also update job_accepted_at if the update method supports it
      // For now, we'll do a separate update
      try {
        await _supabase.update(
          table: 'bookings',
          data: {
            'job_accepted_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
          filters: {'id': bookingId},
        );
      } catch (e) {
        debugPrint('⚠️ [SupabaseBooking] Could not update job_accepted_at: $e');
      }

      if (success) {
        debugPrint('✅ [SupabaseBooking] Job completion confirmed by customer for booking $bookingId');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to confirm job completion: $e');
      return false;
    }
  }

  /// Confirm payment (offline payment confirmation by professional)
  /// Creates a record in payment_confirmations table
  Future<bool> confirmPayment({
    required String bookingId,
    required String professionalId,
    required double amount,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      // Create payment confirmation record in payment_confirmations table
      final confirmationData = <String, dynamic>{
        'booking_id': bookingId,
        'professional_id': professionalId,
        'amount': amount,
        'confirmed_at': now.toIso8601String(),
        'notes': notes,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // Use upsert to handle if confirmation already exists
      final response = await _supabase.upsert(
        table: 'payment_confirmations',
        data: confirmationData,
        conflictTarget: 'booking_id',
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ [SupabaseBooking] Payment confirmed for booking $bookingId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to confirm payment: $e');
      return false;
    }
  }

  /// Create a review
  Future<bool> createReview({
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final reviewId = const Uuid().v4();
      final now = DateTime.now();

      final reviewData = <String, dynamic>{
        'id': reviewId,
        'booking_id': bookingId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'title': title,
        'comment': comment,
        'is_public': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase.insert(
        table: 'reviews',
        data: reviewData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ [SupabaseBooking] Review created: $reviewId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [SupabaseBooking] Failed to create review: $e');
      return false;
    }
  }
}



