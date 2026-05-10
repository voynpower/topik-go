import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:topik_go/core/config/social_login_config.dart';

class SocialLoginService {
  bool _kakaoInitialized = false;

  Future<String> getGoogleIdToken() async {
    final signIn = GoogleSignIn(
      clientId: SocialLoginConfig.googleClientIdOrNull,
      serverClientId: SocialLoginConfig.googleServerClientIdOrNull,
      scopes: const ['email', 'profile'],
    );

    await signIn.signOut();
    final account = await signIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was canceled.');
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google did not return an ID token. Check your Google OAuth client configuration.',
      );
    }

    return idToken;
  }

  Future<String> getKakaoAccessToken() async {
    await _ensureKakaoInitialized();

    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    return token.accessToken;
  }

  Future<void> _ensureKakaoInitialized() async {
    if (_kakaoInitialized) return;

    if (SocialLoginConfig.kakaoNativeAppKey.isEmpty &&
        SocialLoginConfig.kakaoJavaScriptAppKey.isEmpty) {
      throw StateError(
        'Kakao login is not configured. Provide KAKAO_NATIVE_APP_KEY.',
      );
    }

    await KakaoSdk.init(
      nativeAppKey: SocialLoginConfig.kakaoNativeAppKey.isEmpty
          ? null
          : SocialLoginConfig.kakaoNativeAppKey,
      javaScriptAppKey: SocialLoginConfig.kakaoJavaScriptAppKeyOrNull,
      customScheme: SocialLoginConfig.resolvedKakaoCustomScheme.isEmpty
          ? null
          : SocialLoginConfig.resolvedKakaoCustomScheme,
    );
    _kakaoInitialized = true;
  }
}

final socialLoginServiceProvider = Provider<SocialLoginService>((ref) {
  return SocialLoginService();
});
