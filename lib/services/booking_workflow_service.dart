import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart';
import '../models/service.dart';
import 'postgres_booking_service.dart';
import 'firebase_firestore_service.dart';

/// Service for managing the InDrive-style booking workflow
/// Coordinates between Firestore (real-time UI) and PostgreSQL (financial records)
class BookingWorkflowService {
  static final BookingWorkflowService _instance = BookingWorkflowService._internal();
  factory BookingWorkflowService() => _instance;
  BookingWorkflowService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostgresBookingService _postgresBookingService = PostgresBookingService.instance;
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Set "On My Way" status
  /// Can be set by either customer or professional depending on who is traveling
  /// Generates a 4-digit PIN and returns it to be shown to the customer
  Future<String> setOnMyWay({
    required String bookingId,
    required String userId,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Setting "On My Way" status for booking: $bookingId');
      
      // Generate a 4-digit PIN
      final pin = _generatePin();
      final hashedPin = _hashPin(pin);
      
      // Get booking to determine who is traveling
      final bookingData = await _firestoreService.getBookingById(bookingId);
      if (bookingData == null) {
        throw Exception('Booking not found in Firestore');
      }
      
      final booking = Booking.fromMap(bookingData, bookingId);
      final travelMode = booking.finalTravelMode;
      
      // Determine who should be traveling
      bool isCustomerTraveling = false;
      if (travelMode == TravelMode.customerTravels) {
        isCustomerTraveling = userId == booking.customerId;
      } else if (travelMode == TravelMode.proTravels) {
        isCustomerTraveling = userId == booking.professionalId;
      }
      
      // Try to update in PostgreSQL, but create booking if it doesn't exist
      try {
        await _postgresBookingService.setOnMyWay(
          bookingId: bookingId,
          userId: userId,
        );
      } catch (e) {
        // If booking doesn't exist in PostgreSQL, create it first
        if (e.toString().contains('Booking not found') || e.toString().contains('not found')) {
          print('⚠️ [BookingWorkflow] Booking not found in PostgreSQL, creating it now...');
          
          // Create booking in PostgreSQL
          await _postgresBookingService.createBooking(
            bookingId: bookingId,
            customerId: booking.customerId,
            professionalId: booking.professionalId,
            customerName: booking.customerName,
            professionalName: booking.professionalName,
            serviceTitle: booking.serviceTitle,
            serviceDescription: booking.serviceDescription,
            agreedPrice: booking.agreedPrice,
            currency: 'JMD',
            scheduledStartTime: booking.scheduledStartTime,
            scheduledEndTime: booking.scheduledEndTime,
            serviceLocation: booking.location,
            deliverables: booking.deliverables,
            importantPoints: booking.importantPoints,
            chatRoomId: booking.chatRoomId,
            estimateId: booking.estimateId,
            notes: booking.notes,
            travelMode: booking.finalTravelMode,
            customerAddress: booking.customerAddress,
            shopAddress: booking.shopAddress,
            travelFee: booking.travelFee,
          );
          
          // Now try to set "On My Way" again
          await _postgresBookingService.setOnMyWay(
            bookingId: bookingId,
            userId: userId,
          );
          
          print('✅ [BookingWorkflow] Booking created in PostgreSQL and "On My Way" status set');
        } else {
          // Re-throw if it's a different error
          rethrow;
        }
      }
      
      // Update in Firestore for real-time UI with PIN
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'on_my_way',
        'onMyWayAt': FieldValue.serverTimestamp(),
        'customerPin': pin, // Store plain PIN for customer to see
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] "On My Way" status set successfully');
      print('🔐 [BookingWorkflow] PIN generated: $pin');
      
      // Return the PIN so it can be displayed to the customer
      return pin;
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to set "On My Way" status: $e');
      rethrow;
    }
  }
  
  /// Generate a 4-digit PIN
  String _generatePin() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }
  
  /// Hash a PIN using SHA-256 (for PostgreSQL storage)
  String _hashPin(String pin) {
    // This is a placeholder - actual hashing should use crypto package
    // For now, we'll store plain PIN in Firestore and hashed in PostgreSQL
    return pin; // PostgreSQL service will handle hashing
  }

  /// Verify PIN and start job
  Future<bool> verifyPinAndStartJob({
    required String bookingId,
    required String pin,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Verifying PIN for booking: $bookingId');
      
      // Verify PIN in PostgreSQL
      final isValid = await _postgresBookingService.verifyPinAndStartJob(
        bookingId: bookingId,
        pin: pin,
      );
      
      if (!isValid) {
        print('❌ [BookingWorkflow] PIN verification failed');
        return false;
      }
      
      // Update status in Firestore for real-time UI
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'in_progress',
        'jobStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] PIN verified and job started successfully');
      return true;
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to verify PIN and start job: $e');
      return false;
    }
  }

  /// Mark job as completed (by professional)
  Future<void> markJobCompleted({
    required String bookingId,
    String? notes,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Marking job as completed for booking: $bookingId');
      
      // Update in PostgreSQL
      await _postgresBookingService.markJobCompleted(
        bookingId: bookingId,
        notes: notes,
      );
      
      // Update in Firestore for real-time UI
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'jobCompletedAt': FieldValue.serverTimestamp(),
        'statusNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] Job marked as completed successfully');
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to mark job as completed: $e');
      rethrow;
    }
  }

  /// Confirm job completion (by customer)
  Future<void> confirmJobCompletion({
    required String bookingId,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Confirming job completion for booking: $bookingId');
      
      // Update in PostgreSQL
      await _postgresBookingService.confirmJobCompletion(
        bookingId: bookingId,
      );
      
      // Update in Firestore for real-time UI
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'reviewed',
        'jobAcceptedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] Job completion confirmed successfully');
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to confirm job completion: $e');
      rethrow;
    }
  }

  /// Confirm payment (offline payment confirmation by professional)
  /// Shows popup to professional when they mark job as complete
  Future<void> confirmPayment({
    required String bookingId,
    required String professionalId,
    required double amount,
    String? notes,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Confirming payment for booking: $bookingId');
      
      // Update in PostgreSQL
      await _postgresBookingService.confirmPayment(
        bookingId: bookingId,
        professionalId: professionalId,
        amount: amount,
        notes: notes,
      );
      
      // Update in Firestore for real-time UI
      await _firestore.collection('bookings').doc(bookingId).update({
        'paymentConfirmed': true,
        'paymentConfirmedAt': FieldValue.serverTimestamp(),
        'paymentConfirmedBy': professionalId,
        'paymentAmount': amount,
        'paymentNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] Payment confirmed successfully');
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to confirm payment: $e');
      rethrow;
    }
  }

  /// Submit review (customer reviews professional)
  Future<void> submitCustomerReview({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Submitting customer review for booking: $bookingId');
      
      // Create review in PostgreSQL
      await _postgresBookingService.createReview(
        bookingId: bookingId,
        reviewerId: customerId,
        revieweeId: professionalId,
        rating: rating,
        title: null,
        comment: reviewText,
      );
      
      // Create review in Firestore for real-time UI
      final reviewId = _firestore.collection('reviews').doc().id;
      await _firestore.collection('reviews').doc(reviewId).set({
        'id': reviewId,
        'bookingId': bookingId,
        'customerId': customerId,
        'professionalId': professionalId,
        'rating': rating,
        'reviewText': reviewText,
        'type': 'customer_review',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] Customer review submitted successfully');
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to submit customer review: $e');
      rethrow;
    }
  }

  /// Submit professional review (professional rates customer)
  Future<void> submitProfessionalReview({
    required String bookingId,
    required String professionalId,
    required String customerId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      print('🔍 [BookingWorkflow] Submitting professional review for booking: $bookingId');
      
      // Create review in PostgreSQL
      await _postgresBookingService.createReview(
        bookingId: bookingId,
        reviewerId: professionalId,
        revieweeId: customerId,
        rating: rating,
        title: null,
        comment: reviewText,
      );
      
      // Create review in Firestore for real-time UI
      final reviewId = _firestore.collection('professional_reviews').doc().id;
      await _firestore.collection('professional_reviews').doc(reviewId).set({
        'id': reviewId,
        'bookingId': bookingId,
        'professionalId': professionalId,
        'customerId': customerId,
        'rating': rating,
        'reviewText': reviewText,
        'type': 'professional_review',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [BookingWorkflow] Professional review submitted successfully');
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to submit professional review: $e');
      rethrow;
    }
  }

  /// Get booking status
  Future<BookingStatus?> getBookingStatus(String bookingId) async {
    try {
      final bookingData = await _firestoreService.getBookingById(bookingId);
      if (bookingData == null) return null;
      
      // Convert Map to Booking object
      final booking = Booking.fromMap(bookingData, bookingId);
      return booking.status;
    } catch (e) {
      print('❌ [BookingWorkflow] Failed to get booking status: $e');
      return null;
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _postgresBookingService.initialize();
      print('✅ [BookingWorkflow] Service initialized');
    } catch (e) {
      print('⚠️ [BookingWorkflow] Failed to initialize PostgreSQL: $e');
      // Don't fail - Firestore will still work for real-time UI
    }
  }
}

