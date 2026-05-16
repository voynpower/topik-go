import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/auth/session_store.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
// Senior Dev Note: Updated IP from backend team - 172.30.1.79
const _backendTeamIp = '172.30.1.79'; 
const _physicalDeviceApiBaseUrl = 'http://$_backendTeamIp:3000';
const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:3000';

String get resolvedApiBaseUrl {
  if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
  
  // Senior Dev Note: Android Emulators use 10.0.2.2 to access host's localhost.
  // Physical devices use the LAN IP: 172.30.1.79
  if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
    // For local development on Emulator, 10.0.2.2 is usually the best bet.
    // However, since we are testing both, let's use the provided backend IP
    // if 10.0.2.2 fails, OR just use 10.0.2.2 as the primary for Emulator.
    return 'http://10.0.2.2:3000'; 
  }
  
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
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 60),
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

