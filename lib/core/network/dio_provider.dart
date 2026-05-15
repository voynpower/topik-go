import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/auth/session_store.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const _physicalDeviceApiBaseUrl = 'http://10.188.191.214:3000';
const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:3000';

String? _runtimeApiBaseUrl;
Future<String>? _apiBaseUrlResolution;

String get resolvedApiBaseUrl {
  if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
  return _runtimeApiBaseUrl ?? _physicalDeviceApiBaseUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(sessionStoreProvider);
  final baseUrl = resolvedApiBaseUrl;

  if (kDebugMode) {
    debugPrint('Connecting to API at: $baseUrl');
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
        options.baseUrl = await _resolveApiBaseUrl();
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
    _physicalDeviceApiBaseUrl,
  ];

  final selected = await _firstReachable(candidates);
  _runtimeApiBaseUrl = selected;

  if (kDebugMode) {
    debugPrint('Selected API base URL: $selected');
  }

  return selected;
}

Future<String> _firstReachable(List<String> candidates) async {
  final fallback = candidates.last;
  final checks = candidates.map((baseUrl) async {
    return await _canReachApi(baseUrl) ? baseUrl : null;
  });

  for (final result in await Future.wait(checks)) {
    if (result != null) return result;
  }

  return fallback;
}

Future<bool> _canReachApi(String baseUrl) async {
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
    return response.statusCode != null && response.statusCode! < 500;
  } catch (_) {
    return false;
  } finally {
    probe.close(force: true);
  }
}
