import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a review given by a customer to a service professional
class CustomerReview {
  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final String professionalId;
  final String professionalName;
  final int rating; // 1-5 stars
  final String? reviewText; // Optional text review
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  CustomerReview({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    this.customerPhotoUrl,
    required this.professionalId,
    required this.professionalName,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory CustomerReview.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerReview(
      id: documentId,
      bookingId: map['bookingId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhotoUrl: map['customerPhotoUrl'],
      professionalId: map['professionalId'] ?? '',
      professionalName: map['professionalName'] ?? '',
      rating: map['rating'] ?? 0,
      reviewText: map['reviewText'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhotoUrl': customerPhotoUrl,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  CustomerReview copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? customerName,
    String? customerPhotoUrl,
    String? professionalId,
    String? professionalName,
    int? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CustomerReview(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents a review given by a service professional to a customer
class ProfessionalReview {
  final String id;
  final String bookingId;
  final String professionalId;
  final String professionalName;
  final String? professionalPhotoUrl;
  final String customerId;
  final String customerName;
  final int rating; // 1-5 stars
  final String? reviewText; // Optional text review
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ProfessionalReview({
    required this.id,
    required this.bookingId,
    required this.professionalId,
    required this.professionalName,
    this.professionalPhotoUrl,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ProfessionalReview.fromMap(Map<String, dynamic> map, String documentId) {
    return ProfessionalReview(
      id: documentId,
      bookingId: map['bookingId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      professionalName: map['professionalName'] ?? '',
      professionalPhotoUrl: map['professionalPhotoUrl'],
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      rating: map['rating'] ?? 0,
      reviewText: map['reviewText'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'professionalPhotoUrl': professionalPhotoUrl,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  ProfessionalReview copyWith({
    String? id,
    String? bookingId,
    String? professionalId,
    String? professionalName,
    String? professionalPhotoUrl,
    String? customerId,
    String? customerName,
    int? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProfessionalReview(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      professionalPhotoUrl: professionalPhotoUrl ?? this.professionalPhotoUrl,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents aggregated rating statistics for a user
class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count
  final DateTime lastUpdated;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.lastUpdated,
  });

  factory RatingStats.fromMap(Map<String, dynamic> map) {
    return RatingStats(
      averageRating: (map['averageRating'] as num).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Enum for review types
enum ReviewType {
  customerToProfessional,
  professionalToCustomer,
}

/// Enum for review status
enum ReviewStatus {
  pending,
  published,
  hidden,
  deleted,
}
