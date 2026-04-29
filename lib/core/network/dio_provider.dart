import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Local NestJS backend
      // iOS Simulator: http://localhost:3000
      // Android Emulator: http://10.0.2.2:3000
      baseUrl: 'http://localhost:3000', 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ),
  );

  // You can add interceptors here for JWT tokens later
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
