import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/core/network/dio_provider.dart';
import 'package:topik_go/features/users/data/user_profile.dart';

class UserRepository {
  const UserRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/users/profile');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/profile', data: data);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(userRepositoryProvider).getProfile();
});
