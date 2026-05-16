import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/auth/session_store.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
// Senior Dev Note: Updated IP from backend team - 192.168.45.62
const _backendTeamIp = '192.168.45.62'; 
const _physicalDeviceApiBaseUrl = 'http://$_backendTeamIp:3000';
const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:3000';

String get resolvedApiBaseUrl {
  if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
  
  // By default, assume we are on a physical device or a simulator that can see the LAN.
  return _physicalDeviceApiBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(sessionStoreProvider);
  final baseUrl = resolvedApiBaseUrl;

  if (kDebugMode) {
    debugPrint('----------------------------------------');
    debugPrint('🚀 API CONNECTION DIAGNOSTIC');
    debugPrint('Target URL: $baseUrl');
    debugPrint('Platform: $defaultTargetPlatform');
    debugPrint('----------------------------------------');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
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

