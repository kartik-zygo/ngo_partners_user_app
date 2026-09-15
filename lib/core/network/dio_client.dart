import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Timer? _refreshTimer;

  // Set this from main.dart to handle session expiry (e.g. navigate to login).
  VoidCallback? onSessionExpired;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  // ── Proactive refresh timer ────────────────────────────────────────────────

  /// Call after a successful login or session restore to start the 8-minute
  /// proactive refresh cycle. Cancels any running timer first.
  void startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 8), (_) async {
      final ok = await _performRefresh();
      if (!ok) {
        stopRefreshTimer();
        onSessionExpired?.call();
      }
    });
  }

  /// Call on logout or when the session is definitively expired.
  void stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ── Shared refresh logic ───────────────────────────────────────────────────

  Future<bool> _performRefresh() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        await clearTokens();
        return false;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (res.data['success'] == true) {
        final newAccess = res.data['data']['accessToken'] as String;
        final newRefresh = res.data['data']['refreshToken'] as String;
        await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
        debugPrint('│ [Auth] Token refreshed proactively');
        return true;
      }
      await clearTokens();
      return false;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  // ── Interceptors ───────────────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    debugPrint('');
    debugPrint('┌── REQUEST ──────────────────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    debugPrint('│ Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query: ${options.queryParameters}');
    }
    debugPrint('└─────────────────────────────────────────────────');

    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('');
    debugPrint('┌── RESPONSE ─────────────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ Body: ${response.data}');
    debugPrint('└─────────────────────────────────────────────────');
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    debugPrint('');
    debugPrint('┌── ERROR ────────────────────────────────────────');
    debugPrint('│ ${error.requestOptions.method} ${error.requestOptions.uri}');
    debugPrint('│ Status: ${error.response?.statusCode}');
    debugPrint('│ Message: ${error.message}');
    if (error.response?.data != null) {
      debugPrint('│ Response body: ${error.response?.data}');
    }
    debugPrint('└─────────────────────────────────────────────────');

    // Account deletion answers a wrong password with 401 as well. A refresh
    // cannot fix that, and retrying would loop refresh → 401 indefinitely.
    final request = error.requestOptions;
    final isPasswordCheck =
        request.path.endsWith('/auth/me') && request.method == 'DELETE';

    if (error.response?.statusCode != 401 || isPasswordCheck) {
      handler.next(error);
      return;
    }

    // Reactive refresh on 401.
    final ok = await _performRefresh();
    if (ok) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final opts = error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $token';
      final retry = await dio.fetch(opts);
      handler.resolve(retry);
    } else {
      stopRefreshTimer();
      onSessionExpired?.call();
      handler.reject(error);
    }
  }

  // ── Token helpers ──────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.tokenKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
      _storage.delete(key: AppConstants.userIdKey),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.tokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.userIdKey);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: AppConstants.userIdKey, value: userId);

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        return data['error']['message'] as String? ??
            e.message ??
            'Request failed';
      }
    } catch (_) {}
    return e.message ?? 'Request failed';
  }

  String extractErrorMessage(DioException e) => _extractMessage(e);
}
