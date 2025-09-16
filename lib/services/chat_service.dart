import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../models/booking_models.dart';
import '../models/payment_models.dart';
import 'postgres_payment_service.dart';
import 'mock_payment_service.dart';
import 'payment_workflow_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final PostgresPaymentService _paymentService = PostgresPaymentService.instance;
  final MockPaymentService _mockPaymentService = MockPaymentService.instance;

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
      
      final bookingId = _uuid.v4();
      final now = DateTime.now();
      
      final booking = Booking(
        id: bookingId,
        estimateId: summary.estimateId,
        chatRoomId: summary.chatRoomId,
        customerId: summary.customerId,
        professionalId: summary.professionalId,
        customerName: '', // Will be filled from estimate
        professionalName: '', // Will be filled from estimate
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        agreedPrice: summary.extractedPrice,
        scheduledStartTime: summary.extractedStartTime ?? now.add(const Duration(days: 1)),
        scheduledEndTime: summary.extractedEndTime ?? now.add(const Duration(days: 1, hours: 2)),
        location: summary.extractedLocation ?? location,
        deliverables: summary.extractedDeliverables,
        importantPoints: summary.extractedImportantPoints,
        createdAt: now,
        updatedAt: now,
        finalTravelMode: summary.finalTravelMode,
        customerAddress: summary.customerAddress,
        shopAddress: summary.shopAddress,
        travelFee: summary.travelFee,
      );

      await _bookingsCollection.doc(bookingId).set(booking.toMap());
      
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
      
      // Send booking generated message
      await _sendSystemMessage(
        chatRoomId: summary.chatRoomId,
        content: "Booking generated! Please review and confirm the details.",
        metadata: {'bookingId': bookingId, 'type': 'booking_generated'},
      );

      print('✅ [ChatService] Booking created successfully: $bookingId');
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
}
