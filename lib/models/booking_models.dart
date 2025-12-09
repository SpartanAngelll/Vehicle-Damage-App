import 'package:cloud_firestore/cloud_firestore.dart';
import 'service.dart';

class Booking {
  final String id;
  final String estimateId;
  final String chatRoomId;
  final String customerId;
  final String professionalId;
  final String customerName;
  final String professionalName;
  final String serviceTitle;
  final String serviceDescription;
  final double agreedPrice;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String location;
  final List<String> deliverables;
  final List<String> importantPoints;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final Map<String, dynamic>? metadata;
  
  // Status tracking fields
  final DateTime? confirmedAt;
  final DateTime? onMyWayAt;
  final DateTime? jobStartedAt;
  final DateTime? jobCompletedAt;
  final DateTime? jobAcceptedAt;
  final DateTime? reviewedAt;
  final String? customerPin;
  final String? statusNotes;
  
  // Travel mode fields
  final TravelMode? finalTravelMode;
  final String? customerAddress;
  final String? shopAddress;
  final double? travelFee;

  Booking({
    required this.id,
    required this.estimateId,
    required this.chatRoomId,
    required this.customerId,
    required this.professionalId,
    required this.customerName,
    required this.professionalName,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.agreedPrice,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.location,
    required this.deliverables,
    required this.importantPoints,
    this.status = BookingStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.metadata,
    this.confirmedAt,
    this.onMyWayAt,
    this.jobStartedAt,
    this.jobCompletedAt,
    this.jobAcceptedAt,
    this.reviewedAt,
    this.customerPin,
    this.statusNotes,
    this.finalTravelMode,
    this.customerAddress,
    this.shopAddress,
    this.travelFee,
  });

