import 'package:uuid/uuid.dart';

enum PaymentStatus {
  pending,
  paid,
  refunded,
  failed,
  cancelled,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  mobileMoney,
  cash,
}

enum PaymentType {
  full,
  deposit,
  balance,
}

class Payment {
  final String id;
  final String bookingId;
  final String customerId;
  final String professionalId;
  final double amount;
  final String currency;
  final PaymentType type;
  final int depositPercentage;
  final double? depositAmount;
  final double? totalAmount;
  final PaymentStatus status;
  final PaymentMethod? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final double? refundAmount;
  final String? notes;

  Payment({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.professionalId,
    required this.amount,
    this.currency = 'JMD',
    this.type = PaymentType.full,
    this.depositPercentage = 0,
    this.depositAmount,
    this.totalAmount,
    this.status = PaymentStatus.pending,
    this.paymentMethod,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.refundedAt,
    this.refundAmount,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? const Uuid().v4(),
      bookingId: map['booking_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      professionalId: map['professional_id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'JMD',
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentType.full,
      ),
      depositPercentage: map['deposit_percentage'] ?? 0,
      depositAmount: map['deposit_amount']?.toDouble(),
      totalAmount: map['total_amount']?.toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['payment_method'],
              orElse: () => PaymentMethod.creditCard,
            )
          : null,
      transactionId: map['transaction_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      refundedAt: map['refunded_at'] != null ? DateTime.parse(map['refunded_at']) : null,
      refundAmount: map['refund_amount']?.toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'professional_id': professionalId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'deposit_percentage': depositPercentage,
      'deposit_amount': depositAmount,
      'total_amount': totalAmount,
      'status': status.name,
      'payment_method': paymentMethod?.name,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'refunded_at': refundedAt?.toIso8601String(),
      'refund_amount': refundAmount,
      'notes': notes,
    };
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? professionalId,
    double? amount,
    String? currency,
    PaymentType? type,
    int? depositPercentage,
    double? depositAmount,
    double? totalAmount,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? refundedAt,
    double? refundAmount,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      professionalId: professionalId ?? this.professionalId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      depositAmount: depositAmount ?? this.depositAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      refundedAt: refundedAt ?? this.refundedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      notes: notes ?? this.notes,
    );
  }

  double get originalTotalAmount => totalAmount ?? amount;
  double get depositRequired => depositAmount ?? (originalTotalAmount * depositPercentage / 100);
  double get depositPaid => isDepositRequired && status == PaymentStatus.paid ? depositRequired : 0.0;
  double get remainingAmount => originalTotalAmount - amount;
  bool get isDepositRequired => depositPercentage > 0;
  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isRefunded => status == PaymentStatus.refunded;
}

class PaymentStatusHistory {
  final String id;
  final String paymentId;
  final PaymentStatus status;
  final DateTime changedAt;
  final String? changedBy;
  final String? notes;

  PaymentStatusHistory({
    required this.id,
    required this.paymentId,
    required this.status,
    required this.changedAt,
    this.changedBy,
    this.notes,
  });

  factory PaymentStatusHistory.fromMap(Map<String, dynamic> map) {
    return PaymentStatusHistory(
      id: map['id'] ?? const Uuid().v4(),
      paymentId: map['payment_id'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      changedAt: DateTime.parse(map['changed_at']),
      changedBy: map['changed_by'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'status': status.name,
      'changed_at': changedAt.toIso8601String(),
      'changed_by': changedBy,
      'notes': notes,
    };
  }
}

class DepositRequest {
  final String bookingId;
  final String professionalId;
  final int depositPercentage;
  final String reason;
  final DateTime requestedAt;

  DepositRequest({
    required this.bookingId,
    required this.professionalId,
    required this.depositPercentage,
    required this.reason,
    required this.requestedAt,
  });

  factory DepositRequest.fromMap(Map<String, dynamic> map) {
    return DepositRequest(
      bookingId: map['booking_id'] ?? '',
      professionalId: map['professional_id'] ?? '',
      depositPercentage: map['deposit_percentage'] ?? 0,
      reason: map['reason'] ?? '',
      requestedAt: DateTime.parse(map['requested_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'professional_id': professionalId,
      'deposit_percentage': depositPercentage,
      'reason': reason,
      'requested_at': requestedAt.toIso8601String(),
    };
  }
}
