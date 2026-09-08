import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;
  final UpdateProfileUseCase _updateProfile;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
    required UpdateProfileUseCase updateProfile,
  })  : _login = login,
        _register = register,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _updateProfile = updateProfile,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdated>(_onProfileUpdate);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    // Try to restore session from stored token via GET /auth/me
    final user = await _getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _login(email: event.email, password: event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        isOrganizationAccount: event.isOrganizationAccount,
        organizationName: event.organizationName,
        organizationType: event.organizationType,
        organizationRegNumber: event.organizationRegNumber,
        organizationWebsite: event.organizationWebsite,
        organizationDescription: event.organizationDescription,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onProfileUpdate(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final updated = await _updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        avatarUrl: event.avatarUrl,
        organizationName: event.organizationName,
      );
      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      emit(current); // Restore previous state so UI stays usable
    }
  }
}
