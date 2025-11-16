import 'dart:io';

enum JobStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum JobPriority {
  low,
  medium,
  high,
  urgent,
}

class JobRequest {
  final String id;
  final String customerId;
  final String customerEmail;
  final String title;
  final String description;
  final List<String> categoryIds; // Multiple categories supported
  final List<String> imageUrls;
  final double? estimatedBudget; // Deprecated: kept for backward compatibility
  final Map<String, double>? categoryBudgets; // Budget per category
  final Map<String, Map<String, dynamic>>? categoryCustomFields; // Custom fields per category
  final String? location;
  final String? contactPhone;
  final JobStatus status;
  final JobPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadline;
  final List<String> tags;
  final Map<String, dynamic>? customFields; // For category-specific data (deprecated, use categoryCustomFields)

  JobRequest({
    String? id,
    required this.customerId,
    required this.customerEmail,
    required this.title,
    required this.description,
    required this.categoryIds,
    required this.imageUrls,
    this.estimatedBudget,
    this.categoryBudgets,
    this.categoryCustomFields,
    this.location,
    this.contactPhone,
    JobStatus? status,
    JobPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deadline,
    List<String>? tags,
    this.customFields,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    status = status ?? JobStatus.pending,
    priority = priority ?? JobPriority.medium,
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    tags = tags ?? [];

  // Backward compatibility: Convert from old DamageReport
  factory JobRequest.fromDamageReport(Map<String, dynamic> damageReport) {
    return JobRequest(
      id: damageReport['id'],
      customerId: damageReport['ownerId'],
      customerEmail: damageReport['ownerEmail'] ?? '',
      title: 'Vehicle Repair: ${damageReport['vehicleMake']} ${damageReport['vehicleModel']}',
      description: damageReport['damageDescription'] ?? damageReport['description'] ?? '',
      categoryIds: ['mechanics'], // Default to mechanics for backward compatibility
      imageUrls: List<String>.from(damageReport['imageUrls'] ?? []),
      estimatedBudget: damageReport['estimatedCost']?.toDouble(),
      status: _parseJobStatus(damageReport['status']),
      createdAt: damageReport['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: damageReport['updatedAt']?.toDate() ?? DateTime.now(),
      customFields: {
        'vehicleMake': damageReport['vehicleMake'],
        'vehicleModel': damageReport['vehicleModel'],
        'vehicleYear': damageReport['vehicleYear'],
        'additionalNotes': damageReport['additionalNotes'],
      },
    );
  }

  static JobStatus _parseJobStatus(String? status) {
    switch (status) {
      case 'pending':
        return JobStatus.pending;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      default:
        return JobStatus.pending;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerEmail': customerEmail,
      'title': title,
      'description': description,
      'categoryIds': categoryIds,
      'imageUrls': imageUrls,
      'estimatedBudget': estimatedBudget,
      'categoryBudgets': categoryBudgets,
      'categoryCustomFields': categoryCustomFields,
      'location': location,
      'contactPhone': contactPhone,
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deadline': deadline,
      'tags': tags,
      'customFields': customFields,
    };
  }

  // Create from Firestore document
  factory JobRequest.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse categoryBudgets
    Map<String, double>? categoryBudgets;
    if (map['categoryBudgets'] != null) {
      final budgetsMap = map['categoryBudgets'] as Map<String, dynamic>;
      categoryBudgets = budgetsMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
    
    // Parse categoryCustomFields
    Map<String, Map<String, dynamic>>? categoryCustomFields;
    if (map['categoryCustomFields'] != null) {
      final fieldsMap = map['categoryCustomFields'] as Map<String, dynamic>;
      categoryCustomFields = fieldsMap.map((key, value) => 
        MapEntry(key, Map<String, dynamic>.from(value as Map<dynamic, dynamic>)));
    }
    
    return JobRequest(
      id: documentId,
      customerId: map['customerId'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryIds: List<String>.from(map['categoryIds'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      estimatedBudget: map['estimatedBudget']?.toDouble(),
      categoryBudgets: categoryBudgets,
      categoryCustomFields: categoryCustomFields,
      location: map['location'],
      contactPhone: map['contactPhone'],
      status: _parseJobStatus(map['status']),
      priority: _parseJobPriority(map['priority']),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      deadline: map['deadline']?.toDate(),
      tags: List<String>.from(map['tags'] ?? []),
      customFields: map['customFields'] != null 
        ? Map<String, dynamic>.from(map['customFields'])
        : null,
    );
  }

  static JobPriority _parseJobPriority(String? priority) {
    switch (priority) {
      case 'low':
        return JobPriority.low;
      case 'medium':
        return JobPriority.medium;
      case 'high':
        return JobPriority.high;
      case 'urgent':
        return JobPriority.urgent;
      default:
        return JobPriority.medium;
    }
  }

  // Getters
  bool get isPending => status == JobStatus.pending;
  bool get isInProgress => status == JobStatus.inProgress;
  bool get isCompleted => status == JobStatus.completed;
  bool get isCancelled => status == JobStatus.cancelled;
  bool get isUrgent => priority == JobPriority.urgent;
  bool get isHighPriority => priority == JobPriority.high || priority == JobPriority.urgent;
  bool get hasDeadline => deadline != null;
  bool get isOverdue => hasDeadline && DateTime.now().isAfter(deadline!);
  bool get isRecent => DateTime.now().difference(createdAt).inDays < 7;

  // Copy with method
  JobRequest copyWith({
    String? id,
    String? customerId,
    String? customerEmail,
    String? title,
    String? description,
    List<String>? categoryIds,
    List<String>? imageUrls,
    double? estimatedBudget,
    Map<String, double>? categoryBudgets,
    Map<String, Map<String, dynamic>>? categoryCustomFields,
    String? location,
    String? contactPhone,
    JobStatus? status,
    JobPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    List<String>? tags,
    Map<String, dynamic>? customFields,
  }) {
    return JobRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerEmail: customerEmail ?? this.customerEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryIds: categoryIds ?? this.categoryIds,
      imageUrls: imageUrls ?? this.imageUrls,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      categoryCustomFields: categoryCustomFields ?? this.categoryCustomFields,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
      deadline: deadline ?? this.deadline,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
    );
  }
  
  // Helper method to get budget for a specific category
  double? getBudgetForCategory(String categoryId) {
    return categoryBudgets?[categoryId] ?? estimatedBudget;
  }
  
  // Helper method to get custom fields for a specific category
  Map<String, dynamic>? getCustomFieldsForCategory(String categoryId) {
    return categoryCustomFields?[categoryId] ?? customFields;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'JobRequest(id: $id, title: $title, status: $status, categories: $categoryIds)';
  }
}
