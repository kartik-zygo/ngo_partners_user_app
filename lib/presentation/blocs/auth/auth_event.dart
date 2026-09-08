import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool isOrganizationAccount;
  final String? organizationName;
  final String? organizationType;
  final String? organizationRegNumber;
  final String? organizationWebsite;
  final String? organizationDescription;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.isOrganizationAccount = false,
    this.organizationName,
    this.organizationType,
    this.organizationRegNumber,
    this.organizationWebsite,
    this.organizationDescription,
  });

  @override
  List<Object?> get props => [email, firstName, lastName];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthProfileUpdated extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final String? organizationName;

  const AuthProfileUpdated({
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.organizationName,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone];
}
