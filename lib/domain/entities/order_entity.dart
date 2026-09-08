import 'package:equatable/equatable.dart';

import 'payment_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String status;
  final String currency;
  final double amount;
  final String serviceName;
  final String? serviceId;
  final String? fulfillmentStatus;
  final String? notes;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? latestPaymentRequestId;
  final String? latestPaymentRequestStatus;
  final PaymentInstructions? paymentInstructions;
  final List<PaymentRequestEntity> paymentRequests;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const OrderEntity({
    required this.id,
    required this.status,
    this.currency = 'INR',
    required this.amount,
    required this.serviceName,
    this.serviceId,
    this.fulfillmentStatus,
    this.notes,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.latestPaymentRequestId,
    this.latestPaymentRequestStatus,
    this.paymentInstructions,
    this.paymentRequests = const [],
    this.paidAt,
    this.createdAt,
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final instructions = json['paymentInstructions'];
    final requests = json['paymentRequests'];

    return OrderEntity(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? OrderStatus.pendingPayment,
      currency: json['currency'] as String? ?? 'INR',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      serviceName: json['serviceName'] as String? ?? '',
      serviceId: json['serviceId'] as String?,
      fulfillmentStatus: json['fulfillmentStatus'] as String?,
      notes: json['notes'] as String?,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
      latestPaymentRequestId: json['latestPaymentRequestId'] as String?,
      latestPaymentRequestStatus: json['latestPaymentRequestStatus'] as String?,
      paymentInstructions: instructions is Map<String, dynamic>
          ? PaymentInstructions.fromJson(instructions)
          : null,
      paymentRequests: requests is List
          ? requests
              .whereType<Map<String, dynamic>>()
              .map(PaymentRequestEntity.fromJson)
              .toList()
          : const [],
      paidAt: _date(json['paidAt']),
      createdAt: _date(json['createdAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  OrderEntity copyWith({
    String? status,
    String? fulfillmentStatus,
    String? latestPaymentRequestId,
    String? latestPaymentRequestStatus,
    PaymentInstructions? paymentInstructions,
    List<PaymentRequestEntity>? paymentRequests,
    DateTime? paidAt,
  }) {
    return OrderEntity(
      id: id,
      status: status ?? this.status,
      currency: currency,
      amount: amount,
      serviceName: serviceName,
      serviceId: serviceId,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      notes: notes,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      latestPaymentRequestId:
          latestPaymentRequestId ?? this.latestPaymentRequestId,
      latestPaymentRequestStatus:
          latestPaymentRequestStatus ?? this.latestPaymentRequestStatus,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      paymentRequests: paymentRequests ?? this.paymentRequests,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt,
    );
  }

  bool get isPendingPayment => status == OrderStatus.pendingPayment;
  bool get isAwaitingApproval => status == OrderStatus.paymentSubmitted;
  bool get isPaid => status == OrderStatus.paid;
  bool get isRejected => status == OrderStatus.rejected;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isExpired => status == OrderStatus.expired;

  bool get canSubmitPayment => isPendingPayment || isRejected;
  bool get canCancel => isPendingPayment || isRejected;

  PaymentRequestEntity? get latestPaymentRequest {
    if (paymentRequests.isEmpty) return null;
    if (latestPaymentRequestId != null) {
      for (final request in paymentRequests) {
        if (request.id == latestPaymentRequestId) return request;
      }
    }
    return paymentRequests.first;
  }

  String? get rejectionReason {
    if (!isRejected) return null;
    for (final request in paymentRequests) {
      if (request.isRejected && (request.reviewNotes?.isNotEmpty ?? false)) {
        return request.reviewNotes;
      }
    }
    return null;
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.pendingPayment:
        return 'Payment Pending';
      case OrderStatus.paymentSubmitted:
        return 'Awaiting Verification';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.expired:
        return 'Expired';
      default:
        return status;
    }
  }

  String get fulfillmentLabel {
    switch (fulfillmentStatus) {
      case 'processing':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'refund_initiated':
        return 'Refund Pending';
      case 'refunded':
        return 'Refunded';
      default:
        return isPaid ? 'Queued' : '';
    }
  }

  @override
  List<Object?> get props => [id, status, amount, serviceName, latestPaymentRequestStatus];
}

class OrderStatus {
  OrderStatus._();

  static const String pendingPayment = 'pending_payment';
  static const String paymentSubmitted = 'payment_submitted';
  static const String paid = 'paid';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';
}
