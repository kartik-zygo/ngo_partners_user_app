import 'package:equatable/equatable.dart';

enum PaymentMethod {
  upi,
  bankTransfer,
  neft,
  imps,
  cash,
  cheque,
  other;

  String get apiValue {
    switch (this) {
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.neft:
        return 'neft';
      case PaymentMethod.imps:
        return 'imps';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.neft:
        return 'NEFT';
      case PaymentMethod.imps:
        return 'IMPS';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get referenceHint {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI transaction / UTR number';
      case PaymentMethod.bankTransfer:
      case PaymentMethod.neft:
      case PaymentMethod.imps:
        return 'UTR / reference number';
      case PaymentMethod.cash:
        return 'Receipt number';
      case PaymentMethod.cheque:
        return 'Cheque number';
      case PaymentMethod.other:
        return 'Reference number';
    }
  }

  static PaymentMethod fromApi(String? value) {
    switch (value) {
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'neft':
        return PaymentMethod.neft;
      case 'imps':
        return PaymentMethod.imps;
      case 'cash':
        return PaymentMethod.cash;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'other':
        return PaymentMethod.other;
      case 'upi':
      default:
        return PaymentMethod.upi;
    }
  }
}

enum PaymentRequestStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Under Review';
      case PaymentRequestStatus.approved:
        return 'Approved';
      case PaymentRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static PaymentRequestStatus fromApi(String? value) {
    switch (value) {
      case 'approved':
        return PaymentRequestStatus.approved;
      case 'rejected':
        return PaymentRequestStatus.rejected;
      case 'pending':
      default:
        return PaymentRequestStatus.pending;
    }
  }
}

class PaymentRequestEntity extends Equatable {
  final String id;
  final String orderId;
  final PaymentMethod paymentMethod;
  final String referenceNumber;
  final double amountClaimed;
  final double? orderAmount;
  final bool amountMatchesOrder;
  final DateTime? paidAt;
  final String? payerName;
  final String? payerNote;
  final String? proofUrl;
  final PaymentRequestStatus status;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final String? orderStatus;

  const PaymentRequestEntity({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.amountClaimed,
    this.orderAmount,
    this.amountMatchesOrder = true,
    this.paidAt,
    this.payerName,
    this.payerNote,
    this.proofUrl,
    required this.status,
    this.reviewNotes,
    this.reviewedAt,
    this.createdAt,
    this.orderStatus,
  });

  factory PaymentRequestEntity.fromJson(Map<String, dynamic> json) {
    return PaymentRequestEntity(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String?),
      referenceNumber: json['referenceNumber'] as String? ?? '',
      amountClaimed: (json['amountClaimed'] as num?)?.toDouble() ?? 0.0,
      orderAmount: (json['orderAmount'] as num?)?.toDouble(),
      amountMatchesOrder: json['amountMatchesOrder'] as bool? ?? true,
      paidAt: _date(json['paidAt']),
      payerName: json['payerName'] as String?,
      payerNote: json['payerNote'] as String?,
      proofUrl: json['proofUrl'] as String?,
      status: PaymentRequestStatus.fromApi(json['status'] as String?),
      reviewNotes: json['reviewNotes'] as String?,
      reviewedAt: _date(json['reviewedAt']),
      createdAt: _date(json['createdAt']),
      orderStatus: json['orderStatus'] as String?,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  bool get isPending => status == PaymentRequestStatus.pending;
  bool get isApproved => status == PaymentRequestStatus.approved;
  bool get isRejected => status == PaymentRequestStatus.rejected;

  @override
  List<Object?> get props => [id, orderId, referenceNumber, status, amountClaimed];
}
