import 'package:equatable/equatable.dart';

enum CaseStatus {
  submitted,
  filingInProgress,
  underReview,
  approved,
  rejected,
  resubmitRequired,
}

class CaseEntity extends Equatable {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final CaseStatus status;
  final List<String> documents;
  final String? resubmitNote;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? assignedFilingId;

  const CaseEntity({
    required this.id,
    required this.userId,
    this.serviceId = '',
    required this.serviceName,
    required this.status,
    this.documents = const [],
    this.resubmitNote,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.assignedFilingId,
  });

  factory CaseEntity.fromJson(Map<String, dynamic> json) {
    return CaseEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      serviceName: (json['service'] as Map<String, dynamic>?)?['name'] as String? ??
          json['serviceName'] as String? ??
          json['serviceId'] as String? ??
          'Service',
      status: _parseStatus(json['status'] as String?),
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => (e is Map
                      ? e['document_name'] ??
                          e['documentName'] ??
                          e['file_url'] ??
                          e['fileUrl']
                      : e)
                  .toString())
              .toList() ??
          [],
      resubmitNote: json['resubmitNote'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static CaseStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'submitted':
        return CaseStatus.submitted;
      case 'filingInProgress':
        return CaseStatus.filingInProgress;
      case 'underReview':
        return CaseStatus.underReview;
      case 'approved':
        return CaseStatus.approved;
      case 'rejected':
        return CaseStatus.rejected;
      case 'resubmitRequired':
        return CaseStatus.resubmitRequired;
      default:
        return CaseStatus.submitted;
    }
  }

  String get statusLabel {
    switch (status) {
      case CaseStatus.submitted:
        return 'Submitted';
      case CaseStatus.filingInProgress:
        return 'Filing in Progress';
      case CaseStatus.underReview:
        return 'Under Review';
      case CaseStatus.approved:
        return 'Approved';
      case CaseStatus.rejected:
        return 'Rejected';
      case CaseStatus.resubmitRequired:
        return 'Resubmit Required';
    }
  }

  CaseEntity copyWith({
    CaseStatus? status,
    List<String>? documents,
    String? resubmitNote,
  }) {
    return CaseEntity(
      id: id,
      userId: userId,
      serviceId: serviceId,
      serviceName: serviceName,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      resubmitNote: resubmitNote ?? this.resubmitNote,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedFilingId: assignedFilingId,
    );
  }

  @override
  List<Object?> get props => [id, userId, serviceName, status, documents];
}
