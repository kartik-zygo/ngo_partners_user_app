import 'package:equatable/equatable.dart';

/// Client-facing status of a quotation request. These mirror the sales lead
/// pipeline automatically — the client never sees the lead's own vocabulary.
class QuotationStatus {
  static const String submitted = 'submitted';
  static const String assigned = 'assigned';
  static const String contacted = 'contacted';
  static const String qualified = 'qualified';
  static const String quoted = 'quoted';
  static const String closedWon = 'closed_won';
  static const String closedLost = 'closed_lost';

  /// Ordered pipeline used to draw the tracker progress. Terminal statuses are
  /// deliberately excluded — they are rendered as their own end state.
  static const List<String> pipeline = [
    submitted,
    assigned,
    contacted,
    qualified,
    quoted,
  ];

  static const List<String> filterable = [
    submitted,
    assigned,
    contacted,
    qualified,
    quoted,
    closedWon,
    closedLost,
  ];

  /// Short chip text. The server's [QuotationEntity.statusLabel] is the
  /// sentence written for the client and is always printed as-is; this is only
  /// for tight spaces such as filter chips.
  static String shortLabel(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case assigned:
        return 'Assigned';
      case contacted:
        return 'Contacted';
      case qualified:
        return 'In discussion';
      case quoted:
        return 'Quoted';
      case closedWon:
        return 'Confirmed';
      case closedLost:
        return 'Closed';
      default:
        return status;
    }
  }
}

class QuotationEntity extends Equatable {
  final String id;
  final String reference;
  final String? serviceId;
  final String serviceName;
  final String contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? organizationName;

  /// The client's own note, echoed back. Never show this as the confirmation.
  final String? message;
  final String status;

  /// Server-authored sentence for the client — print it verbatim.
  final String statusLabel;
  final String? salesRepName;

  /// Only present on the create response.
  final String? confirmationMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  const QuotationEntity({
    required this.id,
    required this.reference,
    this.serviceId,
    this.serviceName = '',
    this.contactName = '',
    this.contactEmail,
    this.contactPhone,
    this.organizationName,
    this.message,
    this.status = QuotationStatus.submitted,
    this.statusLabel = '',
    this.salesRepName,
    this.confirmationMessage,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  factory QuotationEntity.fromJson(Map<String, dynamic> json) {
    return QuotationEntity(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      serviceId: json['serviceId'] as String?,
      serviceName: json['serviceName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      organizationName: json['organizationName'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? QuotationStatus.submitted,
      statusLabel: json['statusLabel'] as String? ?? '',
      salesRepName: json['salesRepName'] as String?,
      confirmationMessage: json['confirmationMessage'] as String?,
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      closedAt: _date(json['closedAt']),
    );
  }

  static DateTime? _date(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool get isWon => status == QuotationStatus.closedWon;
  bool get isLost => status == QuotationStatus.closedLost;
  bool get isClosed => isWon || isLost;

  /// 0-based position in [QuotationStatus.pipeline]; -1 once closed.
  int get pipelineIndex => QuotationStatus.pipeline.indexOf(status);

  @override
  List<Object?> get props => [id, reference, status, statusLabel, salesRepName];
}

/// `409 CONFLICT` on submit — the client already has an open request for this
/// service. Not an error screen: show the reference and reassure them.
class QuotationAlreadyOpenException implements Exception {
  final String message;
  final String? reference;

  const QuotationAlreadyOpenException(this.message, {this.reference});

  @override
  String toString() => message;
}

/// `422 VALIDATION_ERROR` — [fieldErrors] is keyed by request field name.
class QuotationValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const QuotationValidationException(
    this.message, {
    this.fieldErrors = const {},
  });

  @override
  String toString() => message;
}

/// `404 NOT_FOUND` — the service was deactivated; the catalogue is stale.
class QuotationServiceUnavailableException implements Exception {
  final String message;

  const QuotationServiceUnavailableException(this.message);

  @override
  String toString() => message;
}
