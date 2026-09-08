import 'package:equatable/equatable.dart';

enum TicketStatus { open, inProgress, waitingForUser, resolved, closed }

enum TicketPriority { low, medium, high, urgent }

class TicketUpdate extends Equatable {
  final String id;
  final String message;
  final String authorRole;
  final DateTime? createdAt;

  const TicketUpdate({
    required this.id,
    required this.message,
    this.authorRole = 'user',
    this.createdAt,
  });

  factory TicketUpdate.fromJson(Map<String, dynamic> json) {
    return TicketUpdate(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, message];
}

class TicketEntity extends Equatable {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String? caseId;
  final List<TicketUpdate> updates;
  final DateTime? createdAt;

  const TicketEntity({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    this.caseId,
    this.updates = const [],
    this.createdAt,
  });

  factory TicketEntity.fromJson(Map<String, dynamic> json) {
    return TicketEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      caseId: json['caseId'] as String?,
      updates: (json['updates'] as List<dynamic>?)
              ?.map((e) => TicketUpdate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static TicketStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'open':
        return TicketStatus.open;
      case 'inProgress':
        return TicketStatus.inProgress;
      case 'waitingForUser':
        return TicketStatus.waitingForUser;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  static TicketPriority _parsePriority(String? raw) {
    switch (raw) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.medium;
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.waitingForUser:
        return 'Waiting for User';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  @override
  List<Object?> get props => [id, userId, subject, status];
}
