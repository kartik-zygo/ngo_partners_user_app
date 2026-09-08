import 'package:equatable/equatable.dart';

enum UserRole { user, ngo }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final List<String> purchasedServices;
  final String? ngoName;
  final String? ngoType;
  final String? firstName;
  final String? lastName;
  final bool isOrganizationAccount;
  final String? organizationName;
  final String? organizationType;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.purchasedServices = const [],
    this.ngoName,
    this.ngoType,
    this.firstName,
    this.lastName,
    this.isOrganizationAccount = false,
    this.organizationName,
    this.organizationType,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final profile = json['profile'] as Map<String, dynamic>? ?? {};

    final firstName = profile['firstName'] as String? ?? '';
    final lastName = profile['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    final roles = (user['roles'] as List<dynamic>?)?.map((e) => e.toString()) ?? [];
    final isNgo = roles.contains('NGO');

    return UserEntity(
      id: user['id'] as String? ?? '',
      name: fullName.isNotEmpty ? fullName : (user['email'] as String? ?? ''),
      email: user['email'] as String? ?? '',
      role: isNgo ? UserRole.ngo : UserRole.user,
      phone: profile['phone'] as String?,
      avatarUrl: profile['avatarUrl'] as String?,
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
      isOrganizationAccount: profile['isOrganizationAccount'] as bool? ?? false,
      organizationName: profile['organizationName'] as String?,
      organizationType: profile['organizationType'] as String?,
      ngoName: profile['organizationName'] as String?,
      ngoType: profile['organizationType'] as String?,
    );
  }

  UserEntity copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? organizationName,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      purchasedServices: purchasedServices,
      ngoName: organizationName ?? ngoName,
      ngoType: ngoType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isOrganizationAccount: isOrganizationAccount,
      organizationName: organizationName ?? this.organizationName,
      organizationType: organizationType,
    );
  }

  @override
  List<Object?> get props => [id, email, role];
}
