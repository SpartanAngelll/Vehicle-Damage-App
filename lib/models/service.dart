import 'package:cloud_firestore/cloud_firestore.dart';

enum TravelMode {
  customerTravels,
  proTravels,
  remote,
}

class Service {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String professionalId;
  final double basePrice;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Travel-related fields
  final TravelMode defaultTravel;
  final bool proTravelsAvailable;
  final double? travelFee;
  final double? travelRadiusKm;
  final String? shopAddress;
  final String? shopCity;
  final String? shopState;
  final String? shopPostalCode;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.professionalId,
    required this.basePrice,
    this.currency = 'JMD',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.defaultTravel = TravelMode.customerTravels,
    this.proTravelsAvailable = false,
    this.travelFee,
    this.travelRadiusKm,
    this.shopAddress,
    this.shopCity,
    this.shopState,
    this.shopPostalCode,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'professionalId': professionalId,
      'basePrice': basePrice,
      'currency': currency,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'defaultTravel': defaultTravel.name,
      'proTravelsAvailable': proTravelsAvailable,
      'travelFee': travelFee,
      'travelRadiusKm': travelRadiusKm,
      'shopAddress': shopAddress,
      'shopCity': shopCity,
      'shopState': shopState,
      'shopPostalCode': shopPostalCode,
    };
  }

  // Create from Firestore document
  factory Service.fromMap(Map<String, dynamic> map, String documentId) {
    return Service(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'JMD',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      defaultTravel: TravelMode.values.firstWhere(
        (e) => e.name == map['defaultTravel'],
        orElse: () => TravelMode.customerTravels,
      ),
      proTravelsAvailable: map['proTravelsAvailable'] ?? false,
      travelFee: map['travelFee']?.toDouble(),
      travelRadiusKm: map['travelRadiusKm']?.toDouble(),
      shopAddress: map['shopAddress'],
      shopCity: map['shopCity'],
      shopState: map['shopState'],
      shopPostalCode: map['shopPostalCode'],
    );
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? professionalId,
    double? basePrice,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    TravelMode? defaultTravel,
    bool? proTravelsAvailable,
    double? travelFee,
    double? travelRadiusKm,
    String? shopAddress,
    String? shopCity,
    String? shopState,
    String? shopPostalCode,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      professionalId: professionalId ?? this.professionalId,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultTravel: defaultTravel ?? this.defaultTravel,
      proTravelsAvailable: proTravelsAvailable ?? this.proTravelsAvailable,
      travelFee: travelFee ?? this.travelFee,
      travelRadiusKm: travelRadiusKm ?? this.travelRadiusKm,
      shopAddress: shopAddress ?? this.shopAddress,
      shopCity: shopCity ?? this.shopCity,
      shopState: shopState ?? this.shopState,
      shopPostalCode: shopPostalCode ?? this.shopPostalCode,
    );
  }

  // Helper methods
  String get fullShopAddress {
    final parts = [shopAddress, shopCity, shopState, shopPostalCode]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  bool get hasTravelFee => travelFee != null && travelFee! > 0;
  
  bool get canTravelToCustomer => proTravelsAvailable && travelRadiusKm != null;
  
  String get travelModeDisplayName {
    switch (defaultTravel) {
      case TravelMode.customerTravels:
        return 'Customer travels to shop';
      case TravelMode.proTravels:
        return 'Professional travels to customer';
      case TravelMode.remote:
        return 'Remote service';
    }
  }
}
