import 'dart:io';

class DamageReport {
  final File image;
  final String description;
  final DateTime timestamp;
  final List<Estimate> estimates;
  final String id;

  DamageReport({
    required this.image,
    required this.description,
    required this.timestamp,
    List<Estimate>? estimates,
  }) :
    estimates = estimates ?? [],
    id = DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasEstimates => estimates.isNotEmpty;
  int get estimateCount => estimates.length;
  bool get isRecent => DateTime.now().difference(timestamp).inDays < 7;

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

  void updateDescription(String newDescription) {
    // Note: This creates a new instance since description is final
    // In a real app, you might want to make this mutable or use a different approach
  }

  DamageReport copyWith({
    File? image,
    String? description,
    DateTime? timestamp,
    List<Estimate>? estimates,
  }) {
    return DamageReport(
      image: image ?? this.image,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      estimates: estimates ?? this.estimates,
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
    return 'DamageReport(id: $id, description: $description, estimates: $estimates)';
  }
}

class Estimate {
  final String id;
  final String repairProfessionalId;
  final String repairProfessionalEmail;
  final String? repairProfessionalBio;
  final double cost;
  final int leadTimeDays;
  final String description;
  final EstimateStatus status;
  final DateTime submittedAt;

  Estimate({
    required this.repairProfessionalId,
    required this.repairProfessionalEmail,
    this.repairProfessionalBio,
    required this.cost,
    required this.leadTimeDays,
    required this.description,
    EstimateStatus status = EstimateStatus.pending,
    DateTime? submittedAt,
  }) :
    id = DateTime.now().millisecondsSinceEpoch.toString(),
    status = status,
    submittedAt = submittedAt ?? DateTime.now();

  Estimate copyWith({
    String? repairProfessionalId,
    String? repairProfessionalEmail,
    String? repairProfessionalBio,
    double? cost,
    int? leadTimeDays,
    String? description,
    EstimateStatus? status,
    DateTime? submittedAt,
  }) {
    return Estimate(
      repairProfessionalId: repairProfessionalId ?? this.repairProfessionalId,
      repairProfessionalEmail: repairProfessionalEmail ?? this.repairProfessionalEmail,
      repairProfessionalBio: repairProfessionalBio ?? this.repairProfessionalBio,
      cost: cost ?? this.cost,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      description: description ?? this.description,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
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
