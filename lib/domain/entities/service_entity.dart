import 'package:equatable/equatable.dart';

enum ServiceCategory { ngo, compliance, business }

class ServiceEntity extends Equatable {
  final String id;
  final String name;
  final int price;
  final String pricingLabel;
  final bool purchasable;
  final String status;
  final ServiceCategory category;
  final String? description;
  final List<String> documents;
  final int durationDays;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.pricingLabel,
    required this.purchasable,
    required this.status,
    required this.category,
    this.description,
    this.documents = const [],
    this.durationDays = 30,
  });

  factory ServiceEntity.fromJson(Map<String, dynamic> json) {
    return ServiceEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['basePrice'] as num?)?.toInt() ?? 0,
      pricingLabel: json['pricingLabel'] as String? ?? '',
      purchasable: json['purchasable'] as bool? ?? (json['basePrice'] != null),
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
  List<Object?> get props => [id, name, price, pricingLabel, purchasable];
}
