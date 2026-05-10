import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/users/data/user_profile.dart';

class AdminUserRepository {
  const AdminUserRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/$id', data: data);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }
}

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(ref.watch(dioProvider));
});
