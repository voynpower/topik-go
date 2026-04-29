import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Response> login(String email, String password) async {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    return _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  Future<Response> getUserProfile() async {
    return _dio.get('/user/profile');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
