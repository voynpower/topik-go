import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

/// Stores the JWT access token in platform secure storage
/// (iOS/macOS Keychain, Android Keystore-backed encrypted storage).
class SessionStore {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> readToken() async {
    final secureToken = await _secureStorage.read(key: PrefsKeys.accessToken);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // One-time migration: move a legacy plaintext token out of
    // SharedPreferences into secure storage, then delete the plaintext copy.
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(PrefsKeys.accessToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: PrefsKeys.accessToken, value: legacyToken);
      await prefs.remove(PrefsKeys.accessToken);
      return legacyToken;
    }

    return null;
  }

  Future<String?> readRefreshToken() async {
    return _secureStorage.read(key: PrefsKeys.refreshToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: PrefsKeys.refreshToken, value: token);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: PrefsKeys.accessToken, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: PrefsKeys.accessToken);
    await _removeLegacyToken();
  }

  Future<void> clearAllTokens() async {
    await _secureStorage.delete(key: PrefsKeys.accessToken);
    await _secureStorage.delete(key: PrefsKeys.refreshToken);
    await _removeLegacyToken();
  }

  Future<void> _removeLegacyToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(PrefsKeys.accessToken)) {
      await prefs.remove(PrefsKeys.accessToken);
    }
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore();
});
