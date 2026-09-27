import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/core/constants/prefs_keys.dart';
import 'package:topik_go/features/users/data/user_repository.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;
}

const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'uz', name: 'Uzbek', nativeName: "O'zbekcha"),
  AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  AppLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
];

String getLanguageDisplayName(String? code) {
  final match = kSupportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => const AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  );
  return '${match.nativeName} (${match.name})';
}

/// 현재 설정된 사용자 언어 코드를 관리하는 Notifier
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _init();
    return 'ko';
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(PrefsKeys.preferredLanguageCode);
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    }
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.preferredLanguageCode, code);

    // 사용자 프로필이 있는 경우 백엔드에도 동기화
    try {
      await ref.read(userRepositoryProvider).updateProfile({'language_code': code});
      ref.invalidate(userProfileProvider);
    } catch (_) {
      // 오프라인이거나 비로그인 시 로컬 설정 유지
    }
  }
}

final currentLanguageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

/// 외부 번역 서비스 (MyMemory Open API)
class TranslationService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  /// 한국어 단어/문장을 대상 언어 코드로 번역
  static Future<String?> translate({
    required String text,
    required String targetLang,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (targetLang == 'ko') return clean;

    try {
      final response = await _dio.get(
        'https://api.mymemory.translated.net/get',
        queryParameters: {
          'q': clean,
          'langpair': 'ko|$targetLang',
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final resData = response.data['responseData'];
        if (resData is Map<String, dynamic>) {
          final translated = resData['translatedText']?.toString().trim();
          if (translated != null &&
              translated.isNotEmpty &&
              !translated.startsWith('MYMEMORY WARNING') &&
              translated.toLowerCase() != clean.toLowerCase()) {
            return translated;
          }
        }
      }
    } catch (_) {
      // 번역 실패 시 null 반환
    }
    return null;
  }
}
