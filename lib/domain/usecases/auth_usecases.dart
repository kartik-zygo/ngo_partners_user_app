import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<UserEntity> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}

class RegisterUseCase {
  final AuthRepository _repository;
  RegisterUseCase(this._repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    bool isOrganizationAccount = false,
    String? organizationName,
    String? organizationType,
    String? organizationRegNumber,
    String? organizationWebsite,
    String? organizationDescription,
  }) =>
      _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        isOrganizationAccount: isOrganizationAccount,
        organizationName: organizationName,
        organizationType: organizationType,
        organizationRegNumber: organizationRegNumber,
        organizationWebsite: organizationWebsite,
        organizationDescription: organizationDescription,
      );
}

class LogoutUseCase {
  final AuthRepository _repository;
  LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}

class DeleteAccountUseCase {
  final AuthRepository _repository;
  DeleteAccountUseCase(this._repository);

  Future<String> call({required String password, String? reason}) =>
      _repository.deleteAccount(password: password, reason: reason);
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> call() => _repository.getCurrentUser();
}

class UpdateProfileUseCase {
  final AuthRepository _repository;
  UpdateProfileUseCase(this._repository);

  Future<UserEntity> call({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? organizationName,
  }) =>
      _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarUrl: avatarUrl,
        organizationName: organizationName,
      );
}
