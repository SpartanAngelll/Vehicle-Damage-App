import 'package:uuid/uuid.dart';
import 'payment_models.dart';

enum InvoiceStatus {
  draft,
  sent,
  depositPaid,
  paid,
  overdue,
  cancelled,
  refunded,
}


class Invoice {
  final String id;
  final String bookingId;
  final String customerId;
  final String professionalId;
  final double totalAmount;
  final String currency;
  final int depositPercentage;
  final double depositAmount;
  final double balanceAmount;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? dueDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Invoice({
    String? id,
    required this.bookingId,
    required this.customerId,
    required this.professionalId,
    required this.totalAmount,
    this.currency = 'JMD',
    required this.depositPercentage,
    required this.depositAmount,
    required this.balanceAmount,
    this.status = InvoiceStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sentAt,
    this.dueDate,
    this.notes,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      customerId: map['customer_id'] as String,
      professionalId: map['professional_id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      currency: map['currency'] as String,
      depositPercentage: map['deposit_percentage'] as int,
      depositAmount: (map['deposit_amount'] as num).toDouble(),
      balanceAmount: (map['balance_amount'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      sentAt: map['sent_at'] != null ? DateTime.parse(map['sent_at'] as String) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'professional_id': professionalId,
      'total_amount': totalAmount,
      'currency': currency,
      'deposit_percentage': depositPercentage,
      'deposit_amount': depositAmount,
      'balance_amount': balanceAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  Invoice copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? professionalId,
    double? totalAmount,
    String? currency,
    int? depositPercentage,
    double? depositAmount,
    double? balanceAmount,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    DateTime? dueDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Invoice(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      professionalId: professionalId ?? this.professionalId,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      depositAmount: depositAmount ?? this.depositAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isDepositRequired => depositPercentage > 0;
  bool get isDepositPaid => status == InvoiceStatus.depositPaid || status == InvoiceStatus.paid;
  bool get isFullyPaid => status == InvoiceStatus.paid;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isFullyPaid;
}

class PaymentRecord {
  final String id;
  final String invoiceId;
  final String bookingId;
  final PaymentType type;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod? paymentMethod;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final String? notes;
  final Map<String, dynamic>? metadata;

  PaymentRecord({
    String? id,
    required this.invoiceId,
    required this.bookingId,
    required this.type,
    required this.amount,
    this.currency = 'JMD',
    this.status = PaymentStatus.pending,
    this.paymentMethod,
    this.transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.processedAt,
    this.notes,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      bookingId: map['booking_id'] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => PaymentType.full,
      ),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String),
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == (map['payment_method'] as String),
              orElse: () => PaymentMethod.creditCard,
            )
          : null,
      transactionId: map['transaction_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      processedAt: map['processed_at'] != null ? DateTime.parse(map['processed_at'] as String) : null,
      notes: map['notes'] as String?,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'booking_id': bookingId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'payment_method': paymentMethod?.name,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  PaymentRecord copyWith({
    String? id,
    String? invoiceId,
    String? bookingId,
    PaymentType? type,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? processedAt,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isProcessed => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isRefunded => status == PaymentStatus.refunded;
}
