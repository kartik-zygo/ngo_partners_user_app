import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});

  Future<UserEntity> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    bool isOrganizationAccount,
    String? organizationName,
    String? organizationType,
    String? organizationRegNumber,
    String? organizationWebsite,
    String? organizationDescription,
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? organizationName,
  });
}
