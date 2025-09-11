import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/review_models.dart';
import '../models/booking_models.dart';
import '../models/service_professional.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Collections
  CollectionReference get _customerReviewsCollection => _firestore.collection('reviews');
  CollectionReference get _professionalReviewsCollection => _firestore.collection('professional_reviews');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _professionalsCollection => _firestore.collection('service_professionals');

  /// Submit a customer review for a service professional
  Future<CustomerReview> submitCustomerReview({
    required String bookingId,
    required String customerId,
    required String customerName,
    String? customerPhotoUrl,
    required String professionalId,
    required String professionalName,
    required int rating,
    String? reviewText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [ReviewService] Submitting customer review for booking: $bookingId');
      
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw ArgumentError('Rating must be between 1 and 5');
      }

      // Check if review already exists for this booking
      final existingReview = await _customerReviewsCollection
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: customerId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('Review already exists for this booking');
      }

      final reviewId = _uuid.v4();
      final now = DateTime.now();

      final review = CustomerReview(
        id: reviewId,
        bookingId: bookingId,
        customerId: customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        professionalId: professionalId,
        professionalName: professionalName,
        rating: rating,
        reviewText: reviewText,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      // Store the review
      await _customerReviewsCollection.doc(reviewId).set(review.toMap());

      // Update professional's rating statistics
      await _updateProfessionalRatingStats(professionalId);

      // Update booking status to reviewed if not already
      await _updateBookingToReviewed(bookingId);

      print('✅ [ReviewService] Customer review submitted successfully: $reviewId');
      return review;
    } catch (e) {
      print('❌ [ReviewService] Error submitting customer review: $e');
      rethrow;
    }
  }

  /// Submit a professional review for a customer
  Future<ProfessionalReview> submitProfessionalReview({
    required String bookingId,
    required String professionalId,
    required String professionalName,
    String? professionalPhotoUrl,
    required String customerId,
    required String customerName,
    required int rating,
    String? reviewText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [ReviewService] Submitting professional review for booking: $bookingId');
      
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw ArgumentError('Rating must be between 1 and 5');
      }

      // Check if review already exists for this booking
      final existingReview = await _professionalReviewsCollection
          .where('bookingId', isEqualTo: bookingId)
          .where('professionalId', isEqualTo: professionalId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('Review already exists for this booking');
      }

      final reviewId = _uuid.v4();
      final now = DateTime.now();

      final review = ProfessionalReview(
        id: reviewId,
        bookingId: bookingId,
        professionalId: professionalId,
        professionalName: professionalName,
        professionalPhotoUrl: professionalPhotoUrl,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        reviewText: reviewText,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      // Store the review
      await _professionalReviewsCollection.doc(reviewId).set(review.toMap());

      print('✅ [ReviewService] Professional review submitted successfully: $reviewId');
      return review;
    } catch (e) {
      print('❌ [ReviewService] Error submitting professional review: $e');
      rethrow;
    }
  }

  /// Get all reviews for a service professional
  Future<List<CustomerReview>> getProfessionalReviews(String professionalId) async {
    try {
      final snapshot = await _customerReviewsCollection
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerReview.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ [ReviewService] Error getting professional reviews: $e');
      return [];
    }
  }

  /// Get all reviews for a customer
  Future<List<ProfessionalReview>> getCustomerReviews(String customerId) async {
    try {
      final snapshot = await _professionalReviewsCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProfessionalReview.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ [ReviewService] Error getting customer reviews: $e');
      return [];
    }
  }

  /// Get rating statistics for a service professional
  Future<RatingStats> getProfessionalRatingStats(String professionalId) async {
    try {
      final reviews = await getProfessionalReviews(professionalId);
      
      if (reviews.isEmpty) {
        return RatingStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          lastUpdated: DateTime.now(),
        );
      }

      double totalRating = 0;
      final ratingDistribution = <int, int>{};

      for (final review in reviews) {
        totalRating += review.rating;
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
      }

      final averageRating = totalRating / reviews.length;

      return RatingStats(
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ [ReviewService] Error getting professional rating stats: $e');
      return RatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get rating statistics for a customer
  Future<RatingStats> getCustomerRatingStats(String customerId) async {
    try {
      final reviews = await getCustomerReviews(customerId);
      
      if (reviews.isEmpty) {
        return RatingStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          lastUpdated: DateTime.now(),
        );
      }

      double totalRating = 0;
      final ratingDistribution = <int, int>{};

      for (final review in reviews) {
        totalRating += review.rating;
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
      }

      final averageRating = totalRating / reviews.length;

      return RatingStats(
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('❌ [ReviewService] Error getting customer rating stats: $e');
      return RatingStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Check if a customer has already reviewed a booking
  Future<bool> hasCustomerReviewedBooking(String bookingId, String customerId) async {
    try {
      final snapshot = await _customerReviewsCollection
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: customerId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ [ReviewService] Error checking customer review: $e');
      return false;
    }
  }

  /// Check if a professional has already reviewed a booking
  Future<bool> hasProfessionalReviewedBooking(String bookingId, String professionalId) async {
    try {
      final snapshot = await _professionalReviewsCollection
          .where('bookingId', isEqualTo: bookingId)
          .where('professionalId', isEqualTo: professionalId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ [ReviewService] Error checking professional review: $e');
      return false;
    }
  }

  /// Update professional's rating statistics in their profile
  Future<void> _updateProfessionalRatingStats(String professionalId) async {
    try {
      final stats = await getProfessionalRatingStats(professionalId);
      
      await _professionalsCollection.doc(professionalId).update({
        'averageRating': stats.averageRating,
        'totalReviews': stats.totalReviews,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [ReviewService] Professional rating stats updated: $professionalId');
    } catch (e) {
      print('❌ [ReviewService] Error updating professional rating stats: $e');
    }
  }

  /// Update booking status to reviewed
  Future<void> _updateBookingToReviewed(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.reviewed.name,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [ReviewService] Booking status updated to reviewed: $bookingId');
    } catch (e) {
      print('❌ [ReviewService] Error updating booking status: $e');
    }
  }

  /// Get reviews stream for real-time updates
  Stream<List<CustomerReview>> getProfessionalReviewsStream(String professionalId) {
    return _customerReviewsCollection
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerReview.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get customer reviews stream for real-time updates
  Stream<List<ProfessionalReview>> getCustomerReviewsStream(String customerId) {
    return _professionalReviewsCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfessionalReview.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
