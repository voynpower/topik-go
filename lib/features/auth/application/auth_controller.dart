import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topik_go/features/auth/data/auth_repository.dart';
import 'package:topik_go/features/auth/data/social_login_service.dart';

final authStateProvider = Provider((ref) {
  return ValueNotifier<AsyncValue<void>>(const AsyncValue.data(null));
});

class AuthController {
  final AuthRepository _repository;
  final SocialLoginService _socialLoginService;
  final ValueNotifier<AsyncValue<void>> _stateNotifier;

  AuthController(
    this._repository,
    this._socialLoginService,
    this._stateNotifier,
  );

  Future<bool> login(String email, String password) async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          final message = data['message'];
          errorMessage = message is List
              ? message.join(', ')
              : message.toString();
        }
      }
      _stateNotifier.value = AsyncValue.error(errorMessage, st);
      return false;
    }
  }

  Future<bool> socialLogin(String provider, String token) async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      await _repository.socialLogin(provider: provider, token: token);
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _stateNotifier.value = AsyncValue.error(_errorMessage(e), st);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      final idToken = await _socialLoginService.getGoogleIdToken();
      await _repository.socialLogin(provider: 'google', token: idToken);
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _stateNotifier.value = AsyncValue.error(_errorMessage(e), st);
      return false;
    }
  }

  Future<bool> loginWithKakao() async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      final accessToken = await _socialLoginService.getKakaoAccessToken();
      await _repository.socialLogin(provider: 'kakao', token: accessToken);
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _stateNotifier.value = AsyncValue.error(_errorMessage(e), st);
      return false;
    }
  }

  Future<bool> register(String email, String password, String nickname) async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      await _repository.register(
        email: email,
        password: password,
        nickname: nickname,
      );
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      String errorMessage = e.toString();
      if (e is DioException) {
        // Log full error for debugging
        debugPrint('Registration Error: ${e.response?.data}');

        if (e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            final message = data['message'];
            errorMessage = message is List
                ? message.join(', ')
                : message.toString();
          }
        }
      }
      _stateNotifier.value = AsyncValue.error(errorMessage, st);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _stateNotifier.value = const AsyncValue.loading();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _stateNotifier.value = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      _stateNotifier.value = AsyncValue.error(_errorMessage(e), st);
      return false;
    }
  }

  String _errorMessage(Object e) {
    String errorMessage = e.toString();
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        final message = data['message'];
        errorMessage = message is List
            ? message.join(', ')
            : message.toString();
      }
    }
    return errorMessage;
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(socialLoginServiceProvider),
    ref.watch(authStateProvider),
  );
});
