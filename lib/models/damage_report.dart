import 'dart:io';

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
  final String reportId;
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

  Estimate({
    String? id,
    required this.reportId,
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
  }) :
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    imageUrls = imageUrls ?? [],
    status = status,
    submittedAt = submittedAt ?? DateTime.now(),
    updatedAt = updatedAt,
    acceptedAt = acceptedAt,
    declinedAt = declinedAt;

  Estimate copyWith({
    String? id,
    String? reportId,
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
  }) {
    return Estimate(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
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
    );
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
    return 'Estimate(id: $id, cost: \$${cost.toStringAsFixed(2)}, leadTime: $leadTimeDays days, status: $status)';
  }
}

enum EstimateStatus {
  pending,
  accepted,
  declined,
}
