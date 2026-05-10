import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/auth/session_store.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

String get _resolvedApiBaseUrl {
  if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

final dioProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(sessionStoreProvider);
  final dio = Dio(
    BaseOptions(
      // Local NestJS backend
      // iOS Simulator: http://localhost:3000
      // Android Emulator: http://10.0.2.2:3000
      // Physical devices: pass your Mac IP with --dart-define=API_BASE_URL.
      baseUrl: _resolvedApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await sessionStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await sessionStore.clearToken();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  return dio;
});