  /// Helper function to parse timestamps from either Firestore Timestamp or ISO string
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    
    // If it's already a Timestamp object (from Firestore)
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // If it's a string (ISO format from Supabase or other sources)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ [Booking] Error parsing timestamp string: $value, error: $e');
        return null;
      }
    }
    
    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }
    
    print('⚠️ [Booking] Unknown timestamp type: ${value.runtimeType}, value: $value');
    return null;
  }

  factory Booking.fromMap(Map<String, dynamic> map, String documentId) {
    return Booking(
      id: documentId,
      estimateId: map['estimateId'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      customerId: map['customerId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      customerName: map['customerName'] ?? '',
      professionalName: map['professionalName'] ?? '',
      serviceTitle: map['serviceTitle'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble() ?? 0.0,
      scheduledStartTime: _parseTimestamp(map['scheduledStartTime']) ?? DateTime.now(),
      scheduledEndTime: _parseTimestamp(map['scheduledEndTime']) ?? DateTime.now().add(const Duration(hours: 1)),
      location: map['location'] ?? '',
      deliverables: List<String>.from(map['deliverables'] ?? []),
      importantPoints: List<String>.from(map['importantPoints'] ?? []),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
      notes: map['notes'],
      metadata: map['metadata'],
      confirmedAt: _parseTimestamp(map['confirmedAt']),
      onMyWayAt: _parseTimestamp(map['onMyWayAt']),
      jobStartedAt: _parseTimestamp(map['jobStartedAt']),
      jobCompletedAt: _parseTimestamp(map['jobCompletedAt']),
      jobAcceptedAt: _parseTimestamp(map['jobAcceptedAt']),
      reviewedAt: _parseTimestamp(map['reviewedAt']),
      customerPin: map['customerPin'],
      statusNotes: map['statusNotes'],
      finalTravelMode: map['finalTravelMode'] != null 
          ? TravelMode.values.firstWhere(
              (e) => e.name == map['finalTravelMode'],
              orElse: () => TravelMode.customerTravels,
            )
          : null,
      customerAddress: map['customerAddress'],
      shopAddress: map['shopAddress'],
      travelFee: map['travelFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estimateId': estimateId,
      'chatRoomId': chatRoomId,
      'customerId': customerId,
      'professionalId': professionalId,
      'customerName': customerName,
      'professionalName': professionalName,
      'serviceTitle': serviceTitle,
      'serviceDescription': serviceDescription,
      'agreedPrice': agreedPrice,
      'scheduledStartTime': Timestamp.fromDate(scheduledStartTime),
      'scheduledEndTime': Timestamp.fromDate(scheduledEndTime),
      'location': location,
      'deliverables': deliverables,
      'importantPoints': importantPoints,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'metadata': metadata,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'onMyWayAt': onMyWayAt != null ? Timestamp.fromDate(onMyWayAt!) : null,
      'jobStartedAt': jobStartedAt != null ? Timestamp.fromDate(jobStartedAt!) : null,
      'jobCompletedAt': jobCompletedAt != null ? Timestamp.fromDate(jobCompletedAt!) : null,
      'jobAcceptedAt': jobAcceptedAt != null ? Timestamp.fromDate(jobAcceptedAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'customerPin': customerPin,
      'statusNotes': statusNotes,
      'finalTravelMode': finalTravelMode?.name,
      'customerAddress': customerAddress,
      'shopAddress': shopAddress,
      'travelFee': travelFee,
    };
  }

  Booking copyWith({
    String? id,
    String? estimateId,
    String? chatRoomId,
    String? customerId,
    String? professionalId,
    String? customerName,
    String? professionalName,
    String? serviceTitle,
    String? serviceDescription,
    double? agreedPrice,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? location,
    List<String>? deliverables,
    List<String>? importantPoints,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? confirmedAt,
    DateTime? onMyWayAt,
    DateTime? jobStartedAt,
    DateTime? jobCompletedAt,
    DateTime? jobAcceptedAt,
    DateTime? reviewedAt,
    String? customerPin,
    String? statusNotes,
    TravelMode? finalTravelMode,
    String? customerAddress,
    String? shopAddress,
    double? travelFee,
  }) {
    return Booking(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      customerId: customerId ?? this.customerId,
      professionalId: professionalId ?? this.professionalId,
      customerName: customerName ?? this.customerName,
      professionalName: professionalName ?? this.professionalName,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      location: location ?? this.location,
      deliverables: deliverables ?? this.deliverables,
      importantPoints: importantPoints ?? this.importantPoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      onMyWayAt: onMyWayAt ?? this.onMyWayAt,
      jobStartedAt: jobStartedAt ?? this.jobStartedAt,
      jobCompletedAt: jobCompletedAt ?? this.jobCompletedAt,
      jobAcceptedAt: jobAcceptedAt ?? this.jobAcceptedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      customerPin: customerPin ?? this.customerPin,
      statusNotes: statusNotes ?? this.statusNotes,
      finalTravelMode: finalTravelMode ?? this.finalTravelMode,
      customerAddress: customerAddress ?? this.customerAddress,
      shopAddress: shopAddress ?? this.shopAddress,
      travelFee: travelFee ?? this.travelFee,
    );
  }
}

class JobSummary {
  final String id;
  final String chatRoomId;
  final String estimateId;
  final String customerId;
  final String professionalId;
  final String originalEstimate;
  final String conversationSummary;
  final double extractedPrice;
  final DateTime? extractedStartTime;
  final DateTime? extractedEndTime;
  final String? extractedLocation;
  final List<String> extractedDeliverables;
  final List<String> extractedImportantPoints;
  final double confidenceScore;
  final DateTime createdAt;
  final Map<String, dynamic>? rawAnalysis;
  
  // Travel mode fields
  final TravelMode? finalTravelMode;
  final String? customerAddress;
  final String? shopAddress;
  final double? travelFee;

  JobSummary({
    required this.id,
    required this.chatRoomId,
    required this.estimateId,
    required this.customerId,
    required this.professionalId,
    required this.originalEstimate,
    required this.conversationSummary,
    required this.extractedPrice,
    this.extractedStartTime,
    this.extractedEndTime,
    this.extractedLocation,
    required this.extractedDeliverables,
    required this.extractedImportantPoints,
    required this.confidenceScore,
    required this.createdAt,
    this.rawAnalysis,
    this.finalTravelMode,
    this.customerAddress,
    this.shopAddress,
    this.travelFee,
  });

  factory JobSummary.fromMap(Map<String, dynamic> map, String documentId) {
    return JobSummary(
      id: documentId,
      chatRoomId: map['chatRoomId'] ?? '',
      estimateId: map['estimateId'] ?? '',
      customerId: map['customerId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      originalEstimate: map['originalEstimate'] ?? '',
      conversationSummary: map['conversationSummary'] ?? '',
      extractedPrice: (map['extractedPrice'] as num?)?.toDouble() ?? 0.0,
      extractedStartTime: map['extractedStartTime'] != null 
          ? (map['extractedStartTime'] as Timestamp).toDate() 
          : null,
      extractedEndTime: map['extractedEndTime'] != null 
          ? (map['extractedEndTime'] as Timestamp).toDate() 
          : null,
      extractedLocation: map['extractedLocation'],
      extractedDeliverables: List<String>.from(map['extractedDeliverables'] ?? []),
      extractedImportantPoints: List<String>.from(map['extractedImportantPoints'] ?? []),
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.8,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      rawAnalysis: map['rawAnalysis'],
      finalTravelMode: map['finalTravelMode'] != null 
          ? TravelMode.values.firstWhere(
              (e) => e.name == map['finalTravelMode'],
              orElse: () => TravelMode.customerTravels,
            )
          : null,
      customerAddress: map['customerAddress'],
      shopAddress: map['shopAddress'],
      travelFee: map['travelFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'estimateId': estimateId,
      'customerId': customerId,
      'professionalId': professionalId,
      'originalEstimate': originalEstimate,
      'conversationSummary': conversationSummary,
      'extractedPrice': extractedPrice,
      'extractedStartTime': extractedStartTime != null 
          ? Timestamp.fromDate(extractedStartTime!) 
          : null,
      'extractedEndTime': extractedEndTime != null 
          ? Timestamp.fromDate(extractedEndTime!) 
          : null,
      'extractedLocation': extractedLocation,
      'extractedDeliverables': extractedDeliverables,
      'extractedImportantPoints': extractedImportantPoints,
      'confidenceScore': confidenceScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'rawAnalysis': rawAnalysis,
      'finalTravelMode': finalTravelMode?.name,
      'customerAddress': customerAddress,
      'shopAddress': shopAddress,
      'travelFee': travelFee,
    };
  }
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  reviewed,
  cancelled,
}
