import 'package:cloud_firestore/cloud_firestore.dart';

class BankingDetails {
  final String id;
  final String professionalId;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String routingNumber; // For US banks, or equivalent for other countries
  final String? branchCode; // Optional branch code
  final String? swiftCode; // For international transfers
  final String? iban; // For European banks
  final String accountType; // 'checking', 'savings', 'business'
  final String currency; // 'JMD', 'USD', etc.
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedForPayout; // Track when last used for payout
  final Map<String, dynamic>? metadata; // Additional bank-specific data

  BankingDetails({
    required this.id,
    required this.professionalId,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.routingNumber,
    this.branchCode,
    this.swiftCode,
    this.iban,
    this.accountType = 'checking',
    this.currency = 'JMD',
    this.isVerified = false,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastUsedForPayout,
    this.metadata,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'professionalId': professionalId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'routingNumber': routingNumber,
      'branchCode': branchCode,
      'swiftCode': swiftCode,
      'iban': iban,
      'accountType': accountType,
      'currency': currency,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastUsedForPayout': lastUsedForPayout,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory BankingDetails.fromMap(Map<String, dynamic> map, String documentId) {
    return BankingDetails(
      id: documentId,
      professionalId: map['professionalId'] ?? '',
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountHolderName: map['accountHolderName'] ?? '',
      routingNumber: map['routingNumber'] ?? '',
      branchCode: map['branchCode'],
      swiftCode: map['swiftCode'],
      iban: map['iban'],
      accountType: map['accountType'] ?? 'checking',
      currency: map['currency'] ?? 'JMD',
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      lastUsedForPayout: _parseDateTime(map['lastUsedForPayout']),
      metadata: map['metadata'] != null 
        ? Map<String, dynamic>.from(map['metadata'])
        : null,
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
        print('❌ [BankingDetails] Error parsing date string: $dateValue - $e');
        return null;
      }
    } else if (dateValue.runtimeType.toString().contains('Timestamp')) {
      // Firestore Timestamp
      try {
        return dateValue.toDate();
      } catch (e) {
        print('❌ [BankingDetails] Error parsing Firestore Timestamp: $dateValue - $e');
        return null;
      }
    }
    
    return null;
  }

  // Copy with method
  BankingDetails copyWith({
    String? id,
    String? professionalId,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
    String? routingNumber,
    String? branchCode,
    String? swiftCode,
    String? iban,
    String? accountType,
    String? currency,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedForPayout,
    Map<String, dynamic>? metadata,
  }) {
    return BankingDetails(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      routingNumber: routingNumber ?? this.routingNumber,
      branchCode: branchCode ?? this.branchCode,
      swiftCode: swiftCode ?? this.swiftCode,
      iban: iban ?? this.iban,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
      lastUsedForPayout: lastUsedForPayout ?? this.lastUsedForPayout,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters
  bool get isComplete => 
    bankName.isNotEmpty && 
    accountNumber.isNotEmpty && 
    accountHolderName.isNotEmpty && 
    routingNumber.isNotEmpty;

  bool get isInternational => swiftCode != null && swiftCode!.isNotEmpty;
  
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  String get displayName => '$bankName - $maskedAccountNumber';

  // Validation methods
  static String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank name is required';
    }
    if (value.trim().length < 2) {
      return 'Bank name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    // Remove spaces and dashes for validation
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleanValue.length < 4) {
      return 'Account number must be at least 4 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  static String? validateAccountHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account holder name is required';
    }
    if (value.trim().length < 2) {
      return 'Account holder name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRoutingNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Routing number is required';
    }
    // Remove spaces and dashes for validation
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleanValue.length < 6) {
      return 'Routing number must be at least 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Routing number must contain only digits';
    }
    return null;
  }

  static String? validateSwiftCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final cleanValue = value.trim().toUpperCase();
    if (cleanValue.length != 8 && cleanValue.length != 11) {
      return 'SWIFT code must be 8 or 11 characters';
    }
    if (!RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(cleanValue)) {
      return 'Invalid SWIFT code format';
    }
    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final cleanValue = value.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (cleanValue.length < 15 || cleanValue.length > 34) {
      return 'IBAN must be between 15 and 34 characters';
    }
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(cleanValue)) {
      return 'Invalid IBAN format';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankingDetails && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BankingDetails(id: $id, professionalId: $professionalId, bankName: $bankName, accountNumber: $maskedAccountNumber)';
  }
}

// Banking details validation result
class BankingDetailsValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final BankingDetails? bankingDetails;

  BankingDetailsValidationResult({
    required this.isValid,
    required this.errors,
    this.bankingDetails,
  });

  bool get hasErrors => errors.isNotEmpty;
  String? getFieldError(String field) => errors[field];
}

// Banking details form data
class BankingDetailsFormData {
  String bankName;
  String accountNumber;
  String accountHolderName;
  String routingNumber;
  String? branchCode;
  String? swiftCode;
  String? iban;
  String accountType;
  String currency;

  BankingDetailsFormData({
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolderName = '',
    this.routingNumber = '',
    this.branchCode,
    this.swiftCode,
    this.iban,
    this.accountType = 'checking',
    this.currency = 'JMD',
  });

  BankingDetailsFormData.fromBankingDetails(BankingDetails details) :
    bankName = details.bankName,
    accountNumber = details.accountNumber,
    accountHolderName = details.accountHolderName,
    routingNumber = details.routingNumber,
    branchCode = details.branchCode,
    swiftCode = details.swiftCode,
    iban = details.iban,
    accountType = details.accountType,
    currency = details.currency;

  Map<String, String> validate() {
    final errors = <String, String>{};
    
    final bankNameError = BankingDetails.validateBankName(bankName);
    if (bankNameError != null) errors['bankName'] = bankNameError;
    
    final accountNumberError = BankingDetails.validateAccountNumber(accountNumber);
    if (accountNumberError != null) errors['accountNumber'] = accountNumberError;
    
    final accountHolderNameError = BankingDetails.validateAccountHolderName(accountHolderName);
    if (accountHolderNameError != null) errors['accountHolderName'] = accountHolderNameError;
    
    final routingNumberError = BankingDetails.validateRoutingNumber(routingNumber);
    if (routingNumberError != null) errors['routingNumber'] = routingNumberError;
    
    final swiftCodeError = BankingDetails.validateSwiftCode(swiftCode);
    if (swiftCodeError != null) errors['swiftCode'] = swiftCodeError;
    
    final ibanError = BankingDetails.validateIban(iban);
    if (ibanError != null) errors['iban'] = ibanError;
    
    return errors;
  }

  bool get isValid => validate().isEmpty;

  BankingDetails toBankingDetails(String professionalId) {
    return BankingDetails(
      id: '', // Will be set by the service
      professionalId: professionalId,
      bankName: bankName.trim(),
      accountNumber: accountNumber.replaceAll(RegExp(r'[\s\-]'), ''),
      accountHolderName: accountHolderName.trim(),
      routingNumber: routingNumber.replaceAll(RegExp(r'[\s\-]'), ''),
      branchCode: branchCode?.trim().isNotEmpty == true ? branchCode!.trim() : null,
      swiftCode: swiftCode?.trim().isNotEmpty == true ? swiftCode!.trim().toUpperCase() : null,
      iban: iban?.trim().isNotEmpty == true ? iban!.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '') : null,
      accountType: accountType,
      currency: currency,
    );
  }
}
