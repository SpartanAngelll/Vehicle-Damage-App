import 'package:flutter/material.dart';

class ServiceProfessional {
  final String id;
  final String userId;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? bio;
  final String? profilePhotoUrl; // Profile photo URL
  final String? coverPhotoUrl; // Cover photo URL
  final List<String> workShowcaseImages; // Work showcase images
  final double? latitude; // Location latitude
  final double? longitude; // Location longitude
  final String? address; // Human-readable address
  final List<String> categoryIds; // Multiple categories supported
  final List<String> specializations; // Specific skills within categories
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;
  final String? website;
  final List<String> certifications;
  final int yearsOfExperience;
  final int jobsCompleted; // Number of completed jobs
  final double averageRating;
  final int totalReviews;
  final bool isVerified;
  final bool isAvailable;
  final List<String> serviceAreas; // Geographic areas served
  final Map<String, dynamic>? categorySpecificData; // For category-specific fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActive;
  final String? role; // User role (e.g., 'service_professional')

  ServiceProfessional({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.bio,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    List<String>? workShowcaseImages,
    this.latitude,
    this.longitude,
    this.address,
    required this.categoryIds,
    List<String>? specializations,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
    this.website,
    List<String>? certifications,
    this.yearsOfExperience = 0,
    this.jobsCompleted = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isAvailable = true,
    List<String>? serviceAreas,
    this.categorySpecificData,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastActive,
    this.role,
  }) : 
    workShowcaseImages = workShowcaseImages ?? [],
    specializations = specializations ?? [],
    certifications = certifications ?? [],
    serviceAreas = serviceAreas ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'profilePhotoUrl': profilePhotoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'workShowcaseImages': workShowcaseImages,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'categoryIds': categoryIds,
      'specializations': specializations,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'website': website,
      'certifications': certifications,
      'yearsOfExperience': yearsOfExperience,
      'jobsCompleted': jobsCompleted,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'serviceAreas': serviceAreas,
      'categorySpecificData': categorySpecificData,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastActive': lastActive,
      'role': role,
    };
  }

  // Create from Firestore document
  factory ServiceProfessional.fromMap(Map<String, dynamic> map, String documentId) {
    return ServiceProfessional(
      id: documentId,
      userId: map['userId'] ?? map['id'] ?? documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? 'Service Professional',
      phoneNumber: map['phoneNumber'] ?? map['phone'],
      bio: map['bio'],
      profilePhotoUrl: map['profilePhotoUrl'],
      coverPhotoUrl: map['coverPhotoUrl'],
      workShowcaseImages: List<String>.from(map['workShowcaseImages'] ?? []),
      latitude: (map['latitude'] is num) ? map['latitude'].toDouble() : null,
      longitude: (map['longitude'] is num) ? map['longitude'].toDouble() : null,
      address: map['address'],
      categoryIds: List<String>.from(map['categoryIds'] ?? []),
      specializations: List<String>.from(map['specializations'] ?? []),
      businessName: map['businessName'],
      businessAddress: map['businessAddress'],
      businessPhone: map['businessPhone'],
      website: map['website'],
      certifications: List<String>.from(map['certifications'] ?? []),
      yearsOfExperience: (map['yearsOfExperience'] is int) ? map['yearsOfExperience'] : 0,
      jobsCompleted: (map['jobsCompleted'] is int) ? map['jobsCompleted'] : 0,
      averageRating: (map['averageRating'] is num) ? map['averageRating'].toDouble() : 0.0,
      totalReviews: (map['totalReviews'] is int) ? map['totalReviews'] : 0,
      isVerified: (map['isVerified'] is bool) ? map['isVerified'] : false,
      isAvailable: (map['isAvailable'] is bool) ? map['isAvailable'] : true,
      serviceAreas: List<String>.from(map['serviceAreas'] ?? []),
      categorySpecificData: map['categorySpecificData'] != null 
        ? Map<String, dynamic>.from(map['categorySpecificData'])
        : null,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      lastActive: _parseDateTime(map['lastActive']),
      role: map['role'],
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('❌ [ServiceProfessional] Error parsing date string: $dateValue - $e');
        return null;
      }
    } else if (dateValue.runtimeType.toString().contains('Timestamp')) {
      // Firestore Timestamp
      try {
        return dateValue.toDate();
      } catch (e) {
        print('❌ [ServiceProfessional] Error parsing Firestore Timestamp: $dateValue - $e');
        return null;
      }
    }
    
    return null;
  }

  // Backward compatibility: Convert from old repairman data
  factory ServiceProfessional.fromRepairmanData(Map<String, dynamic> repairmanData) {
    return ServiceProfessional(
      id: repairmanData['id'] ?? repairmanData['userId'] ?? '',
      userId: repairmanData['userId'] ?? repairmanData['id'] ?? '',
      email: repairmanData['email'] ?? '',
      fullName: repairmanData['fullName'] ?? repairmanData['name'] ?? 'Auto Repair Professional',
      phoneNumber: repairmanData['phoneNumber'] ?? repairmanData['phone'],
      bio: repairmanData['bio'] ?? 'Experienced auto repair professional',
      categoryIds: ['mechanics'], // Default to mechanics for backward compatibility
      specializations: ['Auto Repair', 'Vehicle Maintenance'],
      businessName: repairmanData['businessName'],
      businessAddress: repairmanData['businessAddress'],
      businessPhone: repairmanData['businessPhone'],
      yearsOfExperience: repairmanData['yearsOfExperience'] ?? 0,
      averageRating: repairmanData['averageRating']?.toDouble() ?? 0.0,
      totalReviews: repairmanData['totalReviews'] ?? 0,
      isVerified: repairmanData['isVerified'] ?? false,
      isAvailable: repairmanData['isAvailable'] ?? true,
      createdAt: repairmanData['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: repairmanData['updatedAt']?.toDate() ?? DateTime.now(),
      role: 'service_professional',
    );
  }

  // Getters
  bool get hasMultipleCategories => categoryIds.length > 1;
  bool get isExperienced => yearsOfExperience >= 5;
  bool get isHighlyRated => averageRating >= 4.5;
  bool get hasCertifications => certifications.isNotEmpty;
  bool get hasBusinessInfo => businessName != null && businessName!.isNotEmpty;
  bool get isRecentlyActive => lastActive != null && 
    DateTime.now().difference(lastActive!).inDays < 7;

  // Copy with method
  ServiceProfessional copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
    List<String>? workShowcaseImages,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? categoryIds,
    List<String>? specializations,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? website,
    List<String>? certifications,
    int? yearsOfExperience,
    int? jobsCompleted,
    double? averageRating,
    int? totalReviews,
    bool? isVerified,
    bool? isAvailable,
    List<String>? serviceAreas,
    Map<String, dynamic>? categorySpecificData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    String? role,
  }) {
    return ServiceProfessional(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      workShowcaseImages: workShowcaseImages ?? this.workShowcaseImages,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      categoryIds: categoryIds ?? this.categoryIds,
      specializations: specializations ?? this.specializations,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      website: website ?? this.website,
      certifications: certifications ?? this.certifications,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      categorySpecificData: categorySpecificData ?? this.categorySpecificData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
      lastActive: lastActive ?? this.lastActive,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceProfessional && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ServiceProfessional(id: $id, name: $fullName, categories: $categoryIds)';
  }
}
