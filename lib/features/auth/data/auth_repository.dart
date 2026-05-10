import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/auth/session_store.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/auth/data/auth_session.dart';

class AuthRepository {
  final Dio _dio;
  final SessionStore _sessionStore;

  AuthRepository(this._dio, this._sessionStore);

  Future<AuthSession> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final session = AuthSession.fromJson(response.data as Map<String, dynamic>);
    await _sessionStore.saveToken(session.accessToken);
    return session;
  }

  Future<AuthSession> socialLogin({
    required String provider,
    required String token,
  }) async {
    final response = await _dio.post(
      '/auth/social-login',
      data: {'provider': provider, 'token': token},
    );
    final session = AuthSession.fromJson(response.data as Map<String, dynamic>);
    await _sessionStore.saveToken(session.accessToken);
    return session;
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final targetLevel = prefs.getInt(PrefsKeys.targetTopikLevel) ?? 3;
    final languageCode =
        prefs.getString(PrefsKeys.preferredLanguageCode) ?? 'ko';

    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'target_level': targetLevel,
        'language_code': languageCode,
        'timezone': 'Asia/Seoul',
        'timer_mode': 'normal',
      },
    );
    final session = AuthSession.fromJson(response.data as Map<String, dynamic>);
    await _sessionStore.saveToken(session.accessToken);
    return session;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Logout is stateless on the backend, so local cleanup is still enough.
    } finally {
      await _sessionStore.clearToken();
    }
  }

  Future<Response> getUserProfile() async {
    return _dio.get('/users/profile');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(sessionStoreProvider),
  );
});
