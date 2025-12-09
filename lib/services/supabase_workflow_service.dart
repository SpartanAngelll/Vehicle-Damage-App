import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'firebase_supabase_service.dart';
import 'firebase_chat_service.dart';

class SupabaseWorkflowService {
  static SupabaseWorkflowService? _instance;
  final FirebaseSupabaseService _supabase = FirebaseSupabaseService.instance;
  final FirebaseChatService _chat = FirebaseChatService.instance;
  final Uuid _uuid = const Uuid();

  SupabaseWorkflowService._();

  static SupabaseWorkflowService get instance {
    _instance ??= SupabaseWorkflowService._();
    return _instance!;
  }

  Future<String?> createJobRequest({
    required String customerId,
    required String serviceCategoryId,
    required String title,
    required String description,
    required String location,
    double? budgetMin,
    double? budgetMax,
    String? priority,
    List<String>? mediaUrls,
    List<String>? importantPoints,
  }) async {
    try {
      final requestId = _uuid.v4();
      
      final response = await _supabase.insert(
        table: 'job_requests',
        data: {
          'id': requestId,
          'customer_id': customerId,
          'service_category_id': serviceCategoryId,
          'title': title,
          'description': description,
          'location': location,
          'budget_min': budgetMin,
          'budget_max': budgetMax,
          'priority': priority ?? 'normal',
          'status': 'pending',
          'media_urls': mediaUrls ?? [],
          'important_points': importantPoints ?? [],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (response != null) {
        debugPrint('✅ [Workflow] Job request created: $requestId');
        return requestId;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workflow] Create job request error: $e');
      return null;
    }
  }

  Future<String?> acceptRequest({
    required String estimateId,
    required String customerId,
  }) async {
    try {
      final estimateResponse = await _supabase.query(
        table: 'estimates',
        filters: {'id': estimateId},
      );

      if (estimateResponse == null || estimateResponse.isEmpty) {
        throw Exception('Estimate not found');
      }

      final estimate = estimateResponse[0];
      final jobRequestId = estimate['job_request_id'];
      final professionalId = estimate['professional_id'];

      final jobRequestResponse = await _supabase.query(
        table: 'job_requests',
        filters: {'id': jobRequestId},
      );

      if (jobRequestResponse == null || jobRequestResponse.isEmpty) {
        throw Exception('Job request not found');
      }

      final jobRequest = jobRequestResponse[0];

      final customerResponse = await _supabase.query(
        table: 'users',
        filters: {'firebase_uid': customerId},
      );

      final professionalResponse = await _supabase.query(
        table: 'users',
        filters: {'firebase_uid': professionalId},
      );

      final customerName = customerResponse?.isNotEmpty == true
          ? customerResponse![0]['full_name'] ?? 'Customer'
          : 'Customer';
      final professionalName = professionalResponse?.isNotEmpty == true
          ? professionalResponse![0]['full_name'] ?? 'Professional'
          : 'Professional';

      final bookingId = _uuid.v4();

      final bookingResponse = await _supabase.insert(
        table: 'bookings',
        data: {
          'id': bookingId,
          'estimate_id': estimateId,
          'customer_id': customerId,
          'professional_id': professionalId,
          'customer_name': customerName,
          'professional_name': professionalName,
          'service_title': estimate['title'],
          'service_description': estimate['description'],
          'agreed_price': estimate['price'],
          'currency': estimate['currency'] ?? 'JMD',
          'scheduled_start_time': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'scheduled_end_time': DateTime.now().add(const Duration(days: 1, hours: 2)).toIso8601String(),
          'service_location': jobRequest['location'],
          'deliverables': estimate['deliverables'] ?? [],
          'important_points': estimate['important_points'] ?? [],
          'status': 'confirmed',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (bookingResponse == null) {
        throw Exception('Failed to create booking');
      }

      await _supabase.update(
        table: 'estimates',
        data: {'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()},
        filters: {'id': estimateId},
      );

      await _supabase.update(
        table: 'job_requests',
        data: {'status': 'in_progress', 'updated_at': DateTime.now().toIso8601String()},
        filters: {'id': jobRequestId},
      );

      final chatRoomId = await _chat.createChatRoom(
        bookingId: bookingId,
        customerId: customerId,
        professionalId: professionalId,
        customerName: customerName,
        professionalName: professionalName,
      );

      await _supabase.update(
        table: 'bookings',
        data: {'chat_room_id': chatRoomId, 'updated_at': DateTime.now().toIso8601String()},
        filters: {'id': bookingId},
      );

      debugPrint('✅ [Workflow] Request accepted, booking created: $bookingId');
      return bookingId;
    } catch (e) {
      debugPrint('❌ [Workflow] Accept request error: $e');
      return null;
    }
  }

  Future<bool> completeJob({
    required String bookingId,
    required String professionalId,
    String? notes,
  }) async {
    try {
      final bookingResponse = await _supabase.query(
        table: 'bookings',
        filters: {'id': bookingId},
      );

      if (bookingResponse == null || bookingResponse.isEmpty) {
        throw Exception('Booking not found');
      }

      final booking = bookingResponse[0];
      if (booking['professional_id'] != professionalId) {
        throw Exception('Unauthorized');
      }

      await _supabase.update(
        table: 'bookings',
        data: {
          'status': 'completed',
          'job_completed_at': DateTime.now().toIso8601String(),
          'status_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': bookingId},
      );

      debugPrint('✅ [Workflow] Job completed: $bookingId');
      return true;
    } catch (e) {
      debugPrint('❌ [Workflow] Complete job error: $e');
      return false;
    }
  }

  Future<bool> recordPayment({
    required String bookingId,
    required String type,
    required double amount,
    required String currency,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final bookingResponse = await _supabase.query(
        table: 'bookings',
        filters: {'id': bookingId},
      );

      if (bookingResponse == null || bookingResponse.isEmpty) {
        throw Exception('Booking not found');
      }

      final booking = bookingResponse[0];
      final professionalId = booking['professional_id'];

      final paymentId = _uuid.v4();

      await _supabase.insert(
        table: 'payment_records',
        data: {
          'id': paymentId,
          'booking_id': bookingId,
          'type': type,
          'amount': amount,
          'currency': currency,
          'status': 'completed',
          'payment_method': paymentMethod,
          'transaction_id': transactionId,
          'processed_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      final balanceResponse = await _supabase.query(
        table: 'professional_balances',
        filters: {'professional_id': professionalId},
      );

      if (balanceResponse != null && balanceResponse.isNotEmpty) {
        final balance = balanceResponse[0];
        final newAvailable = (balance['available_balance'] as num) + amount;
        final newTotal = (balance['total_earned'] as num) + amount;

        await _supabase.update(
          table: 'professional_balances',
          data: {
            'available_balance': newAvailable,
            'total_earned': newTotal,
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'professional_id': professionalId},
        );
      } else {
        await _supabase.insert(
          table: 'professional_balances',
          data: {
            'professional_id': professionalId,
            'available_balance': amount,
            'total_earned': amount,
            'total_paid_out': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }

      debugPrint('✅ [Workflow] Payment recorded: $paymentId');
      return true;
    } catch (e) {
      debugPrint('❌ [Workflow] Record payment error: $e');
      return false;
    }
  }

  Future<bool> leaveReview({
    required String bookingId,
    required String reviewerId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final bookingResponse = await _supabase.query(
        table: 'bookings',
        filters: {'id': bookingId},
      );

      if (bookingResponse == null || bookingResponse.isEmpty) {
        throw Exception('Booking not found');
      }

      final booking = bookingResponse[0];
      final customerId = booking['customer_id'];
      final professionalId = booking['professional_id'];

      final revieweeId = reviewerId == customerId ? professionalId : customerId;

      final reviewId = _uuid.v4();

      await _supabase.insert(
        table: 'reviews',
        data: {
          'id': reviewId,
          'booking_id': bookingId,
          'reviewer_id': reviewerId,
          'reviewee_id': revieweeId,
          'rating': rating,
          'title': title,
          'comment': comment,
          'is_public': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      final reviewsResponse = await _supabase.query(
        table: 'reviews',
        filters: {'reviewee_id': revieweeId},
      );

      if (reviewsResponse != null && reviewsResponse.isNotEmpty) {
        double totalRating = 0;
        for (var review in reviewsResponse) {
          totalRating += (review['rating'] as num).toDouble();
        }
        final averageRating = totalRating / reviewsResponse.length;

        await _supabase.update(
          table: 'service_professionals',
          data: {
            'average_rating': averageRating,
            'total_reviews': reviewsResponse.length,
            'updated_at': DateTime.now().toIso8601String(),
          },
          filters: {'user_id': revieweeId},
        );
      }

      await _supabase.update(
        table: 'bookings',
        data: {
          'status': 'reviewed',
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': bookingId},
      );

      debugPrint('✅ [Workflow] Review created: $reviewId');
      return true;
    } catch (e) {
      debugPrint('❌ [Workflow] Leave review error: $e');
      return false;
    }
  }
}

