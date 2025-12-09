import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseChatService {
  static FirebaseChatService? _instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseChatService._();

  static FirebaseChatService get instance {
    _instance ??= FirebaseChatService._();
    return _instance!;
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String> createChatRoom({
    required String bookingId,
    required String customerId,
    required String professionalId,
    required String customerName,
    required String professionalName,
  }) async {
    try {
      final roomId = _firestore.collection('chatRooms').doc().id;
      
      await _firestore.collection('chatRooms').doc(roomId).set({
        'bookingId': bookingId,
        'customerId': customerId,
        'professionalId': professionalId,
        'customerName': customerName,
        'professionalName': professionalName,
        'lastMessage': null,
        'lastMessageAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [FirebaseChat] Chat room created: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Create room error: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final messageRef = _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'senderId': userId,
        'text': text,
        'imageUrl': imageUrl,
        'type': imageUrl != null ? 'image' : 'text',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chatRooms').doc(roomId).update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [FirebaseChat] Message sent to room: $roomId');
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Send message error: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRoomsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chatRooms')
        .where('customerId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getProfessionalChatRoomsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chatRooms')
        .where('professionalId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Future<void> markMessageAsRead(String roomId, String messageId) async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Mark read error: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String roomId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final messages = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Mark all read error: $e');
    }
  }

  Future<DocumentSnapshot?> getChatRoom(String roomId) async {
    try {
      return await _firestore.collection('chatRooms').doc(roomId).get();
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Get room error: $e');
      return null;
    }
  }

  Future<void> deleteChatRoom(String roomId) async {
    try {
      final messages = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('chatRooms').doc(roomId));
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [FirebaseChat] Delete room error: $e');
      rethrow;
    }
  }
}

