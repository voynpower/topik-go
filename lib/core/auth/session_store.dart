import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';

class SessionStore {
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.accessToken);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.accessToken, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefsKeys.accessToken);
  }
}

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore();
});
