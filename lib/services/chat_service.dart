import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import '../models/payment_models.dart';
import '../models/booking_availability_models.dart';
import 'postgres_payment_service.dart';
import 'mock_payment_service.dart';
import 'payment_workflow_service.dart';
import 'comprehensive_notification_service.dart';
import 'booking_reminder_scheduler.dart';
import 'booking_availability_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final PostgresPaymentService _paymentService = PostgresPaymentService.instance;
  final MockPaymentService _mockPaymentService = MockPaymentService.instance;
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  final BookingReminderScheduler _reminderScheduler = BookingReminderScheduler();
  final BookingAvailabilityService _availabilityService = BookingAvailabilityService();

  // Collections
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');
  CollectionReference get _messagesCollection => _firestore.collection('chat_messages');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _jobSummariesCollection => _firestore.collection('job_summaries');

  // Create a new chat room for an accepted estimate
  Future<ChatRoom> createChatRoom({
    required String estimateId,
    required String customerId,
    required String professionalId,
    required String customerName,
    required String professionalName,
    String? customerPhotoUrl,
    String? professionalPhotoUrl,
  }) async {
    try {
      print('🔍 [ChatService] Creating chat room for estimate: $estimateId');
      
      final chatRoomId = _uuid.v4();
      final now = DateTime.now();
      
      final chatRoom = ChatRoom(
        id: chatRoomId,
        estimateId: estimateId,
        customerId: customerId,
        professionalId: professionalId,
        customerName: customerName,
        professionalName: professionalName,
        customerPhotoUrl: customerPhotoUrl,
        professionalPhotoUrl: professionalPhotoUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _chatRoomsCollection.doc(chatRoomId).set(chatRoom.toMap());
      
      // Send initial system message
      await _sendSystemMessage(
        chatRoomId: chatRoomId,
        content: "Chat started! Please discuss the job details, schedule, and any specific requirements. Once you're ready, I'll help generate a booking summary.",
      );

      print('✅ [ChatService] Chat room created successfully: $chatRoomId');
      return chatRoom;
    } catch (e) {
      print('❌ [ChatService] Error creating chat room: $e');
      rethrow;
    }
  }

  // Send a message
  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String content,
    String? senderPhotoUrl,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔍 [ChatService] Sending message to chat room: $chatRoomId');
      
      final messageId = _uuid.v4();
      final now = DateTime.now();
      
      final message = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: type,
        timestamp: now,
        metadata: metadata,
      );

      // Add message to messages collection
      await _messagesCollection.doc(messageId).set(message.toMap());
      
      // Update chat room with last message info
      await _chatRoomsCollection.doc(chatRoomId).update({
        'lastMessage': content,
        'lastMessageAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Send notification to the recipient
      try {
        final chatRoom = await getChatRoom(chatRoomId);
        if (chatRoom != null) {
          final recipientId = senderId == chatRoom.customerId 
              ? chatRoom.professionalId 
              : chatRoom.customerId;
          
          await _notificationService.sendNewChatMessageNotification(
            recipientId: recipientId,
            senderName: senderName,
            messagePreview: content.length > 100 ? '${content.substring(0, 100)}...' : content,
            chatRoomId: chatRoomId,
          );
        }
      } catch (e) {
        print('⚠️ [ChatService] Failed to send chat message notification: $e');
        // Don't fail the message sending if notification fails
      }

      print('✅ [ChatService] Message sent successfully: $messageId');
      return message;
    } catch (e) {
      print('❌ [ChatService] Error sending message: $e');
      rethrow;
    }
  }

  // Send system message
  Future<ChatMessage> _sendSystemMessage({
    required String chatRoomId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    return sendMessage(
      chatRoomId: chatRoomId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      metadata: metadata,
    );
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _chatRoomsCollection.doc(chatRoomId).get();
      if (doc.exists) {
        return ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ [ChatService] Error getting chat room: $e');
      return null;
    }
  }

  // Get chat room by estimate ID
  Future<ChatRoom?> getChatRoomByEstimateId(String estimateId) async {
    try {
      final query = await _chatRoomsCollection
          .where('estimateId', isEqualTo: estimateId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ [ChatService] Error getting chat room by estimate ID: $e');
      return null;
    }
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _messagesCollection
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
      // Sort messages in memory to avoid index requirement
      final messages = snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      // Sort by timestamp in ascending order (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    });
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChatRoomsStream(String userId) {
    return _chatRoomsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      // Filter chat rooms where user is a participant
      final chatRooms = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['customerId'] == userId || data['professionalId'] == userId;
          })
          .map((doc) {
            return ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          })
          .toList();
      
      // Sort by updatedAt in descending order (newest first)
      chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return chatRooms;
    });
  }

  // Get existing chat room between customer and professional
  Future<ChatRoom?> getExistingChatRoom(String customerId, String professionalId) async {
    try {
      print('🔍 [ChatService] Looking for existing chat between customer: $customerId and professional: $professionalId');
      
      final query = await _chatRoomsCollection
          .where('customerId', isEqualTo: customerId)
          .where('professionalId', isEqualTo: professionalId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final chatRoom = ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        print('✅ [ChatService] Found existing chat room: ${chatRoom.id}');
        return chatRoom;
      }
      
      print('ℹ️ [ChatService] No existing chat room found');
      return null;
    } catch (e) {
      print('❌ [ChatService] Error getting existing chat room: $e');
      return null;
    }
  }

  // Create a new chat room for direct communication (without estimate)
  Future<ChatRoom> createDirectChatRoom({
    required String customerId,
    required String professionalId,
    required String customerName,
    required String professionalName,
    String? customerPhotoUrl,
    String? professionalPhotoUrl,
  }) async {
    try {
      print('🔍 [ChatService] Creating direct chat room between customer: $customerId and professional: $professionalId');
      
      final chatRoomId = _uuid.v4();
      final now = DateTime.now();
      
      final chatRoom = ChatRoom(
        id: chatRoomId,
        estimateId: '', // Empty for direct chats
        customerId: customerId,
        professionalId: professionalId,
        customerName: customerName,
        professionalName: professionalName,
        customerPhotoUrl: customerPhotoUrl,
        professionalPhotoUrl: professionalPhotoUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _chatRoomsCollection.doc(chatRoomId).set(chatRoom.toMap());
      
      // Send initial system message
      await _sendSystemMessage(
        chatRoomId: chatRoomId,
        content: "Direct chat started! You can now discuss services, pricing, and any questions you may have.",
      );

      print('✅ [ChatService] Direct chat room created successfully: $chatRoomId');
      return chatRoom;
    } catch (e) {
      print('❌ [ChatService] Error creating direct chat room: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // Get all messages for the chat room and filter in memory to avoid index requirement
      final query = await _messagesCollection
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      // Filter messages in memory
      final unreadMessages = query.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['senderId'] != userId && data['isRead'] != true;
      }).toList();

      if (unreadMessages.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadMessages) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('❌ [ChatService] Error marking messages as read: $e');
    }
  }

  // Create booking from job summary
  Future<Booking> createBookingFromSummary({
    required JobSummary summary,
    required String serviceTitle,
    required String serviceDescription,
    required String location,
  }) async {
    try {
      print('🔍 [ChatService] Creating booking from summary: ${summary.id}');
      
      final startTime = summary.extractedStartTime ?? DateTime.now().add(const Duration(days: 1));
      final endTime = summary.extractedEndTime ?? startTime.add(const Duration(hours: 2));
      
      // Use the availability service to book the time slot with conflict checking
      // This ensures consistency and prevents double bookings
      final booking = await _availabilityService.bookTimeSlot(
        professionalId: summary.professionalId,
        customerId: summary.customerId,
        customerName: '', // Will be filled from estimate if needed
        professionalName: '', // Will be filled from estimate if needed
        startTime: startTime,
        endTime: endTime,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        agreedPrice: summary.extractedPrice,
        location: summary.extractedLocation ?? location,
        deliverables: summary.extractedDeliverables,
        importantPoints: summary.extractedImportantPoints,
        notes: null,
      );
      
      // Update booking with additional fields from summary
      await _bookingsCollection.doc(booking.id).update({
        'estimateId': summary.estimateId,
        'chatRoomId': summary.chatRoomId,
        'finalTravelMode': summary.finalTravelMode,
        'customerAddress': summary.customerAddress,
        'shopAddress': summary.shopAddress,
        'travelFee': summary.travelFee,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Payment workflow disabled for initial web launch
      // Payment processing will be re-enabled when payment gateway is integrated
      // TODO: Re-enable payment workflow when payment gateway is configured
      /*
      // Create invoice and payment record
      try {
        // Try PostgreSQL first
        try {
          await _paymentService.initialize();
          
          // Create invoice first
          final paymentWorkflowService = PaymentWorkflowService.instance;
          await paymentWorkflowService.initialize();
          
          final invoice = await paymentWorkflowService.createInvoiceFromBooking(
            bookingId: bookingId,
            customerId: summary.customerId,
            professionalId: summary.professionalId,
            totalAmount: summary.extractedPrice,
            depositPercentage: 0, // No deposit required by default
            currency: 'JMD',
            notes: 'Invoice created for booking: $serviceTitle',
          );
          
          // Create payment record
          await _paymentService.createPayment(
            bookingId: bookingId,
            customerId: summary.customerId,
            professionalId: summary.professionalId,
            amount: summary.extractedPrice,
            currency: 'JMD',
            notes: 'Payment for booking: $serviceTitle',
          );
          
          print('✅ [ChatService] PostgreSQL invoice and payment record created for booking: $bookingId');
        } catch (e) {
          print('⚠️ [ChatService] PostgreSQL not available, using mock payments: $e');
          await _mockPaymentService.initialize();
          await _mockPaymentService.createPayment(
            bookingId: bookingId,
            customerId: summary.customerId,
            professionalId: summary.professionalId,
            amount: summary.extractedPrice,
            currency: 'JMD',
            notes: 'Payment for booking: $serviceTitle',
          );
          print('✅ [ChatService] Mock payment record created for booking: $bookingId');
        }
      } catch (e) {
        print('⚠️ [ChatService] Failed to create payment record: $e');
        // Don't fail the booking creation if payment record creation fails
      }
      */
      
      print('✅ [ChatService] Booking created (payment workflow disabled): ${booking.id}');
      
      // Send booking generated message
      await _sendSystemMessage(
        chatRoomId: summary.chatRoomId,
        content: "Booking generated! Please review and confirm the details.",
        metadata: {'bookingId': booking.id, 'type': 'booking_generated'},
      );

      // Schedule booking reminders
      try {
        await _reminderScheduler.scheduleBookingReminders(booking);
        print('✅ [ChatService] Booking reminders scheduled for booking: ${booking.id}');
      } catch (e) {
        print('⚠️ [ChatService] Failed to schedule booking reminders: $e');
        // Don't fail the booking creation if reminder scheduling fails
      }

      print('✅ [ChatService] Booking created successfully: ${booking.id}');
      return booking;
    } catch (e) {
      print('❌ [ChatService] Error creating booking: $e');
      rethrow;
    }
  }

  // Get user's bookings
  Stream<List<Booking>> getUserBookingsStream(String userId) {
    return _bookingsCollection
        .snapshots()
        .map((snapshot) {
      // Filter and sort in memory to avoid complex index requirements
      final bookings = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['customerId'] == userId || data['professionalId'] == userId;
          })
          .map((doc) {
            return Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          })
          .toList();
      
      // Sort by scheduledStartTime in ascending order (earliest first)
      bookings.sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
      
      return bookings;
    });
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ [ChatService] Error updating booking status: $e');
      rethrow;
    }
  }

  // Archive chat room
  Future<void> archiveChatRoom(String chatRoomId) async {
    try {
      await _chatRoomsCollection.doc(chatRoomId).update({
        'isActive': false,
        'status': ChatStatus.archived.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ [ChatService] Error archiving chat room: $e');
      rethrow;
    }
  }

  // Create booking with availability checking
  Future<Booking> createBookingWithAvailability({
    required String professionalId,
    required String customerId,
    required String customerName,
    required String professionalName,
    required DateTime startTime,
    required DateTime endTime,
    required String serviceTitle,
    required String serviceDescription,
    required double agreedPrice,
    required String location,
    List<String>? deliverables,
    List<String>? importantPoints,
    String? notes,
    String? estimateId,
    String? chatRoomId,
  }) async {
    try {
      print('🔍 [ChatService] Creating booking with availability check for professional: $professionalId');

      // Use the availability service to book the time slot
      final booking = await _availabilityService.bookTimeSlot(
        professionalId: professionalId,
        customerId: customerId,
        customerName: customerName,
        professionalName: professionalName,
        startTime: startTime,
        endTime: endTime,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        agreedPrice: agreedPrice,
        location: location,
        deliverables: deliverables,
        importantPoints: importantPoints,
        notes: notes,
      );

      // Update the booking with additional fields if provided
      if (estimateId != null || chatRoomId != null) {
        final updateData = <String, dynamic>{
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };
        
        if (estimateId != null) updateData['estimateId'] = estimateId;
        if (chatRoomId != null) updateData['chatRoomId'] = chatRoomId;
        
        await _bookingsCollection.doc(booking.id).update(updateData);
      }

      // Schedule booking reminders
      try {
        await _reminderScheduler.scheduleBookingReminders(booking);
        print('✅ [ChatService] Booking reminders scheduled for booking: ${booking.id}');
      } catch (e) {
        print('⚠️ [ChatService] Failed to schedule booking reminders: $e');
        // Don't fail the booking creation if reminder scheduling fails
      }

      print('✅ [ChatService] Booking created successfully with availability check: ${booking.id}');
      return booking;
    } catch (e) {
      print('❌ [ChatService] Error creating booking with availability check: $e');
      rethrow;
    }
  }

  // Get available time slots for a professional
  Future<List<TimeSlot>> getAvailableSlots({
    required String professionalId,
    required DateTime date,
  }) async {
    try {
      return await _availabilityService.getAvailableSlotsForDate(
        professionalId: professionalId,
        date: date,
      );
    } catch (e) {
      print('❌ [ChatService] Error getting available slots: $e');
      return [];
    }
  }

  // Get calendar data for a professional
  Future<List<CalendarDay>> getProfessionalCalendar({
    required String professionalId,
    required DateTime month,
  }) async {
    try {
      return await _availabilityService.getCalendarDataForMonth(
        professionalId: professionalId,
        month: month,
      );
    } catch (e) {
      print('❌ [ChatService] Error getting professional calendar: $e');
      return [];
    }
  }

  // Setup professional availability
  Future<void> setupProfessionalAvailability({
    required String professionalId,
    required List<Map<String, dynamic>> weeklySchedule,
  }) async {
    try {
      await _availabilityService.setupProfessionalAvailability(
        professionalId: professionalId,
        weeklySchedule: weeklySchedule,
      );
    } catch (e) {
      print('❌ [ChatService] Error setting up professional availability: $e');
      rethrow;
    }
  }
}
