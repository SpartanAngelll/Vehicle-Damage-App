import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import '../models/payment_models.dart';
import '../models/booking_availability_models.dart';
import 'postgres_payment_service.dart';
import 'postgres_booking_service.dart';
import 'supabase_booking_service.dart';
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
  final SupabaseBookingService _supabaseBookingService = SupabaseBookingService.instance;
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

      // Send notification to the recipient (but not to the sender)
      try {
        final chatRoom = await getChatRoom(chatRoomId);
        if (chatRoom != null) {
          // Determine recipient: if sender is customer, recipient is professional, and vice versa
          final recipientId = senderId == chatRoom.customerId 
              ? chatRoom.professionalId 
              : chatRoom.customerId;
          
          // CRITICAL: Multiple checks to prevent self-notifications
          if (recipientId == null || recipientId.isEmpty) {
            print('⚠️ [ChatService] Skipping notification - recipient ID is null or empty (sender: $senderId)');
            return message;
          }
          
          if (recipientId == senderId) {
            print('⚠️ [ChatService] Skipping notification - recipient is same as sender (sender: $senderId, recipient: $recipientId)');
            return message;
          }
          
          // Additional validation: ensure recipientId is different from senderId (case-insensitive)
          if (recipientId.toLowerCase().trim() == senderId.toLowerCase().trim()) {
            print('⚠️ [ChatService] Skipping notification - recipient matches sender (case-insensitive check) (sender: $senderId, recipient: $recipientId)');
            return message;
          }
          
          print('📤 [ChatService] Sending notification to recipient: $recipientId (sender: $senderId, customerId: ${chatRoom.customerId}, professionalId: ${chatRoom.professionalId})');
          await _notificationService.sendNewChatMessageNotification(
            recipientId: recipientId,
            senderName: senderName,
            messagePreview: content.length > 100 ? '${content.substring(0, 100)}...' : content,
            chatRoomId: chatRoomId,
            senderId: senderId, // Pass senderId to prevent self-notifications
          );
        } else {
          print('⚠️ [ChatService] Chat room not found, skipping notification (chatRoomId: $chatRoomId)');
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
    String? customerName,
    String? professionalName,
  }) async {
    try {
      print('🔍 [ChatService] Creating booking from summary: ${summary.id}');
      print('🔍 [ChatService] Summary data:');
      print('  - extractedPrice: ${summary.extractedPrice}');
      print('  - extractedStartTime: ${summary.extractedStartTime}');
      print('  - extractedEndTime: ${summary.extractedEndTime}');
      print('  - extractedLocation: ${summary.extractedLocation}');
      
      // Use values from summary (these come from the booking confirmation dialog)
      final startTime = summary.extractedStartTime ?? DateTime.now().add(const Duration(days: 1));
      final endTime = summary.extractedEndTime ?? startTime.add(const Duration(hours: 2));
      final agreedPrice = summary.extractedPrice;
      final serviceLocation = summary.extractedLocation ?? location;
      
      // Validate required fields
      if (agreedPrice <= 0) {
        throw Exception('Agreed price must be greater than 0');
      }
      
      // Use the availability service to book the time slot with conflict checking
      // This ensures consistency and prevents double bookings
      final booking = await _availabilityService.bookTimeSlot(
        professionalId: summary.professionalId,
        customerId: summary.customerId,
        customerName: customerName ?? 'Customer',
        professionalName: professionalName ?? 'Professional',
        startTime: startTime,
        endTime: endTime,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        agreedPrice: agreedPrice,
        location: serviceLocation,
        deliverables: summary.extractedDeliverables,
        importantPoints: summary.extractedImportantPoints,
        notes: null,
      );
      
      // Update booking with additional fields from summary
      await _bookingsCollection.doc(booking.id).update({
        'estimateId': summary.estimateId,
        'chatRoomId': summary.chatRoomId,
        'finalTravelMode': summary.finalTravelMode?.name, // Convert enum to string
        'customerAddress': summary.customerAddress,
        'shopAddress': summary.shopAddress,
        'travelFee': summary.travelFee,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Create booking in Supabase (for financial records)
      // IMPORTANT: Verify customerId matches current Firebase UID to prevent RLS violations
      try {
        // Get current Firebase Auth UID to ensure it matches
        final firebaseAuth = FirebaseAuth.instance;
        final currentFirebaseUid = firebaseAuth.currentUser?.uid;
        
        if (currentFirebaseUid == null) {
          throw Exception('User not authenticated - cannot create booking');
        }
        
        // Use current Firebase UID instead of potentially stale summary.customerId
        final verifiedCustomerId = currentFirebaseUid;
        
        if (summary.customerId != verifiedCustomerId) {
          print('⚠️ [ChatService] Customer ID mismatch detected:');
          print('   Summary customerId: ${summary.customerId}');
          print('   Current Firebase UID: $verifiedCustomerId');
          print('   Using current Firebase UID to prevent RLS violation');
        }
        
        final pin = await _supabaseBookingService.createBooking(
          bookingId: booking.id,
          customerId: verifiedCustomerId,
          professionalId: summary.professionalId,
          customerName: booking.customerName,
          professionalName: booking.professionalName,
          serviceTitle: serviceTitle,
          serviceDescription: serviceDescription,
          agreedPrice: agreedPrice, // Use the validated price from summary
          currency: 'JMD',
          scheduledStartTime: startTime, // Use the validated time from summary
          scheduledEndTime: endTime, // Use the validated time from summary
          serviceLocation: serviceLocation, // Use the validated location from summary
          deliverables: summary.extractedDeliverables,
          importantPoints: summary.extractedImportantPoints,
          chatRoomId: summary.chatRoomId,
          estimateId: summary.estimateId,
          notes: null,
          travelMode: summary.finalTravelMode,
          customerAddress: summary.customerAddress,
          shopAddress: summary.shopAddress,
          travelFee: summary.travelFee,
        );
          
        // Store PIN in Firestore for customer access (unhashed, only shown once)
        await _bookingsCollection.doc(booking.id).update({
          'customerPin': pin,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        print('✅ [ChatService] Booking created in Supabase with PIN: ${pin.substring(0, 2)}**');
      } catch (e) {
        print('⚠️ [ChatService] Failed to create booking in Supabase: $e');
        // Don't fail the booking creation if Supabase fails
        // Firestore booking is still created for real-time UI
      }
      
      print('✅ [ChatService] Booking created: ${booking.id}');
      
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

      // Create booking in Supabase (for financial records)
      try {
        final pin = await _supabaseBookingService.createBooking(
          bookingId: booking.id,
          customerId: customerId,
          professionalId: professionalId,
          customerName: customerName,
          professionalName: professionalName,
          serviceTitle: serviceTitle,
          serviceDescription: serviceDescription,
          agreedPrice: agreedPrice,
          currency: 'JMD',
          scheduledStartTime: startTime,
          scheduledEndTime: endTime,
          serviceLocation: location,
          deliverables: deliverables,
          importantPoints: importantPoints,
          chatRoomId: chatRoomId,
          estimateId: estimateId,
          notes: notes,
        );
        
        // Store PIN in Firestore for customer access (unhashed, only shown once)
        await _bookingsCollection.doc(booking.id).update({
          'customerPin': pin,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        print('✅ [ChatService] Booking created in Supabase with PIN: ${pin.substring(0, 2)}**');
      } catch (e) {
        print('⚠️ [ChatService] Failed to create booking in Supabase: $e');
        // Don't fail the booking creation if Supabase fails
        // Firestore booking is still created for real-time UI
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
