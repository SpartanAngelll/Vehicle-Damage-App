import 'package:uuid/uuid.dart';

enum PayoutStatus {
  pending,
  success,
  failed,
}

class Payout {
  final String id;
  final String professionalId;
  final double amount;
  final String currency;
  final PayoutStatus status;
  final String? paymentProcessorTransactionId;
  final Map<String, dynamic>? paymentProcessorResponse;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  Payout({
    required this.id,
    required this.professionalId,
    required this.amount,
    this.currency = 'JMD',
    this.status = PayoutStatus.pending,
    this.paymentProcessorTransactionId,
    this.paymentProcessorResponse,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  factory Payout.fromMap(Map<String, dynamic> map) {
    return Payout(
      id: map['id'] as String,
      professionalId: map['professional_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'JMD',
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => PayoutStatus.pending,
      ),
      paymentProcessorTransactionId: map['payment_processor_transaction_id'] as String?,
      paymentProcessorResponse: map['payment_processor_response'] != null
          ? Map<String, dynamic>.from(map['payment_processor_response'] as Map)
          : null,
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completed_at']),
      errorMessage: map['error_message'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'professional_id': professionalId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'payment_processor_transaction_id': paymentProcessorTransactionId,
      'payment_processor_response': paymentProcessorResponse,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'professionalId': professionalId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'paymentProcessorTransactionId': paymentProcessorTransactionId,
      'paymentProcessorResponse': paymentProcessorResponse,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  // Create from Firestore document
  factory Payout.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Payout(
      id: documentId,
      professionalId: map['professionalId'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'JMD',
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => PayoutStatus.pending,
      ),
      paymentProcessorTransactionId: map['paymentProcessorTransactionId'] as String?,
      paymentProcessorResponse: map['paymentProcessorResponse'] != null
          ? Map<String, dynamic>.from(map['paymentProcessorResponse'] as Map)
          : null,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      errorMessage: map['errorMessage'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('❌ [Payout] Error parsing date string: $dateValue - $e');
        return null;
      }
    } else if (dateValue.runtimeType.toString().contains('Timestamp')) {
      // Firestore Timestamp
      try {
        return dateValue.toDate();
      } catch (e) {
        print('❌ [Payout] Error parsing Firestore Timestamp: $dateValue - $e');
        return null;
      }
    }
    
    return null;
  }

  Payout copyWith({
    String? id,
    String? professionalId,
    double? amount,
    String? currency,
    PayoutStatus? status,
    String? paymentProcessorTransactionId,
    Map<String, dynamic>? paymentProcessorResponse,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Payout(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentProcessorTransactionId: paymentProcessorTransactionId ?? this.paymentProcessorTransactionId,
      paymentProcessorResponse: paymentProcessorResponse ?? this.paymentProcessorResponse,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters
  bool get isPending => status == PayoutStatus.pending;
  bool get isSuccess => status == PayoutStatus.success;
  bool get isFailed => status == PayoutStatus.failed;
  bool get isCompleted => isSuccess || isFailed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payout && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payout(id: $id, professionalId: $professionalId, amount: $amount, status: $status)';
  }
}

class ProfessionalBalance {
  final String professionalId;
  final double availableBalance;
  final double totalEarned;
  final double totalPaidOut;
  final DateTime lastUpdated;
  final DateTime createdAt;

  ProfessionalBalance({
    required this.professionalId,
    required this.availableBalance,
    required this.totalEarned,
    required this.totalPaidOut,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory ProfessionalBalance.fromMap(Map<String, dynamic> map) {
    return ProfessionalBalance(
      professionalId: map['professional_id'] as String,
      availableBalance: _parseDouble(map['available_balance']),
      totalEarned: _parseDouble(map['total_earned']),
      totalPaidOut: _parseDouble(map['total_paid_out']),
      lastUpdated: _parseDateTime(map['last_updated']) ?? DateTime.now(),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professional_id': professionalId,
      'available_balance': availableBalance,
      'total_earned': totalEarned,
      'total_paid_out': totalPaidOut,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'professionalId': professionalId,
      'availableBalance': availableBalance,
      'totalEarned': totalEarned,
      'totalPaidOut': totalPaidOut,
      'lastUpdated': lastUpdated,
      'createdAt': createdAt,
    };
  }

  // Create from Firestore document
  factory ProfessionalBalance.fromFirestore(Map<String, dynamic> map, String documentId) {
    return ProfessionalBalance(
      professionalId: documentId,
      availableBalance: _parseDouble(map['availableBalance']),
      totalEarned: _parseDouble(map['totalEarned']),
      totalPaidOut: _parseDouble(map['totalPaidOut']),
      lastUpdated: _parseDateTime(map['lastUpdated']) ?? DateTime.now(),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('❌ [ProfessionalBalance] Error parsing date string: $dateValue - $e');
        return null;
      }
    } else if (dateValue.runtimeType.toString().contains('Timestamp')) {
      // Firestore Timestamp
      try {
        return dateValue.toDate();
      } catch (e) {
        print('❌ [ProfessionalBalance] Error parsing Firestore Timestamp: $dateValue - $e');
        return null;
      }
    }
    
    return null;
  }

  ProfessionalBalance copyWith({
    String? professionalId,
    double? availableBalance,
    double? totalEarned,
    double? totalPaidOut,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return ProfessionalBalance(
      professionalId: professionalId ?? this.professionalId,
      availableBalance: availableBalance ?? this.availableBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalPaidOut: totalPaidOut ?? this.totalPaidOut,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Getters
  bool get hasAvailableBalance => availableBalance > 0;
  double get netEarnings => totalEarned - totalPaidOut;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfessionalBalance && other.professionalId == professionalId;
  }

  @override
  int get hashCode => professionalId.hashCode;

  @override
  String toString() {
    return 'ProfessionalBalance(professionalId: $professionalId, availableBalance: $availableBalance, totalEarned: $totalEarned)';
  }
}

class PayoutStatusHistory {
  final String id;
  final String payoutId;
  final PayoutStatus status;
  final DateTime changedAt;
  final String? changedBy;
  final String? notes;

  PayoutStatusHistory({
    required this.id,
    required this.payoutId,
    required this.status,
    required this.changedAt,
    this.changedBy,
    this.notes,
  });

  factory PayoutStatusHistory.fromMap(Map<String, dynamic> map) {
    return PayoutStatusHistory(
      id: map['id'] as String,
      payoutId: map['payout_id'] as String,
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => PayoutStatus.pending,
      ),
      changedAt: _parseDateTime(map['changed_at']) ?? DateTime.now(),
      changedBy: map['changed_by'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payout_id': payoutId,
      'status': status.name,
      'changed_at': changedAt.toIso8601String(),
      'changed_by': changedBy,
      'notes': notes,
    };
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('❌ [PayoutStatusHistory] Error parsing date string: $dateValue - $e');
        return null;
      }
    } else if (dateValue.runtimeType.toString().contains('Timestamp')) {
      // Firestore Timestamp
      try {
        return dateValue.toDate();
      } catch (e) {
        print('❌ [PayoutStatusHistory] Error parsing Firestore Timestamp: $dateValue - $e');
        return null;
      }
    }
    
    return null;
  }

  @override
  String toString() {
    return 'PayoutStatusHistory(id: $id, payoutId: $payoutId, status: $status, changedAt: $changedAt)';
  }
}

// Cash-out request model for API
class CashOutRequest {
  final String professionalId;
  final double amount;

  CashOutRequest({
    required this.professionalId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'professional_id': professionalId,
      'amount': amount,
    };
  }

  factory CashOutRequest.fromMap(Map<String, dynamic> map) {
    return CashOutRequest(
      professionalId: map['professional_id'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'CashOutRequest(professionalId: $professionalId, amount: $amount)';
  }
}

// Cash-out response model for API
class CashOutResponse {
  final bool success;
  final String? message;
  final Payout? payout;
  final String? error;

  CashOutResponse({
    required this.success,
    this.message,
    this.payout,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'payout': payout?.toMap(),
      'error': error,
    };
  }

  factory CashOutResponse.fromMap(Map<String, dynamic> map) {
    return CashOutResponse(
      success: map['success'] as bool,
      message: map['message'] as String?,
      payout: map['payout'] != null ? Payout.fromMap(map['payout'] as Map<String, dynamic>) : null,
      error: map['error'] as String?,
    );
  }

  @override
  String toString() {
    return 'CashOutResponse(success: $success, message: $message, error: $error)';
  }
}

class CashOutValidationResult {
  final bool isValid;
  final String? error;
  final double? availableBalance;

  CashOutValidationResult({
    required this.isValid,
    this.error,
    this.availableBalance,
  });

  factory CashOutValidationResult.fromMap(Map<String, dynamic> map) {
    return CashOutValidationResult(
      isValid: map['is_valid'] as bool? ?? false,
      error: map['error'] as String?,
      availableBalance: (map['available_balance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_valid': isValid,
      'error': error,
      'available_balance': availableBalance,
    };
  }

  @override
  String toString() {
    return 'CashOutValidationResult(isValid: $isValid, error: $error, availableBalance: $availableBalance)';
  }
}

class CashOutStats {
  final double availableBalance;
  final double totalEarned;
  final double totalPaidOut;
  final int pendingPayouts;
  final int completedPayouts;
  final int failedPayouts;

  CashOutStats({
    required this.availableBalance,
    required this.totalEarned,
    required this.totalPaidOut,
    required this.pendingPayouts,
    required this.completedPayouts,
    required this.failedPayouts,
  });

  factory CashOutStats.fromMap(Map<String, dynamic> map) {
    return CashOutStats(
      availableBalance: (map['available_balance'] as num).toDouble(),
      totalEarned: (map['total_earned'] as num).toDouble(),
      totalPaidOut: (map['total_paid_out'] as num).toDouble(),
      pendingPayouts: map['pending_payouts'] as int,
      completedPayouts: map['completed_payouts'] as int,
      failedPayouts: map['failed_payouts'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'available_balance': availableBalance,
      'total_earned': totalEarned,
      'total_paid_out': totalPaidOut,
      'pending_payouts': pendingPayouts,
      'completed_payouts': completedPayouts,
      'failed_payouts': failedPayouts,
    };
  }

  @override
  String toString() {
    return 'CashOutStats(availableBalance: $availableBalance, totalEarned: $totalEarned, totalPaidOut: $totalPaidOut, pendingPayouts: $pendingPayouts, completedPayouts: $completedPayouts, failedPayouts: $failedPayouts)';
  }
}