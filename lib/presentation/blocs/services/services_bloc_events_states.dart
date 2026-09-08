import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/case_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesEvent {}

class LoadCases extends ServicesEvent {
  final String userId;
  const LoadCases(this.userId);
  @override
  List<Object?> get props => [userId];
}

class PurchaseService extends ServicesEvent {
  final String userId;
  final ServiceEntity service;
  const PurchaseService({required this.userId, required this.service});
  @override
  List<Object?> get props => [userId, service];
}

class UploadDocument extends ServicesEvent {
  final String caseId;
  final String docName;
  final String filePath;
  const UploadDocument({
    required this.caseId,
    required this.docName,
    required this.filePath,
  });
  @override
  List<Object?> get props => [caseId, docName, filePath];
}

class FilterByCategory extends ServicesEvent {
  final ServiceCategory? category;
  const FilterByCategory(this.category);
  @override
  List<Object?> get props => [category];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ServiceEntity> services;
  final List<CaseEntity> cases;
  final ServiceCategory? activeFilter;
  final bool isPurchasing;
  final bool purchaseComplete;
  final ServiceEntity? lastPurchasedService;

  const ServicesLoaded({
    required this.services,
    required this.cases,
    this.activeFilter,
    this.isPurchasing = false,
    this.purchaseComplete = false,
    this.lastPurchasedService,
  });

  List<ServiceEntity> get filteredServices => activeFilter == null
      ? services
      : services.where((s) => s.category == activeFilter).toList();

  ServicesLoaded copyWith({
    List<ServiceEntity>? services,
    List<CaseEntity>? cases,
    ServiceCategory? Function()? activeFilter,
    bool? isPurchasing,
    bool? purchaseComplete,
    ServiceEntity? Function()? lastPurchasedService,
  }) {
    return ServicesLoaded(
      services: services ?? this.services,
      cases: cases ?? this.cases,
      activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseComplete: purchaseComplete ?? this.purchaseComplete,
      lastPurchasedService: lastPurchasedService != null
          ? lastPurchasedService()
          : this.lastPurchasedService,
    );
  }

  @override
  List<Object?> get props =>
      [services, cases, activeFilter, isPurchasing, purchaseComplete];
}

class ServicesError extends ServicesState {
  final String message;
  const ServicesError(this.message);
  @override
  List<Object?> get props => [message];
}
