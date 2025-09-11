import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class DamageReport {
  final String id;
  final String ownerId;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String damageDescription;
  final List<String> imageUrls;
  final double estimatedCost;
  final String? additionalNotes;
  final String status;
  final DateTime timestamp;
  final List<Estimate> estimates;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final File? image; // Add image field
  final String description; // Add description field

  DamageReport({
    String? id,
    required this.ownerId,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.damageDescription,
    required this.imageUrls,
    required this.estimatedCost,
    this.additionalNotes,
    String? status,
    DateTime? timestamp,
    List<Estimate>? estimates,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.image, // Add image parameter
    String? description, // Add description parameter
  }) :
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    status = status ?? 'pending',
    timestamp = timestamp ?? DateTime.now(),
    estimates = estimates ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    description = description ?? damageDescription; // Initialize description

  bool get hasEstimates => estimates.isNotEmpty;
  int get estimateCount => estimates.length;
  bool get isRecent => DateTime.now().difference(timestamp).inDays < 7;
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  void addEstimate(Estimate estimate) {
    estimates.add(estimate);
  }

  void removeEstimate(int index) {
    if (index >= 0 && index < estimates.length) {
      estimates.removeAt(index);
    }
  }

  void updateEstimate(int index, Estimate newEstimate) {
    if (index >= 0 && index < estimates.length) {
      estimates[index] = newEstimate;
    }
  }

  void clearEstimates() {
    estimates.clear();
  }

  void updateStatus(String newStatus) {
    // Note: This creates a new instance since status is final
    // In a real app, you might want to make this mutable or use a different approach
  }

  DamageReport copyWith({
    String? id,
    String? ownerId,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? damageDescription,
    List<String>? imageUrls,
    double? estimatedCost,
    String? additionalNotes,
    String? status,
    DateTime? timestamp,
    List<Estimate>? estimates,
    DateTime? createdAt,
    DateTime? updatedAt,
    File? image, // Add image parameter
    String? description, // Add description parameter
  }) {
    return DamageReport(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      damageDescription: damageDescription ?? this.damageDescription,
      imageUrls: imageUrls ?? this.imageUrls,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      estimates: estimates ?? this.estimates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      image: image ?? this.image, // Add image
      description: description ?? this.description, // Add description
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DamageReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DamageReport(id: $id, description: $damageDescription, estimates: $estimates)';
  }
}

class Estimate {
  final String id;
  final String reportId; // Keep for backward compatibility
  final String? jobRequestId; // New field for job requests
  final String ownerId;
  final String repairProfessionalId;
  final String repairProfessionalEmail;
  final String? repairProfessionalBio;
  final double cost;
  final int leadTimeDays;
  final String description;
  final List<String> imageUrls;
  final EstimateStatus status;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? completedAt;
  final String? completionNotes;
  final List<String>? attachments; // Additional files/documents

  Estimate({
    String? id,
    String? reportId,
    this.jobRequestId,
    required this.ownerId,
    required this.repairProfessionalId,
    required this.repairProfessionalEmail,
    this.repairProfessionalBio,
    required this.cost,
    required this.leadTimeDays,
    required this.description,
    List<String>? imageUrls,
    EstimateStatus status = EstimateStatus.pending,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    this.completedAt,
    this.completionNotes,
    List<String>? attachments,
  }) :
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    reportId = reportId ?? '',
    imageUrls = imageUrls ?? [],
    status = status,
    submittedAt = submittedAt ?? DateTime.now(),
    updatedAt = updatedAt,
    acceptedAt = acceptedAt,
    declinedAt = declinedAt,
    attachments = attachments ?? [];

  // Backward compatibility: Create from old damage report estimate
  factory Estimate.fromDamageReport(Map<String, dynamic> estimateData) {
    return Estimate(
      id: estimateData['id'],
      reportId: estimateData['reportId'],
      ownerId: estimateData['ownerId'],
      repairProfessionalId: estimateData['repairProfessionalId'],
      repairProfessionalEmail: estimateData['repairProfessionalEmail'],
      repairProfessionalBio: estimateData['repairProfessionalBio'],
      cost: estimateData['cost']?.toDouble() ?? 0.0,
      leadTimeDays: estimateData['leadTimeDays'] ?? 0,
      description: estimateData['description'] ?? '',
      imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
      status: _parseEstimateStatus(estimateData['status']),
      submittedAt: _parseTimestamp(estimateData['submittedAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(estimateData['updatedAt']),
      acceptedAt: _parseTimestamp(estimateData['acceptedAt']),
      declinedAt: _parseTimestamp(estimateData['declinedAt']),
    );
  }

  // Create from job request estimate
  factory Estimate.fromJobRequest(Map<String, dynamic> estimateData) {
    return Estimate(
      id: estimateData['id'],
      jobRequestId: estimateData['jobRequestId'],
      ownerId: estimateData['customerId'],
      repairProfessionalId: estimateData['professionalId'],
      repairProfessionalEmail: estimateData['professionalEmail'],
      repairProfessionalBio: estimateData['professionalBio'],
      cost: estimateData['cost']?.toDouble() ?? 0.0,
      leadTimeDays: estimateData['leadTimeDays'] ?? 0,
      description: estimateData['description'] ?? '',
      imageUrls: List<String>.from(estimateData['imageUrls'] ?? []),
      status: _parseEstimateStatus(estimateData['status']),
      submittedAt: _parseTimestamp(estimateData['submittedAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(estimateData['updatedAt']),
      acceptedAt: _parseTimestamp(estimateData['acceptedAt']),
      declinedAt: _parseTimestamp(estimateData['declinedAt']),
      completedAt: estimateData['completedAt']?.toDate(),
      completionNotes: estimateData['completionNotes'],
      attachments: List<String>.from(estimateData['attachments'] ?? []),
    );
  }

  static EstimateStatus _parseEstimateStatus(String? status) {
    switch (status) {
      case 'pending':
        return EstimateStatus.pending;
      case 'accepted':
        return EstimateStatus.accepted;
      case 'declined':
        return EstimateStatus.declined;
      default:
        return EstimateStatus.pending;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'ownerId': ownerId,
      'repairProfessionalId': repairProfessionalId,
      'repairProfessionalEmail': repairProfessionalEmail,
      'repairProfessionalBio': repairProfessionalBio,
      'cost': cost,
      'leadTimeDays': leadTimeDays,
      'description': description,
      'imageUrls': imageUrls,
      'status': status.name,
      'submittedAt': submittedAt,
      'updatedAt': updatedAt,
      'acceptedAt': acceptedAt,
      'declinedAt': declinedAt,
      'completedAt': completedAt,
      'completionNotes': completionNotes,
      'attachments': attachments,
    };

    // Add appropriate ID field based on context
    if (jobRequestId != null && jobRequestId!.isNotEmpty) {
      map['jobRequestId'] = jobRequestId;
    } else if (reportId.isNotEmpty) {
      map['reportId'] = reportId;
    }

    return map;
  }

  // Create from Firestore document
  factory Estimate.fromMap(Map<String, dynamic> map, String documentId) {
    return Estimate(
      id: documentId,
      reportId: map['reportId'] ?? '',
      jobRequestId: map['jobRequestId'],
      ownerId: map['ownerId'] ?? map['customerId'] ?? '',
      repairProfessionalId: map['repairProfessionalId'] ?? map['professionalId'] ?? '',
      repairProfessionalEmail: map['repairProfessionalEmail'] ?? map['professionalEmail'] ?? '',
      repairProfessionalBio: map['repairProfessionalBio'] ?? map['professionalBio'],
      cost: map['cost']?.toDouble() ?? 0.0,
      leadTimeDays: map['leadTimeDays'] ?? 0,
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: _parseEstimateStatus(map['status']),
      submittedAt: _parseTimestamp(map['submittedAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']),
      acceptedAt: _parseTimestamp(map['acceptedAt']),
      declinedAt: _parseTimestamp(map['declinedAt']),
      completedAt: _parseTimestamp(map['completedAt']),
      completionNotes: map['completionNotes'],
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  Estimate copyWith({
    String? id,
    String? reportId,
    String? jobRequestId,
    String? ownerId,
    String? repairProfessionalId,
    String? repairProfessionalEmail,
    String? repairProfessionalBio,
    double? cost,
    int? leadTimeDays,
    String? description,
    List<String>? imageUrls,
    EstimateStatus? status,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? completedAt,
    String? completionNotes,
    List<String>? attachments,
  }) {
    return Estimate(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      jobRequestId: jobRequestId ?? this.jobRequestId,
      ownerId: ownerId ?? this.ownerId,
      repairProfessionalId: repairProfessionalId ?? this.repairProfessionalId,
      repairProfessionalEmail: repairProfessionalEmail ?? this.repairProfessionalEmail,
      repairProfessionalBio: repairProfessionalBio ?? this.repairProfessionalBio,
      cost: cost ?? this.cost,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      attachments: attachments ?? this.attachments,
    );
  }

  // Getters
  bool get isForJobRequest => jobRequestId != null && jobRequestId!.isNotEmpty;
  bool get isForDamageReport => reportId.isNotEmpty;
  bool get isCompleted => completedAt != null;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  
  // Time picker helper methods
  Map<String, int> get leadTimeBreakdown {
    // Check if the value is likely stored as days (old format) or minutes (new format)
    // If leadTimeDays > 30, it's probably stored as minutes (new format)
    // If leadTimeDays <= 30, it could be either, but we'll assume minutes for new estimates
    final totalMinutes = _isStoredAsMinutes() ? leadTimeDays : (leadTimeDays * 24 * 60);
    
    final days = totalMinutes ~/ (24 * 60);
    final remainingMinutes = totalMinutes % (24 * 60);
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    
    return {
      'days': days,
      'hours': hours,
      'minutes': minutes,
    };
  }
  
  String get leadTimeDisplay {
    final breakdown = leadTimeBreakdown;
    final parts = <String>[];
    
    // Debug logging
    print('🔍 [Estimate] ID: $id, Raw leadTimeDays: $leadTimeDays, Is stored as minutes: ${_isStoredAsMinutes()}');
    print('🔍 [Estimate] Breakdown: days=${breakdown['days']}, hours=${breakdown['hours']}, minutes=${breakdown['minutes']}');
    
    if (breakdown['days']! > 0) parts.add('${breakdown['days']}d');
    if (breakdown['hours']! > 0) parts.add('${breakdown['hours']}h');
    if (breakdown['minutes']! > 0) parts.add('${breakdown['minutes']}m');
    
    if (parts.isEmpty) return '0m';
    final result = parts.join(' ');
    print('🔍 [Estimate] Final display: $result');
    return result;
  }
  
  // Helper method to determine if leadTimeDays is stored as minutes or days
  bool _isStoredAsMinutes() {
    // If the value is very large (> 30), it's likely stored as minutes
    // If it's small (<= 30), it could be either, but we'll assume minutes for consistency
    // This is a heuristic - in practice, most reasonable lead times in days would be <= 30
    return leadTimeDays > 30 || submittedAt.isAfter(DateTime(2024, 12, 1)); // Assume new format after Dec 1, 2024
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Estimate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Estimate(id: $id, cost: \$${cost.toStringAsFixed(2)}, leadTime: $leadTimeDisplay, status: $status)';
  }

  // Helper method to parse timestamps from both Timestamp and String
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    return null;
  }
}

enum EstimateStatus {
  pending,
  accepted,
  declined,
}
