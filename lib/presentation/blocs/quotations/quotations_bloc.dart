import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/quotation_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'quotations_bloc_events_states.dart';

export 'quotations_bloc_events_states.dart';

class QuotationsBloc extends Bloc<QuotationsEvent, QuotationsState> {
  final CreateQuotationUseCase _createQuotation;
  final GetQuotationsUseCase _getQuotations;

  QuotationsBloc({
    required CreateQuotationUseCase createQuotation,
    required GetQuotationsUseCase getQuotations,
  })  : _createQuotation = createQuotation,
        _getQuotations = getQuotations,
        super(const QuotationsState()) {
    on<LoadQuotations>(_onLoad);
    on<FilterQuotationsByStatus>(_onFilter);
    on<SubmitQuotation>(_onSubmit);
    on<ResetQuotationSubmission>(_onReset);
  }

  Future<void> _onLoad(
    LoadQuotations event,
    Emitter<QuotationsState> emit,
  ) async {
    final status = event.status ?? state.activeStatus;
    emit(state.copyWith(
      isLoading: true,
      listError: () => null,
      activeStatus: () => status,
    ));
    try {
      final quotations = await _getQuotations(status: status);
      emit(state.copyWith(
        isLoading: false,
        quotations: quotations,
        activeStatus: () => status,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        listError: () => _clean(e),
      ));
    }
  }

  Future<void> _onFilter(
    FilterQuotationsByStatus event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(activeStatus: () => event.status));
    add(LoadQuotations(status: event.status));
  }

  Future<void> _onSubmit(
    SubmitQuotation event,
    Emitter<QuotationsState> emit,
  ) async {
    emit(state.copyWith(submission: const SubmissionInProgress()));
    try {
      final quotation = await _createQuotation(
        serviceId: event.serviceId,
        name: event.name,
        email: event.email,
        phone: event.phone,
        organizationName: event.organizationName,
        message: event.message,
      );
      emit(state.copyWith(
        submission: SubmissionSuccess(quotation),
        // Put it at the top of the tracker straight away; a refresh will
        // reconcile with the server ordering.
        quotations: [quotation, ...state.quotations],
      ));
    } on QuotationAlreadyOpenException catch (e) {
      emit(state.copyWith(
        submission: SubmissionAlreadyOpen(e.message, reference: e.reference),
      ));
    } on QuotationValidationException catch (e) {
      emit(state.copyWith(
        submission: SubmissionInvalid(e.message, fieldErrors: e.fieldErrors),
      ));
    } on QuotationServiceUnavailableException catch (e) {
      emit(state.copyWith(submission: SubmissionServiceGone(e.message)));
    } catch (e) {
      emit(state.copyWith(submission: SubmissionFailure(_clean(e))));
    }
  }

  void _onReset(
    ResetQuotationSubmission event,
    Emitter<QuotationsState> emit,
  ) {
    emit(state.copyWith(submission: const SubmissionIdle()));
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}
