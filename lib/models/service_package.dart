import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a pre-priced service package that professionals can create
/// and customers can book directly
class ServicePackage {
  final String id;
  final String professionalId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int durationMinutes; // Duration in minutes
  final bool isStartingFrom; // If true, price is "starting from"
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ServicePackage({
    required this.id,
    required this.professionalId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'JMD',
    required this.durationMinutes,
    this.isStartingFrom = false,
    this.isActive = true,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'professionalId': professionalId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'durationMinutes': durationMinutes,
      'isStartingFrom': isStartingFrom,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata ?? {},
    };
  }

  /// Create from Firestore document
  factory ServicePackage.fromMap(Map<String, dynamic> map, String documentId) {
    return ServicePackage(
      id: documentId,
      professionalId: map['professionalId'] ?? map['professional_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'JMD',
      durationMinutes: map['durationMinutes'] ?? map['duration_minutes'] ?? 0,
      isStartingFrom: map['isStartingFrom'] ?? map['is_starting_from'] ?? false,
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      sortOrder: map['sortOrder'] ?? map['sort_order'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? 
                 map['created_at']?.toDate() ?? 
                 DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? 
                 map['updated_at']?.toDate() ?? 
                 DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create from API response (PostgreSQL format)
  factory ServicePackage.fromApiResponse(Map<String, dynamic> map) {
    return ServicePackage(
      id: map['id'] ?? '',
      professionalId: map['professional_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'JMD',
      durationMinutes: map['duration_minutes'] ?? 0,
      isStartingFrom: map['is_starting_from'] ?? false,
      isActive: map['is_active'] ?? true,
      sortOrder: map['sort_order'] ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to API request format (PostgreSQL format)
  Map<String, dynamic> toApiRequest() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_minutes': durationMinutes,
      'is_starting_from': isStartingFrom,
      'is_active': isActive,
      'sort_order': sortOrder,
      'metadata': metadata ?? {},
    };
  }

  ServicePackage copyWith({
    String? id,
    String? professionalId,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? durationMinutes,
    bool? isStartingFrom,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isStartingFrom: isStartingFrom ?? this.isStartingFrom,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper methods
  String get formattedPrice {
    final priceStr = price.toStringAsFixed(2);
    if (isStartingFrom) {
      return 'from $currency $priceStr';
    }
    return '$currency $priceStr';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  String get displayPrice {
    if (isStartingFrom) {
      return 'from ${currency} ${price.toStringAsFixed(2)}';
    }
    return '${currency} ${price.toStringAsFixed(2)}';
  }
}


