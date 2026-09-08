import 'package:equatable/equatable.dart';

enum CollabStatus { pending, approved, rejected }

enum CollabType { fundingPartner, resourceSharing, csrPartner, technical }

class CollaborationEntity extends Equatable {
  final String id;
  final String ngoName;
  final CollabType type;
  final CollabStatus status;
  final String about;
  final String? contactEmail;
  final DateTime? createdAt;

  const CollaborationEntity({
    required this.id,
    required this.ngoName,
    required this.type,
    required this.status,
    required this.about,
    this.contactEmail,
    this.createdAt,
  });

  factory CollaborationEntity.fromJson(Map<String, dynamic> json) {
    return CollaborationEntity(
      id: json['id'] as String? ?? '',
      ngoName: json['ngoName'] as String? ??
          (json['user'] as Map<String, dynamic>?)?['email'] as String? ??
          '',
      type: _parseType(json['type'] as String?),
      status: _parseStatus(json['status'] as String?),
      about: json['proposal'] as String? ?? json['about'] as String? ?? '',
      contactEmail: json['contactEmail'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static CollabType _parseType(String? raw) {
    switch (raw) {
      case 'fundingPartner':
        return CollabType.fundingPartner;
      case 'resourceSharing':
        return CollabType.resourceSharing;
      case 'csrPartner':
        return CollabType.csrPartner;
      case 'technical':
        return CollabType.technical;
      default:
        return CollabType.fundingPartner;
    }
  }

  static CollabStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'approved':
        return CollabStatus.approved;
      case 'rejected':
        return CollabStatus.rejected;
      default:
        return CollabStatus.pending;
    }
  }

  String get typeLabel {
    switch (type) {
      case CollabType.fundingPartner:
        return 'Funding Partner';
      case CollabType.resourceSharing:
        return 'Resource Sharing';
      case CollabType.csrPartner:
        return 'CSR Partner';
      case CollabType.technical:
        return 'Technical Partner';
    }
  }

  String get typeName {
    switch (type) {
      case CollabType.fundingPartner:
        return 'fundingPartner';
      case CollabType.resourceSharing:
        return 'resourceSharing';
      case CollabType.csrPartner:
        return 'csrPartner';
      case CollabType.technical:
        return 'technical';
    }
  }

  @override
  List<Object?> get props => [id, ngoName, type, status];
}
