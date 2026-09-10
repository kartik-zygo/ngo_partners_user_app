import 'package:equatable/equatable.dart';

enum ServiceCategory { ngo, compliance, business }

/// Shown wherever a rate used to be. The backend sends the same constant, but
/// older builds of the API (and the offline mock data) may omit it entirely.
const String kPricingOnRequestLabel = 'Pricing on request';

class ServiceEntity extends Equatable {
  final String id;
  final String name;
  final String pricingLabel;

  /// Always true since the quotation cutover — services are quote-only and
  /// carry no client-visible rate.
  final bool quotationRequired;
  final String status;
  final ServiceCategory category;
  final String? description;
  final List<String> documents;
  final int durationDays;

  const ServiceEntity({
    required this.id,
    required this.name,
    this.pricingLabel = kPricingOnRequestLabel,
    this.quotationRequired = true,
    required this.status,
    required this.category,
    this.description,
    this.documents = const [],
    this.durationDays = 30,
  });

  factory ServiceEntity.fromJson(Map<String, dynamic> json) {
    final label = json['pricingLabel'] as String?;
    return ServiceEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pricingLabel:
          (label == null || label.isEmpty) ? kPricingOnRequestLabel : label,
      quotationRequired: json['quotationRequired'] as bool? ?? true,
      status: (json['isActive'] as bool? ?? true) ? 'approved' : 'pending',
      category: _parseCategory(json['category'] as String?),
      description: json['description'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
    );
  }

  static ServiceCategory _parseCategory(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ngo':
        return ServiceCategory.ngo;
      case 'compliance':
        return ServiceCategory.compliance;
      default:
        return ServiceCategory.business;
    }
  }

  String get categoryLabel {
    switch (category) {
      case ServiceCategory.ngo:
        return 'NGO';
      case ServiceCategory.compliance:
        return 'Compliance';
      case ServiceCategory.business:
        return 'Business';
    }
  }

  @override
  List<Object?> get props => [id, name, pricingLabel, quotationRequired];
}
