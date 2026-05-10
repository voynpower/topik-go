class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    required this.languageCode,
    required this.targetLevel,
    required this.timezone,
    required this.fontScale,
    required this.timerMode,
    required this.themeColor,
    required this.homeLayout,
    required this.practiceLayout,
  });

  final String id;
  final String? email;
  final String nickname;
  final String role;
  final String languageCode;
  final int targetLevel;
  final String timezone;
  final String fontScale;
  final String timerMode;
  final String themeColor;
  final int homeLayout;
  final int practiceLayout;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      nickname: json['nickname']?.toString() ?? 'TOPIK GO',
      role: json['role']?.toString() ?? 'user',
      languageCode: json['language_code']?.toString() ?? 'ko',
      targetLevel: _asInt(json['target_level']) ?? 3,
      timezone: json['timezone']?.toString() ?? '+09:00',
      fontScale: json['font_scale']?.toString() ?? '1.00',
      timerMode: json['timer_mode']?.toString() ?? 'countdown',
      themeColor: json['theme_color']?.toString() ?? 'mint',
      homeLayout: _asInt(json['home_layout']) ?? 1,
      practiceLayout: _asInt(json['practice_layout']) ?? 1,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
