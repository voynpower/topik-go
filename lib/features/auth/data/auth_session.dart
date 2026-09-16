class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing access token');
    }

    final refreshToken = json['refresh_token'] as String?;

    return AuthSession(
      accessToken: token,
      refreshToken: refreshToken,
    );
  }
}
