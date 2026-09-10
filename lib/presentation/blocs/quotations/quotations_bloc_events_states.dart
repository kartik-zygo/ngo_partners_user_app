import 'package:equatable/equatable.dart';
import '../../../domain/entities/quotation_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class QuotationsEvent extends Equatable {
  const QuotationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadQuotations extends QuotationsEvent {
  final String? status;
  const LoadQuotations({this.status});
  @override
  List<Object?> get props => [status];
}

class FilterQuotationsByStatus extends QuotationsEvent {
  final String? status;
  const FilterQuotationsByStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class SubmitQuotation extends QuotationsEvent {
  final String serviceId;
  final String name;
  final String email;
  final String phone;
  final String? organizationName;
  final String? message;

  const SubmitQuotation({
    required this.serviceId,
    required this.name,
    required this.email,
    required this.phone,
    this.organizationName,
    this.message,
  });

  @override
  List<Object?> get props =>
      [serviceId, name, email, phone, organizationName, message];
}

/// Clears the outcome of the last submit so the form can be shown again.
class ResetQuotationSubmission extends QuotationsEvent {
  const ResetQuotationSubmission();
}

// ── Submission outcome ────────────────────────────────────────────────────────

/// Everything the form screen needs to react to a submit. Kept separate from
/// the list state so a failed submit never blanks the tracker.
abstract class QuotationSubmission extends Equatable {
  const QuotationSubmission();
  @override
  List<Object?> get props => [];
}

class SubmissionIdle extends QuotationSubmission {
  const SubmissionIdle();
}

class SubmissionInProgress extends QuotationSubmission {
  const SubmissionInProgress();
}

class SubmissionSuccess extends QuotationSubmission {
  final QuotationEntity quotation;
  const SubmissionSuccess(this.quotation);
  @override
  List<Object?> get props => [quotation];
}

/// `409` — not a failure to show as an error. The client already has an open
/// request for this service.
class SubmissionAlreadyOpen extends QuotationSubmission {
  final String message;
  final String? reference;
  const SubmissionAlreadyOpen(this.message, {this.reference});
  @override
  List<Object?> get props => [message, reference];
}

class SubmissionInvalid extends QuotationSubmission {
  final String message;
  final Map<String, String> fieldErrors;
  const SubmissionInvalid(this.message, {this.fieldErrors = const {}});
  @override
  List<Object?> get props => [message, fieldErrors];
}

/// `404` — the service was deactivated; the catalogue needs a refresh.
class SubmissionServiceGone extends QuotationSubmission {
  final String message;
  const SubmissionServiceGone(this.message);
  @override
  List<Object?> get props => [message];
}

class SubmissionFailure extends QuotationSubmission {
  final String message;
  const SubmissionFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── State ─────────────────────────────────────────────────────────────────────
class QuotationsState extends Equatable {
  final bool isLoading;
  final List<QuotationEntity> quotations;
  final String? activeStatus;
  final String? listError;
  final QuotationSubmission submission;

  const QuotationsState({
    this.isLoading = false,
    this.quotations = const [],
    this.activeStatus,
    this.listError,
    this.submission = const SubmissionIdle(),
  });

  bool get hasLoaded => !isLoading && listError == null;

  QuotationsState copyWith({
    bool? isLoading,
    List<QuotationEntity>? quotations,
    String? Function()? activeStatus,
    String? Function()? listError,
    QuotationSubmission? submission,
  }) {
    return QuotationsState(
      isLoading: isLoading ?? this.isLoading,
      quotations: quotations ?? this.quotations,
      activeStatus: activeStatus != null ? activeStatus() : this.activeStatus,
      listError: listError != null ? listError() : this.listError,
      submission: submission ?? this.submission,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, quotations, activeStatus, listError, submission];
}
