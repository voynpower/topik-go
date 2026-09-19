import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/auth/session_store.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const _localApiBaseUrl = 'http://localhost:3000';
const _backendTeamIp = '172.30.1.79';
const _previousBackendIp = '10.188.191.214';
const _physicalDeviceApiBaseUrl = 'http://$_backendTeamIp:3000';
const _previousPhysicalDeviceApiBaseUrl = 'http://$_previousBackendIp:3000';
const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:3000';

String? _runtimeApiBaseUrl;
Future<String>? _apiBaseUrlResolution;

String get resolvedApiBaseUrl {
  if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
  return _runtimeApiBaseUrl ?? _localApiBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(sessionStoreProvider);
  final baseUrl = resolvedApiBaseUrl;

  if (kDebugMode) {
    debugPrint('API target bootstrap URL: $baseUrl');
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
        options.baseUrl = await _resolveApiBaseUrl();
        final token = await sessionStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/refresh') &&
            !error.requestOptions.path.contains('/auth/login')) {
          final refreshToken = await sessionStore.readRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final baseUrl = await _resolveApiBaseUrl();
              final refreshDio = Dio(
                BaseOptions(baseUrl: baseUrl, contentType: 'application/json'),
              );
              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final data = response.data as Map<String, dynamic>?;
              final newAccessToken = data?['access_token'] as String?;
              final newRefreshToken = data?['refresh_token'] as String?;

              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                await sessionStore.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              await sessionStore.clearAllTokens();
            }
          } else {
            await sessionStore.clearAllTokens();
          }
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

Future<String> _resolveApiBaseUrl() {
  if (_apiBaseUrl.isNotEmpty) return Future.value(_apiBaseUrl);

  final resolved = _runtimeApiBaseUrl;
  if (resolved != null) return Future.value(resolved);

  return _apiBaseUrlResolution ??= _findReachableApiBaseUrl();
}

Future<String> _findReachableApiBaseUrl() async {
  final candidates = <String>[
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
      _androidEmulatorApiBaseUrl,
    _localApiBaseUrl,
    _physicalDeviceApiBaseUrl,
    _previousPhysicalDeviceApiBaseUrl,
  ];

  for (final result in await Future.wait(candidates.map(_probeApiBaseUrl))) {
    if (result != null) {
      _runtimeApiBaseUrl = result;
      if (kDebugMode) debugPrint('Selected API base URL: $result');
      return result;
    }
  }

  _runtimeApiBaseUrl = _localApiBaseUrl;
  return _localApiBaseUrl;
}

Future<String?> _probeApiBaseUrl(String baseUrl) async {
  final probe = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
      validateStatus: (_) => true,
    ),
  );

  try {
    final response = await probe.get('/api');
    if (response.statusCode != null && response.statusCode! < 500) {
      return baseUrl;
    }
  } catch (_) {
    return null;
  } finally {
    probe.close(force: true);
  }

  return null;
}
