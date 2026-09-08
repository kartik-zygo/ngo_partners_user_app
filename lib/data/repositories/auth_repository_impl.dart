import '../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteDataSource _remote;
  final DioClient _client;

  AuthRepositoryImpl(this._remote, this._client);

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) =>
      _remote.login(email: email, password: password);

  @override
  Future<UserEntity> register({
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
      _remote.register(
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

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Check if we have a stored token; if so restore session via GET /auth/me
    final token = await _client.getAccessToken();
    if (token == null) return null;
    try {
      return await _remote.getMe();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? organizationName,
  }) =>
      _remote.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarUrl: avatarUrl,
        organizationName: organizationName,
      );
}
