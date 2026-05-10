class AuthSession {
  const AuthSession({required this.accessToken});

  final String accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing access token');
    }

    return AuthSession(accessToken: token);
  }
}
