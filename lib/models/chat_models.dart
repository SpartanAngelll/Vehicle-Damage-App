import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String estimateId;
  final String customerId;
  final String professionalId;
  final String customerName;
  final String professionalName;
  final String? customerPhotoUrl;
  final String? professionalPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final ChatStatus status;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatRoom({
    required this.id,
    required this.estimateId,
    required this.customerId,
    required this.professionalId,
    required this.customerName,
    required this.professionalName,
    this.customerPhotoUrl,
    this.professionalPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.status = ChatStatus.active,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatRoom(
      id: documentId,
      estimateId: map['estimateId'] ?? '',
      customerId: map['customerId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      customerName: map['customerName'] ?? '',
      professionalName: map['professionalName'] ?? '',
      customerPhotoUrl: map['customerPhotoUrl'],
      professionalPhotoUrl: map['professionalPhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      status: ChatStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChatStatus.active,
      ),
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null 
          ? (map['lastMessageAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estimateId': estimateId,
      'customerId': customerId,
      'professionalId': professionalId,
      'customerName': customerName,
      'professionalName': professionalName,
      'customerPhotoUrl': customerPhotoUrl,
      'professionalPhotoUrl': professionalPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'status': status.name,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? estimateId,
    String? customerId,
    String? professionalId,
    String? customerName,
    String? professionalName,
    String? customerPhotoUrl,
    String? professionalPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    ChatStatus? status,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      customerId: customerId ?? this.customerId,
      professionalId: professionalId ?? this.professionalId,
      customerName: customerName ?? this.customerName,
      professionalName: professionalName ?? this.professionalName,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      professionalPhotoUrl: professionalPhotoUrl ?? this.professionalPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatMessage(
      id: documentId,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum ChatStatus {
  active,
  completed,
  archived,
}

enum MessageType {
  text,
  system,
  bookingGenerated,
  bookingConfirmed,
}
