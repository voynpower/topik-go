class SocialLoginConfig {
  const SocialLoginConfig._();

  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const kakaoJavaScriptAppKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_APP_KEY',
  );
  static const kakaoCustomScheme = String.fromEnvironment(
    'KAKAO_CUSTOM_SCHEME',
  );

  static String? get googleClientIdOrNull => _emptyToNull(googleClientId);
  static String? get googleServerClientIdOrNull =>
      _emptyToNull(googleServerClientId);

  static String get googleServerClientIdRequired {
    final value = googleServerClientIdOrNull;
    if (value == null) {
      throw StateError(
        'Missing GOOGLE_SERVER_CLIENT_ID. Pass the Web client ID from the same Google OAuth project.',
      );
    }
    return value;
  }
  static String? get kakaoJavaScriptAppKeyOrNull =>
      _emptyToNull(kakaoJavaScriptAppKey);

  static String get resolvedKakaoCustomScheme {
    if (kakaoCustomScheme.isNotEmpty) return kakaoCustomScheme;
    if (kakaoNativeAppKey.isNotEmpty) return 'kakao$kakaoNativeAppKey';
    return '';
  }

  static String? _emptyToNull(String value) {
    return value.isEmpty ? null : value;
  }
}
