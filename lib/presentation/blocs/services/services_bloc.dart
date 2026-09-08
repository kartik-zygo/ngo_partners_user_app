import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/case_entity.dart';
import '../../../domain/usecases/app_usecases.dart';
import 'services_bloc_events_states.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final GetServicesUseCase _getServices;
  final GetCasesUseCase _getCases;
  final PurchaseServiceUseCase _purchaseService;
  final UploadDocumentUseCase _uploadDocument;

  ServicesBloc({
    required GetServicesUseCase getServices,
    required GetCasesUseCase getCases,
    required PurchaseServiceUseCase purchaseService,
    required UploadDocumentUseCase uploadDocument,
  })  : _getServices = getServices,
        _getCases = getCases,
        _purchaseService = purchaseService,
        _uploadDocument = uploadDocument,
        super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadCases>(_onLoadCases);
    on<PurchaseService>(_onPurchaseService);
    on<UploadDocument>(_onUploadDocument);
    on<FilterByCategory>(_onFilter);
  }

  Future<void> _onLoadServices(LoadServices event, Emitter<ServicesState> emit) async {
    final previousCases = state is ServicesLoaded
      ? (state as ServicesLoaded).cases
      : const <CaseEntity>[];
    emit(ServicesLoading());
    try {
      final services = await _getServices();
      emit(ServicesLoaded(
        services: services,
        cases: previousCases,
      ));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadCases(LoadCases event, Emitter<ServicesState> emit) async {
    final current = state;
    try {
      final cases = await _getCases(event.userId);
      if (current is ServicesLoaded) {
        emit(current.copyWith(cases: cases));
        return;
      }

      final services = await _getServices();
      emit(ServicesLoaded(services: services, cases: cases));
    } catch (e) {
      if (current is! ServicesLoaded) {
        emit(ServicesError(e.toString()));
      }
    }
  }

  Future<void> _onPurchaseService(PurchaseService event, Emitter<ServicesState> emit) async {
    final current = state;
    if (current is! ServicesLoaded) return;
    emit(current.copyWith(isPurchasing: true));
    try {
      final newCase = await _purchaseService(
        userId: event.userId,
        service: event.service,
      );
      emit(current.copyWith(
        cases: [...current.cases, newCase],
        isPurchasing: false,
        purchaseComplete: true,
        lastPurchasedService: () => event.service,
      ));
    } catch (e) {
      emit(current.copyWith(isPurchasing: false));
    }
  }

  Future<void> _onUploadDocument(UploadDocument event, Emitter<ServicesState> emit) async {
    final current = state;
    if (current is! ServicesLoaded) return;
    try {
      await _uploadDocument(
        caseId: event.caseId,
        docName: event.docName,
        filePath: event.filePath,
      );
      // Optimistic update: append the doc name to the existing case in state.
      // GET /cases/{id} does not return documents, so we never replace from server.
      final updatedCases = current.cases.map((c) {
        if (c.id != event.caseId) return c;
        return c.copyWith(documents: [...c.documents, event.docName]);
      }).toList();
      emit(current.copyWith(cases: updatedCases));
    } catch (_) {}
  }

  void _onFilter(FilterByCategory event, Emitter<ServicesState> emit) {
    final current = state;
    if (current is ServicesLoaded) {
      emit(current.copyWith(activeFilter: () => event.category));
    }
  }
}
